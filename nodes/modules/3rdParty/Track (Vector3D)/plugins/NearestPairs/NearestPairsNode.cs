#region usings
using System;
using System.ComponentModel.Composition;
using System.Linq;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "NearestPairs", Category = "Value", Help = "Find closest direct matches", Tags = "ID, Tracking", Author = "velcrome")]
	#endregion PluginInfo
	public class NearestPairsDouble : NearestPairs<double> {
		
		public override double Distance(double input, double other) {
			return Math.Abs(input - other); 
		}
	}

	#region PluginInfo
	[PluginInfo(Name = "NearestPairs", Category = "Vector3D", Help = "Find closest direct matches", Tags = "ID, Tracking", Author = "velcrome")]
	#endregion PluginInfo
	public class NearestPairsVector3D : NearestPairs<Vector3D> {
		
		public override double Distance(Vector3D input, Vector3D other) {
			return (input - other).Length; 
		}
		
		protected override int Index(ISpread<Vector3D> spread, Vector3D item) {
			int i=0;
			foreach (var v in spread) {
				if (item.x == v.x && item.y == v.y && item.z == v.z) return i;
				i++;
			}
			return -1;			
		}
	}	
	
	public abstract class NearestPairs<T> : IPluginEvaluate// where T: IEquatable<T>
	{
		#region fields & pins
		[Input("Input")]
		public ISpread<T> FInput;

		[Input("Other")]
		public ISpread<T> FOther;		

		[Input("MinDistance", Visibility = PinVisibility.OnlyInspector)]
		public ISpread<double> FMin;			
		
		[Input("MaxDistance", DefaultValue=0.5)]
		public ISpread<double> FMax;				
		
		[Output("Output")]
		public ISpread<T> FOutput;
		
		[Output("Former Slice")]
		public ISpread<int> FFormer;		
		
		[Output("Other Slice")]
		public ISpread<int> FFormerOther;		

		[Output("Unpaired Input")]
		public ISpread<T> FNew;

		[Output("Unpaired Input Former Slice")]
		public ISpread<int> FFormerNew;

		[Output("Unpaired Other")]
		public ISpread<T> FOld;

		[Output("Unpaired Other Slice")]
		public ISpread<int> FFormerOld;

		[Import()]
		public ILogger FLogger;

		protected List<T> FoundInputs = new List<T>();
		protected List<T> FoundOthers = new List<T>();
		
		#endregion fields & pins

		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = 
			FFormer.SliceCount =
			FFormerOther.SliceCount = 0;

			
// 			remove redundancies
			var inputs = FInput;
			var others = FOther;
			
			var map = 
				from input in inputs
				from other in others
				let distance = Distance(input, other)
				where distance <= FMax[0] && distance >= FMin[0]
				orderby distance ascending
				select new MapElement<T>(distance, input, other);

			FoundInputs.Clear();
			FoundOthers.Clear();

			for (int i=0;i<FInput.SliceCount;i++) {
				var inputItem = map.FirstOrDefault();
				
				if (inputItem != null) {
					FoundInputs.Add(inputItem.Input);
					FoundOthers.Add(inputItem.Other);
					
					var newMap =
						from item in map
						where (!item.Input.Equals(inputItem.Input) && !item.Other.Equals(inputItem.Other))
						select item;
				
					map = newMap;
				
					FOutput.Add(inputItem.Input);
					FFormer.Add(i);
					FFormerOther.Add(Index(FOther, inputItem.Other));
				}
			}
			
			FFormerNew.SliceCount =
			FNew.SliceCount = 
			FFormerOld.SliceCount = 
			FOld.SliceCount = 0;
			
			foreach (var input in inputs.Except(FoundInputs)) {
				FNew.Add(input);
				FFormerNew.Add(Index(FInput, input));
			}
			
			foreach (var input in others.Except(FoundOthers)) {
				FOld.Add(input);
				FFormerOld.Add(Index(FOther, input));
			}
		}
		
		protected virtual int Index(ISpread<T> spread, T item) {
			return spread.IndexOf(item);	
		}
		
		public abstract double Distance(T a, T b);
		
		
	}

    public class MapElement<T>
    {
        public double Distance ; 
        public T Input;
        public T Other ;

        public MapElement(double distance, T input, T other)
        {
            this.Distance = distance;
            this.Input = input;
            this.Other = other;
        }
    }

	
}
