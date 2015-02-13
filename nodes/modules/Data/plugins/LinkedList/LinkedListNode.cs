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

namespace LinkedList
{
	#region PluginInfo
	[PluginInfo(Name = "LinkedList", Category = "DX11.Pointcloud.Data", Version = "PointcloudBuffer", Help = "Creates a linked list that can be used in further shaders (for example to do a neighbour lookup).", Tags = "")]
	#endregion PluginInfo
    public class LinkedListNode : IPluginEvaluate, IDX11ResourceProvider
	{
		#region fields & pins

		[Input("PointcloudBuffer")]
        protected Pin<DX11Resource<IDX11ReadableStructureBuffer>> FInPcBuffer;

		[Input("Element Count", DefaultValue = -1.0, IsSingle = true)]
        public ISpread<int> FInEleCount;

        [Input("Transform In", IsSingle = true)]
        public ISpread<Matrix> FInTransform;

		[Input("Gridcell Count", DefaultValue = 10.0, IsSingle = true)]
        public IDiffSpread<int> FInGridcellCount;
		
		[Output("LinkBuffer Out",IsSingle=true)]
        protected ISpread<DX11Resource<IDX11RWStructureBuffer>> FOutLinkBuffer;
		
		[Output("OffsetBuffer Out",IsSingle=true)]
        protected ISpread<DX11Resource<IDX11RWStructureBuffer>> FOutOffsetBuffer;
		#endregion fields & pins

        private DX11ShaderInstance shader;
        
		[Import()]
        protected IPluginHost FHost;

        [Import()]
        public ILogger FLogger;
		
		public void Evaluate(int SpreadMax)
		{
			if (this.FOutLinkBuffer[0] == null || this.FOutOffsetBuffer[0] == null)
			{
                this.FOutLinkBuffer[0] = new DX11Resource<IDX11RWStructureBuffer>();
				this.FOutOffsetBuffer[0] = new DX11Resource<IDX11RWStructureBuffer>();
            }
		}
		
		public void Update(IPluginIO pin, DX11RenderContext context)
        {
            Device device = context.Device;
            DeviceContext ctx = context.CurrentDeviceContext;

            if (!this.FOutLinkBuffer[0].Contains(context) || !this.FOutOffsetBuffer[0].Contains(context) || FInGridcellCount.IsChanged)
           	{
                this.FOutLinkBuffer[0].Dispose(context);
                this.FOutOffsetBuffer[0].Dispose(context);
            	DX11RWStructuredBuffer lb = new DX11RWStructuredBuffer(device, FInEleCount[0], 8, eDX11BufferMode.Counter);
            	DX11RWStructuredBuffer ob = new DX11RWStructuredBuffer(device, FInGridcellCount[0] * FInGridcellCount[0] * FInGridcellCount[0], 4, eDX11BufferMode.Counter);
                this.FOutLinkBuffer[0][context] = lb;
            	this.FOutOffsetBuffer[0][context] = ob;

            }

            // clear offsetbuffer
            int[] mask = new int[4] { -1, -1, -1, -1 };
        	ctx.ClearUnorderedAccessView(FOutOffsetBuffer[0][context].UAV,mask);
        	
            // load shader
            if (this.shader == null)
            {
                string basepath = "LinkedList.effects.LinkedList.fx";
                DX11Effect effect = DX11Effect.FromResource(Assembly.GetExecutingAssembly(), basepath);
                this.shader = new DX11ShaderInstance(context, effect);
            }
            
        	if (this.FInPcBuffer.PluginIO.IsConnected)
            {
                
            	shader.SelectTechnique("BuildHash");            	
            	shader.SetBySemantic("POINTCLOUDBUFFER", FInPcBuffer[0][context].SRV);
                shader.SetBySemantic("POINTTRANSFORM", FInTransform[0]);
                shader.SetBySemantic("RWLINKBUFFER", FOutLinkBuffer[0][context].UAV, 0);
            	shader.SetBySemantic("RWOFFSETBUFFER", FOutOffsetBuffer[0][context].UAV);
            	shader.SetBySemantic("GRIDCELLSIZE", FInGridcellCount[0]);
                            	
            	shader.ApplyPass(0);
            	ctx.Dispatch((FInEleCount[0] + 63) / 64, 1, 1);
                context.CleanUp();
            	context.CleanUpCS();
            }        	
        	
        }

        public void Destroy(IPluginIO pin, DX11RenderContext context, bool force)
        {
            if (this.FOutLinkBuffer[0] != null || this.FOutOffsetBuffer[0] != null )
            {
                this.FOutLinkBuffer[0].Dispose(context);
            	this.FOutOffsetBuffer[0].Dispose(context);
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
