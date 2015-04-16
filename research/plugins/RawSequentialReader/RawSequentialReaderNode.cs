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
	[PluginInfo(Name = "SequentialReader", Category = "Raw", Help = "Basic raw template which copies up to count bytes from the input to the output", Tags = "")]
	#endregion PluginInfo
	public class RawSequentialReaderNode : IPluginEvaluate, IPartImportsSatisfiedNotification, IDisposable
	{
		#region fields & pins
		#pragma warning disable 0649
		[Input("Filename", StringType = StringType.Filename, DefaultString = "", FileMask = "")]
		public IDiffSpread<string> FFilenameIn;
		
		[Input("Format", DefaultEnumEntry = "Double")]
        public IInStream<IInStream<ValueTypeFormat>> FFormats;

        [Input("Byte Order", Visibility = PinVisibility.OnlyInspector)]
        public IInStream<ByteOrder> FByteOrder;
		
		[Input("Read", IsBang=true, IsSingle = true)]
        public ISpread<bool> FDoRead;
		
		[Input("Reset", IsBang=true, IsSingle = true)]
        public ISpread<bool> FReset;
		
		[Output("Output", AutoFlush = false)]
        IIOStream<IInStream<double>> FOutputs; 
		
		[Output("End of File", IsSingle = true)]
        public ISpread<bool> FEof;
		
		[Import()]
        public ILogger FLogger;
		#pragma warning restore
		#endregion fields & pins
		
		private StreamReader FReader;

		public void OnImportsSatisfied()
        {
            FOutputs.Length = 0;
        }

		public void Evaluate(int spreadMax)
		{
			if (this.FReset[0]){
				FLogger.Log(LogType.Debug, "reset");
			}
			if (this.FFilenameIn.IsChanged || this.FReset[0]){
				FLogger.Log(LogType.Debug, "ischanged");
			 	string path = this.FFilenameIn[0];
				if (File.Exists(path))this.FReader = new StreamReader(path);
			 }
			
			if ( this.FDoRead[0] == true  && this.FReader != null){
				spreadMax = StreamUtils.GetSpreadMax(FFormats, FByteOrder);
	            FOutputs.ResizeAndDismiss(spreadMax, () => new MemoryIOStream<double>());
	            var buffer = MemoryPool<double>.GetArray();
	            try
	            {
	                //using (var reader = FInputStreams.GetCyclicReader())
	                using (var formatReader = FFormats.GetCyclicReader())
	                using (var byteOrderReader = FByteOrder.GetCyclicReader())
	                {
	                    foreach (MemoryIOStream<double> outputStream in FOutputs)
	                    {
	                        
                            var formatStream = formatReader.Read();
                            var byteOrder = byteOrderReader.Read();
                            /*if (formatStream.Length == 1)
                            {
                                //var format = formatStream.Single();
                                //ConvertAllAtOnce(FReader.BaseStream, outputStream, buffer, format, byteOrder);
                            }
                            else
                            {
                                //ConvertOneByOne(this.FReader.Read(), outputStream, formatStream, byteOrder);
                            }
	                        */
							ConvertOneByOne(this.FReader.BaseStream, outputStream, formatStream, byteOrder);
	                    }
	                }
	                FOutputs.Flush(true);
	            }
	            finally
	            {
	                MemoryPool<double>.PutArray(buffer);
	            }
				
			}
			
			
		}
		
        static void ConvertOneByOne(Stream srcStream, MemoryIOStream<double> dstStream, IInStream<ValueTypeFormat> formatStream, ByteOrder byteOrder)
        {
            var binaryReader = new BinaryReader(srcStream);
            int dstStreamLength = 0;
        	bool stop = false;
            using (var writer = dstStream.GetWriter())
            using (var formatStreamReader = formatStream.GetCyclicReader())
            {
                while (srcStream.Position < srcStream.Length && !stop)
                {
                    var format = formatStreamReader.Read();
                    double result;
                    switch (format)
                    {
                        case ValueTypeFormat.Boolean:
                            result = (Double)Convert.ChangeType(binaryReader.ReadBoolean(byteOrder), typeof(Double));
                            break;
                        case ValueTypeFormat.SByte:
                            result = (Double)binaryReader.ReadSByte();
                            break;
                        case ValueTypeFormat.Byte:
                            result = (Double)binaryReader.ReadByte();
                            break;
                        case ValueTypeFormat.Int16:
                            result = (Double)binaryReader.ReadInt16(byteOrder);
                            break;
                        case ValueTypeFormat.UInt16:
                            result = (Double)binaryReader.ReadUInt16(byteOrder);
                            break;
                        case ValueTypeFormat.Int32:
                            result = (Double)binaryReader.ReadInt32(byteOrder);
                            break;
                        case ValueTypeFormat.UInt32:
                            result = (Double)binaryReader.ReadUInt32(byteOrder);
                            break;
                        case ValueTypeFormat.Int64:
                            result = (Double)binaryReader.ReadInt64(byteOrder);
                            break;
                        case ValueTypeFormat.UInt64:
                            result = (Double)binaryReader.ReadUInt64(byteOrder);
                            break;
                        case ValueTypeFormat.Single:
                            result = (Double)binaryReader.ReadSingle(byteOrder);
                            break;
                        case ValueTypeFormat.Double:
                            result = binaryReader.ReadDouble(byteOrder);
                            break;
                        default:
                            throw new NotImplementedException();
                    }
                    if (result == -1) stop = true;
                	writer.Write(result);
                    dstStreamLength++;
                }
            }
            dstStream.Length = dstStreamLength;
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
