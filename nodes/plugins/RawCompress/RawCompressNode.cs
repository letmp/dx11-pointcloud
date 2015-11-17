#region usings
using System;
using System.IO;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;


using VVVV.Core.Logging;
using SnappyPI;
using System.Runtime.InteropServices;

#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
    [PluginInfo(Name = "Compress", Category = "Raw", Help = "Uses the Snappy compression/decompression library to compress a RAW stream.", Author = "tmp", Tags = "")]
	#endregion PluginInfo
	public unsafe class RawCompressNode : IPluginEvaluate, IPartImportsSatisfiedNotification
	{
		#region fields & pins
		[Input("Input")]
		public ISpread<Stream> FStreamIn;
        
		[Output("Output")]
		public ISpread<Stream> FStreamOut;

        private byte[] compressedFrameData;
        private int compressedSize;

        [Import()]
        public ILogger FLogger;
        
		#endregion fields & pins

		public void OnImportsSatisfied()
		{
			//FStreamIn.SliceCount = 0;
			FStreamOut.SliceCount = 0;
		}

		public void Evaluate(int spreadMax)
		{
            if (FStreamIn.SliceCount == 0 || FStreamIn[0] == null || FStreamIn[0].Length == 0) 
                spreadMax = 0;
            else spreadMax = FStreamIn.SliceCount;
			
			FStreamOut.ResizeAndDispose(spreadMax, () => new MemoryStream());
            
			for (int i = 0; i < spreadMax; i++) {
                
				var inputStream = FStreamIn[i];
				var outputStream = FStreamOut[i];
                
                inputStream.Position = 0;
                outputStream.Position = 0;

                FStreamOut[i].SetLength(0);
                var length = (int) inputStream.Length;
               
                IntPtr contentPtr = Marshal.AllocHGlobal(length);
                byte[] memory = new byte[length];
                inputStream.Read(memory, 0, length);
                Marshal.Copy(memory, 0, contentPtr, length);

                int maxCompressedLength = SnappyCodec.GetMaximumCompressedLength(length);
                this.compressedFrameData = new byte[maxCompressedLength];

                fixed (byte* bptr = &this.compressedFrameData[0])
                {
                    this.compressedSize = maxCompressedLength;
                    SnappyCodec.Compress((byte*)contentPtr, length, bptr, ref this.compressedSize);
                    byte[] output = new byte[this.compressedSize];
                    Marshal.Copy((IntPtr)bptr, output, 0, this.compressedSize);
                    outputStream.Write(this.compressedFrameData, 0, this.compressedSize);
                }

                Marshal.FreeHGlobal(contentPtr);
            }
			FStreamOut.Flush(true);
		}
	}

    #region PluginInfo
    [PluginInfo(Name = "Decompress", Category = "Raw", Help = "Uses the Snappy compression/decompression library to decompress a RAW stream.", Author = "tmp", Tags = "")]
    #endregion PluginInfo
    public unsafe class RawDecompressNode : IPluginEvaluate, IPartImportsSatisfiedNotification
    {
        #region fields & pins
        [Input("Input")]
        public ISpread<Stream> FStreamIn;

        [Output("Output")]
        public ISpread<Stream> FStreamOut;

        private byte[] uncompressedFrameData;
        private int uncompressedSize;

        [Import()]
        public ILogger FLogger;

        #endregion fields & pins

        public void OnImportsSatisfied()
        {
            //FStreamIn.SliceCount = 0;
            FStreamOut.SliceCount = 0;
        }

        public void Evaluate(int spreadMax)
        {
            if (FStreamIn.SliceCount == 0 || FStreamIn[0] == null || FStreamIn[0].Length == 0)
                spreadMax = 0;
            else spreadMax = FStreamIn.SliceCount;

            FStreamOut.ResizeAndDispose(spreadMax, () => new MemoryStream());
            for (int i = 0; i < spreadMax; i++)
            {
                var inputStream = FStreamIn[i];
                var outputStream = FStreamOut[i];

                inputStream.Position = 0;
                outputStream.Position = 0;

                FStreamOut[i].SetLength(0);
                var compressedDataSize = (int)inputStream.Length;

                IntPtr contentPtr = Marshal.AllocHGlobal(compressedDataSize);
                byte[] compressedData = new byte[compressedDataSize];
                inputStream.Read(compressedData, 0, compressedDataSize);
                Marshal.Copy(compressedData, 0, contentPtr, compressedDataSize);

                fixed (byte* bptr = &compressedData[0])
                {
                    SnappyCodec.GetUncompressedLength(bptr, compressedDataSize, ref this.uncompressedSize);
                    IntPtr uncompressedDataPointer = Marshal.AllocHGlobal(this.uncompressedSize);
                    
                    SnappyCodec.Uncompress(bptr, compressedDataSize, (byte*)uncompressedDataPointer, ref this.uncompressedSize);
                    
                    this.uncompressedFrameData = new byte[this.uncompressedSize];
                    Marshal.Copy((IntPtr)uncompressedDataPointer, this.uncompressedFrameData, 0, this.uncompressedSize);
                    outputStream.Write(this.uncompressedFrameData, 0, this.uncompressedSize);

                    Marshal.FreeHGlobal(uncompressedDataPointer);
                }

                Marshal.FreeHGlobal(contentPtr);
            }
            FStreamOut.Flush(true);
        }
    }
}
