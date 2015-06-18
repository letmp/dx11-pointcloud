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

namespace RingBuffer
{
    #region PluginInfo
    [PluginInfo(Name = "RingBuffer", Category = "DX11.Pointcloud", Version = "PointcloudBuffer", Help = "", Author = "tmp", Tags = "")]
    #endregion PluginInfo
    public class RingBufferNode : IPluginEvaluate, IDX11ResourceProvider
    {
        #region fields & pins

        [Input("PointcloudBuffer")]
        protected Pin<DX11Resource<IDX11ReadableStructureBuffer>> FInPointcloudBuffer;

        [Input("CountBuffer")]
        protected Pin<DX11Resource<DX11RawBuffer>> FInCountBuffer;

        [Input("Element Count", DefaultValue = 1.0, IsSingle = true)]
        public IDiffSpread<int> FInEleCount;

        [Input("PointcloudRingBuffer Size", DefaultValue = 1.0, IsSingle = true)]
        public IDiffSpread<int> FInPointcloudRingBufferSize;

        [Input("Stride", DefaultValue = 0, IsSingle = true)]
        public ISpread<int> FInStride;

        [Input("Set", IsBang = true, IsSingle = true)]
        public ISpread<bool> FInSet;

        [Output("PointcloudBuffer", IsSingle = true)]
        protected ISpread<DX11Resource<IDX11RWStructureBuffer>> FOutPointcloudRingBuffer;

        [Output("UpdatedBuffer", IsSingle = true)]
        protected ISpread<DX11Resource<IDX11RWStructureBuffer>> FOutUpdatedBuffer;

        #endregion fields & pins

        private DX11ShaderInstance shader;
        private DX11Resource<DX11RawBuffer> bOffset;
        private DX11Resource<IDX11RWStructureBuffer> bCounter;
        private static double currentFrame;

        [Import()]
        protected IPluginHost FHost;

        [Import()]
        IHDEHost FHDEHost;

        [Import()]
        public ILogger FLogger;

        public void Evaluate(int SpreadMax)
        {
            if ( this.FOutPointcloudRingBuffer[0] == null || this.FOutUpdatedBuffer[0] == null || this.bCounter == null || this.bOffset == null)
            {
                this.FOutPointcloudRingBuffer[0] = new DX11Resource<IDX11RWStructureBuffer>();
                this.FOutUpdatedBuffer[0] = new DX11Resource<IDX11RWStructureBuffer>();
                this.bOffset = new DX11Resource<DX11RawBuffer>();
                this.bCounter = new DX11Resource<IDX11RWStructureBuffer>();
            }
        }

        public void Update(IPluginIO pin, DX11RenderContext context)
        {
            Device device = context.Device;
            DeviceContext ctx = context.CurrentDeviceContext;

            if ( !this.FOutPointcloudRingBuffer[0].Contains(context) || !this.FOutUpdatedBuffer[0].Contains(context) || !this.bCounter.Contains(context) || !this.bOffset.Contains(context) || this.FInPointcloudRingBufferSize.IsChanged || this.FInEleCount.IsChanged)
            {

                this.FOutPointcloudRingBuffer[0].Dispose(context);
                DX11RWStructuredBuffer brPointcloud = new DX11RWStructuredBuffer(device, FInPointcloudRingBufferSize[0], FInStride[0], eDX11BufferMode.Counter);
                this.FOutPointcloudRingBuffer[0][context] = brPointcloud;

                this.FOutUpdatedBuffer[0].Dispose(context);
                DX11RWStructuredBuffer brUpdated = new DX11RWStructuredBuffer(device, FInPointcloudRingBufferSize[0], 4, eDX11BufferMode.Counter);
                this.FOutUpdatedBuffer[0][context] = brUpdated;

                this.bOffset.Dispose(context);
                this.bOffset[context] = new DX11RawBuffer(device, 16);

                this.bCounter.Dispose(context);
                this.bCounter[context] = new DX11RWStructuredBuffer(device, FInEleCount[0], 4, eDX11BufferMode.Counter);

            }

            // load shader
            if (this.shader == null)
            {
                string basepath = "RingBuffer.effects.RingBuffer.fx";
                DX11Effect effect = DX11Effect.FromResource(Assembly.GetExecutingAssembly(), basepath);
                this.shader = new DX11ShaderInstance(context, effect);
            }

            if (this.FInPointcloudBuffer.PluginIO.IsConnected && FInSet[0] && currentFrame != FHDEHost.FrameTime)
            {

                currentFrame = FHDEHost.FrameTime; // prevents to execute this a second time

                int[] mask = new int[4] { 0, 0, 0, 0 };
                ctx.ClearUnorderedAccessView(FOutUpdatedBuffer[0][context].UAV, mask);

                shader.SelectTechnique("AddPoints");
                shader.SetBySemantic("POINTCLOUDBUFFER", FInPointcloudBuffer[0][context].SRV);
                shader.SetBySemantic("POINTCLOUDCOUNTBUFFER", FInCountBuffer[0][context].SRV);
                shader.SetBySemantic("POINTCLOUDRINGBUFFER", FOutPointcloudRingBuffer[0][context].UAV, FInPointcloudRingBufferSize[0]);
                shader.SetBySemantic("UPDATEDRINGBUFFER", FOutUpdatedBuffer[0][context].UAV, FInPointcloudRingBufferSize[0]);
                shader.SetBySemantic("POINTCLOUDRINGBUFFERSIZE", FInPointcloudRingBufferSize[0]);
                shader.SetBySemantic("OFFSETBUFFER", this.bOffset[context].SRV);
                shader.SetBySemantic("COUNTERBUFFER", this.bCounter[context].UAV, 0);
                shader.ApplyPass(0);
                ctx.Dispatch((FInEleCount[0] + 63) / 64, 1, 1);

                ctx.CopyStructureCount(this.bCounter[context].UAV, this.bOffset[context].Buffer, 0);
                shader.SelectTechnique("CalcOffset");
                shader.ApplyPass(0);
                ctx.Dispatch(1, 1, 1);

                context.CleanUp();
                context.CleanUpCS();
                
            }

        }

        public void Destroy(IPluginIO pin, DX11RenderContext context, bool force)
        {
            if (this.FOutPointcloudRingBuffer[0] != null || this.FOutUpdatedBuffer[0] != null)
            {
                this.FOutPointcloudRingBuffer[0].Dispose(context);
                this.FOutUpdatedBuffer[0].Dispose(context);
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
