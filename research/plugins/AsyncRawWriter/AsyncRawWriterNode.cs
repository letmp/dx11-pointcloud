#region usings
using System;
using System.Collections.Generic;
using System.ComponentModel.Composition;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "Writer", Category = "Raw", Version = "Async", Help = "Buffers and writes raw data into a file", Author ="tmp", Tags = "",AutoEvaluate = true)]
	#endregion PluginInfo
	public class AsyncRawWriterNode : IPluginEvaluate
	{
		
		class CopyOperation : IDisposable
        {
            private MemoryStream memoryStream;
            private FileStream fileStream;
            private string fileName;
            private bool append;
            private CancellationTokenSource CancellationTokenSource;
            private Task CopyTask;
        	private float progress = 0;
            public CopyOperation(Stream rawStream, string fileName, bool append)
            {
            	var memoryStream = new MemoryStream();
            	rawStream.CopyTo(memoryStream);
                this.memoryStream = memoryStream;
                this.fileName = fileName;
                this.append = append;
            }

            public void Run()
            {
                CancellationTokenSource = new CancellationTokenSource();
                var cancellationToken = CancellationTokenSource.Token;
                
                CopyTask = Task.Run(
                    async () =>
                    {
                        
                    	if (append){
		                    fileStream = File.Open(fileName, FileMode.OpenOrCreate);                    		
                    		fileStream.Seek(0, SeekOrigin.End);                    		
		                }
		                else {
		                    fileStream = File.Create(fileName);
		                    fileStream.Seek(0, SeekOrigin.Begin);
		                }
                    	
                        var streamLength = (float)memoryStream.Length;
                        var buffer = new byte[0x1000];
                    	
                    	var numBytesToCopy = streamLength;
                    	memoryStream.Position = 0;
                    	
                    	while (numBytesToCopy > 0)
						{
							var chunkSize = (int)Math.Min(numBytesToCopy, buffer.Length);
							var numBytesRead = memoryStream.Read(buffer, 0, chunkSize);
							if (numBytesRead == 0) break;
							await fileStream.WriteAsync(buffer, 0, numBytesRead, cancellationToken);
							numBytesToCopy -= numBytesRead;
							progress = (streamLength - numBytesToCopy) / streamLength;
						}
		                
                    	memoryStream.Dispose();
                    	fileStream.Dispose();
                    },
                    CancellationTokenSource.Token
                   );
            }

            public bool IsRunning { get { return CopyTask != null; } }

            public bool IsCompleted { get { return CopyTask != null && CopyTask.IsCompleted; } }

        	public float getProgress { get { return progress;}}
        	
            public void Dispose()
            {
                if (CancellationTokenSource != null)
                {
                    CancellationTokenSource.Cancel();
                    CancellationTokenSource.Dispose();
                    CancellationTokenSource = null;
                }
                if (CopyTask != null)
                {
                    try
                    {
                        CopyTask.Wait();
                    }
                    catch (AggregateException ae)
                    {
                        ae.Handle(e => e is OperationCanceledException);
                    }
                    finally
                    {
                        CopyTask.Dispose();
                        CopyTask = null;
                    }
                }
            	
            }
        }
		
		#region fields & pins
		[Input("Input")]
		public ISpread<Stream> FStreamIn;

		[Input("Filename", StringType=StringType.Filename, IsSingle = true)]
        public ISpread<string> FFile;

		[Input("Write", DefaultValue = 0)]
		public ISpread<bool> FWrite;

        [Input("Append", DefaultValue = 0)]
        public ISpread<bool> FAppend;

        [Output("Progress")]
        public ISpread<float> ProgressOut;
		
		[Output("Success", IsBang = true)]
        public ISpread<bool> FSuccess;
		
		[Import()]
        public ILogger Logger;
		
		private List<CopyOperation> CopyOperations = new List<CopyOperation>();
		#endregion fields & pins
		
		public void Evaluate(int spreadMax)
		{

			for (int i = 0; i < spreadMax; i++){
				if (FWrite[i]){
            		CopyOperations.Add(new CopyOperation(FStreamIn[i], FFile[i],FAppend[i]));
            	}
			}
            
			if(CopyOperations.Count == 0 ){
				ProgressOut.SliceCount = 1;
				ProgressOut[0] = 0;
				FSuccess.SliceCount = 1;
				FSuccess[0] = false;
			}
			else {
				ProgressOut.SliceCount = CopyOperations.Count;
				FSuccess.SliceCount = CopyOperations.Count;
			}
			
            List<CopyOperation> coToRemoveList = new List<CopyOperation>();
            bool copyOpRunning = false;
			
			foreach (CopyOperation copyOperation in CopyOperations)
            {
				
            	int index = CopyOperations.IndexOf(copyOperation);
            	ProgressOut[index] = copyOperation.getProgress;
            	
            	if(copyOperation.IsRunning){            		
            		copyOpRunning = true;
            	}
            	
                if (!copyOperation.IsRunning && !copyOpRunning){
                    copyOperation.Run();
                    copyOpRunning = true;
                }            	
                
            	FSuccess[index] = false;
            	if (copyOperation.IsCompleted){
            		FSuccess[index] = true;
                    coToRemoveList.Add(copyOperation);
            		DisposeAndLogExceptions(copyOperation);
                }
            }
			
            foreach (CopyOperation co in coToRemoveList){
            	CopyOperations.Remove(co);
            }
		}

        public void Dispose()
        {
        	foreach (var copyOperation in CopyOperations)
                DisposeAndLogExceptions(copyOperation);
        }

        private void DisposeAndLogExceptions(CopyOperation copyOperation)
        {
            try
            {
                copyOperation.Dispose();
            }
            catch (Exception e)
            {
                Logger.Log(e);
            }
        }
		
	}
}
