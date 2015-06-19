#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

float4x4 tW: WORLD;

int groupId = -1;
int groupIdNew = -1;
bool Apply;

[numthreads(64, 1, 1)]
void CS_ChangeGroupId( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply) {
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
				rwForceBuffer[i.x].groupId = groupIdNew;
		}
	}
}

technique11 ChangeGroupId
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS_ChangeGroupId() ) ); }
}