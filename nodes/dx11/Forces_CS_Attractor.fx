#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;
StructuredBuffer<uint> updatedBufferIn;

StructuredBuffer<float3> AttractorPosition;
StructuredBuffer<float> Force;
StructuredBuffer<float> Size;
int groupId = -1;

bool updatedOnly;
bool Apply;


[numthreads(64, 1, 1)]
void CS_Attractor( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	
	if (Apply) {
		if (updatedOnly && updatedBufferIn[i.x] == 0){ return; }
		
		AttractorPosition.GetDimensions(cnt,stride);
		int attractorCount = cnt;
		for (int j = 0; j <  attractorCount; j++)
		{
			if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
				
				float3 dist = AttractorPosition[j] - rwForceBuffer[i.x].position;
				Size.GetDimensions(cnt,stride);
				float f = (length(dist) / Size[j % cnt]);
				f = 1 - f;
				f = saturate(f);
				f = pow(f, 2.71);
				Force.GetDimensions(cnt,stride);
				rwForceBuffer[i.x].acceleration += dist * f * Force[j % cnt];
			}
		}
	}
}

technique11 Attractor
{
	pass P0{ SetComputeShader(CompileShader(cs_5_0, CS_Attractor())); }
}
