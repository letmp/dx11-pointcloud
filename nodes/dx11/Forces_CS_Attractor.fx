#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int CountAttractor;
StructuredBuffer<float3> AttractorPosition;
StructuredBuffer<float2> ForceSize;

int groupId = -1;
bool Apply;


[numthreads(64, 1, 1)]
void CS_Attractor( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	
	if (Apply) {
		
		for (int j = 0; j < CountAttractor; j++)
		{
			if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
				
				float3 dist = AttractorPosition[j] - rwForceBuffer[i.x].position;
				float f = (length(dist) / ForceSize[j].y);
				f = 1 - f;
				f = saturate(f);
				f = pow(f, 2.71);
				rwForceBuffer[i.x].acceleration += dist * f * ForceSize[j].x;
			}
		}
	}
}

technique11 Attractor
{
	pass P0{ SetComputeShader(CompileShader(cs_5_0, CS_Attractor())); }
}
