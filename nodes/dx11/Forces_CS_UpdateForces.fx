#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int groupId = -1;
bool Apply;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply){
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
		
			rwForceBuffer[i.x].velocity += rwForceBuffer[i.x].acceleration;
			rwForceBuffer[i.x].acceleration *=0;
		
			rwForceBuffer[i.x].position += rwForceBuffer[i.x].velocity;
		
			rwForceBuffer[i.x].age ++;
			
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
