#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int groupId = -1;
float deceleration_multiplicator = 0.01f;
bool Apply;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply){
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
		
			float3 deceleration = rwForceBuffer[i.x].velocity * -1;
			deceleration *= deceleration_multiplicator;
			deceleration *= rwForceBuffer[i.x].mass;
			
			rwForceBuffer[i.x].acceleration += deceleration;
		}
	}
	
	
}

technique11 ApplyForce
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
