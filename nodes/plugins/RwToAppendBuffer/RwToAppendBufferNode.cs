#region usings
using System;
using System.Reflection;
using System.ComponentModel.Composition;
using System.Drawing;
using System.IO;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using SlimDX;
using SlimDX.Direct3D11;

using FeralTic.DX11;
using FeralTic.DX11.Resources;
using VVVV.DX11;

using VVVV.Core.Logging;
#endregion usings

namespace RwToAppendBuffer
{
	#region PluginInfo
	[PluginInfo(Name = "RwToAppendBuffer", Category = "DX11.Pointcloud", Version = "PointcloudBuffer", Help = "Copies a RWStructuredBuffer to an AppendStructuredBuffer and additionally outputs a second buffer with indices.", Author = "tmp", Tags = "")]
	#endregion PluginInfo
    public class RwToAppendBufferNode : IPluginEvaluate, IDX11ResourceProvider
	{
		#region fields & pins

		[Input("PointcloudBuffer")]
        protected Pin<DX11Resource<IDX11ReadableStructureBuffer>> FInPointcloudBuffer;

		[Input("Element Count", DefaultValue = -1.0, IsSingle = true)]
        public ISpread<int> FInEleCount;

        [Input("Stride", DefaultValue = 0, IsSingle = true)]
        public ISpread<int> FInStride;

		[Output("PointcloudBuffer",IsSingle=true)]
        protected ISpread<DX11Resource<IDX11RWStructureBuffer>> FOutPointcloudBuffer;
		
		[Output("IndexBuffer",IsSingle=true)]
        protected ISpread<DX11Resource<IDX11RWStructureBuffer>> FOutIndexBuffer;
		#endregion fields & pins

        private DX11ShaderInstance shader;
        
		[Import()]
        protected IPluginHost FHost;

        [Import()]
        public ILogger FLogger;
		
		public void Evaluate(int SpreadMax)
		{
			if (this.FOutPointcloudBuffer[0] == null || this.FOutIndexBuffer[0] == null)
			{
                this.FOutPointcloudBuffer[0] = new DX11Resource<IDX11RWStructureBuffer>();
				this.FOutIndexBuffer[0] = new DX11Resource<IDX11RWStructureBuffer>();
            }
		}
		
		public void Update(IPluginIO pin, DX11RenderContext context)
        {
            Device device = context.Device;
            DeviceContext ctx = context.CurrentDeviceContext;

            if (!this.FOutPointcloudBuffer[0].Contains(context) || !this.FOutIndexBuffer[0].Contains(context))
           	{
                this.FOutPointcloudBuffer[0].Dispose(context);
                this.FOutIndexBuffer[0].Dispose(context);
            	DX11RWStructuredBuffer pcBuffer = new DX11RWStructuredBuffer(device, FInEleCount[0], FInStride[0], eDX11BufferMode.Counter);
            	DX11RWStructuredBuffer idBuffer = new DX11RWStructuredBuffer(device, FInEleCount[0], 4, eDX11BufferMode.Counter);
                this.FOutPointcloudBuffer[0][context] = pcBuffer;
            	this.FOutIndexBuffer[0][context] = idBuffer;

            }

            // clear offsetbuffer
            int[] mask = new int[4] { -1, -1, -1, -1 };
        	ctx.ClearUnorderedAccessView(FOutIndexBuffer[0][context].UAV,mask);
        	
            // load shader
            if (this.shader == null)
            {
                string basepath = "RwToAppendBuffer.effects.RwToAppendBuffer.fx";
                DX11Effect effect = DX11Effect.FromResource(Assembly.GetExecutingAssembly(), basepath);
                this.shader = new DX11ShaderInstance(context, effect);
            }
            if (this.shader == null) FLogger.Log(LogType.Debug, "Shader could not be loaded.");
        	if (this.FInPointcloudBuffer.PluginIO.IsConnected)
            {
                
            	shader.SelectTechnique("BuildHash");            	
            	shader.SetBySemantic("POINTCLOUDBUFFERIN", FInPointcloudBuffer[0][context].SRV);
                shader.SetBySemantic("POINTCLOUDBUFFEROUT", FOutPointcloudBuffer[0][context].UAV, 0);
            	shader.SetBySemantic("INDEXBUFFER", FOutIndexBuffer[0][context].UAV);
                            	
            	shader.ApplyPass(0);
            	ctx.Dispatch((FInEleCount[0] + 63) / 64, 1, 1);
                context.CleanUp();
            	context.CleanUpCS();
            }        	
        	
        }

        public void Destroy(IPluginIO pin, DX11RenderContext context, bool force)
        {
            if (this.FOutPointcloudBuffer[0] != null || this.FOutIndexBuffer[0] != null )
            {
                this.FOutPointcloudBuffer[0].Dispose(context);
            	this.FOutIndexBuffer[0].Dispose(context);
            }
        }
		
		public void Dispose()
        {
            if (this.shader != null)
            {
                this.shader.Dispose();
            }
        }
		
	}
	
	
	
}
