#region usings
using System;
using System.Linq;
using System.Text;
using System.IO;
using System.ComponentModel.Composition;
using System.Runtime.InteropServices;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;
using VVVV.Utils.Streams;

using VVVV.Core.Logging;

#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "PartialReader", Category = "Raw", Help = "Reads parts of a raw file", Author = "tmp", Tags = "")]
	#endregion PluginInfo
	public class RawPartialReaderNode : IPluginEvaluate, IPartImportsSatisfiedNotification
	{
		#region fields & pins

		[Input("Filename", StringType = StringType.Filename, DefaultString = "", FileMask = "", IsSingle = true)]
		public IDiffSpread<string> FFilenameIn;
		
		[Input("Reload", IsBang=true, IsSingle = true)]
        public ISpread<bool> FReloadFile;
		
		[Input("Position", DefaultValue = 0)]
        public ISpread<int> FPositionIn;
		
		[Input("Count", DefaultValue = 0)]
        public ISpread<int> FCountIn;
		
		[Input("Read", IsBang=true, IsSingle = true)]
        public ISpread<bool> FDoRead;

		[Output("Output")]
        public ISpread<Stream> FStreamOut;
		
		[Output("File Length", DefaultValue = 0)]
        public ISpread<long> FLength;
		
		readonly byte[] FBuffer = new byte[1024];
		#endregion fields & pins

		private StreamReader FReader;
		
		//called when all inputs and outputs defined above are assigned from the host
		public void OnImportsSatisfied()
		{
			 FStreamOut.SliceCount = 0;
		}

		//called when data for any output pin is requested
		public void Evaluate(int spreadMax)
		{
			
			if (this.FFilenameIn.IsChanged || FReloadFile[0] ){
			 	string path = this.FFilenameIn[0];
				if (File.Exists(path))this.FReader = new StreamReader(path);
				FLength[0] = this.FReader.BaseStream.Length;
			}
			
			if ( this.FDoRead[0] == true  && this.FReader != null){
				
				FStreamOut.ResizeAndDispose(spreadMax, () => new MemoryStream());
				var inputStream = FReader.BaseStream;
				
				for (int i = 0; i < spreadMax; i++)
				{
					var outputStream = FStreamOut[i];
					var pos = FPositionIn[i] % inputStream.Length;
					var count = Math.Max(FCountIn[i], 0);
					var numBytesToCopy = Math.Min( inputStream.Length - pos , count);
					
					inputStream.Position = pos;
					outputStream.Position = 0;

					outputStream.SetLength(numBytesToCopy);
					
					while (numBytesToCopy > 0)
					{
						var chunkSize = (int)Math.Min(numBytesToCopy, FBuffer.Length);
						var numBytesRead = inputStream.Read(FBuffer, 0, chunkSize);
						if (numBytesRead == 0) break;
						outputStream.Write(FBuffer, 0, numBytesRead);
						numBytesToCopy -= numBytesRead;
					}
				}
				
			}
			
		}
		
		#region Dispose
        public void Dispose()
        {
            this.Clear();
        }
        #endregion

        private void Clear()
        {
            if (this.FReader != null)
            {
                this.FReader.Close();
                this.FReader.Dispose();
            }
        }
	}
}
