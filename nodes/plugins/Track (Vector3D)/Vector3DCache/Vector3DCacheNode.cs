#region usings
using System;
using System.ComponentModel.Composition;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VMath;
using System.Linq;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "Cache", Category = "Vector3D", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class Vector3DCacheNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input")]
		public ISpread<Vector3D> FInput;

		[Input("ID")]
		public ISpread<int> FIndex;

		[Input("Retain Time", IsSingle = true, DefaultValue = 1.0)]
		public ISpread<double> FTime;

		[Input("Reset", IsSingle = true)]
		public ISpread<bool> FReset;
		
		[Output("Cached Output")]
		public ISpread<Vector3D> FOutput;
		
		[Output("Cached ID")]
		public ISpread<int> FCachedID;

		[Import()]
		public ILogger FLogger;
		
        [Import()]
        protected IHDEHost FHDEHost;
		
		
		protected Dictionary<int, Vector3D> dict = new Dictionary<int, Vector3D>();
		protected Dictionary<int, double> mark = new Dictionary<int, double>();
		
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			if (FReset[0]) {
				dict.Clear();
				mark.Clear(); 
			}
			
			SpreadMax = FInput.CombineWith(FIndex);
			
			if (FInput.SliceCount > 0 && FIndex.SliceCount > 0)
			for (int i=0;i<SpreadMax;i++) {
				dict[FIndex[i]] = FInput[i];
				mark[FIndex[i]] = FHDEHost.FrameTime;
			}

			var validTime = FHDEHost.FrameTime - FTime[0];

			var clear = from id in mark.Keys
						where mark[id] < validTime
						select id;
			
			foreach (var id in clear.ToArray()) {
				if (mark[id] < validTime) {
					mark.Remove(id);
					dict.Remove(id);
				}
			}
		
			FOutput.SliceCount = 
			FCachedID.SliceCount = 0;
			FOutput.AssignFrom(dict.Values);
			FCachedID.AssignFrom(dict.Keys);

		}
	}
}
