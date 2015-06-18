#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

float4x4 tW: WORLD;

int groupId = -1;
int onEventGroup = -1;
bool Apply;

[numthreads(64, 1, 1)]
void CS_IsInside( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply) {
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			float3 pointCoord = mul(float4(rwForceBuffer[i.x].position,1), tW).xyz;
			if(	!(pointCoord.x < -0.5 || pointCoord.x > 0.5 ||
			pointCoord.y < -0.5 || pointCoord.y > 0.5 ||
			pointCoord.z < -0.5 || pointCoord.z > 0.5
			)){
				rwForceBuffer[i.x].groupId = onEventGroup;
			}
			
		}
	}
}

[numthreads(64, 1, 1)]
void CS_IsOutside( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply) {
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			float3 pointCoord = mul(float4(rwForceBuffer[i.x].position,1), tW).xyz;
			if(	(pointCoord.x < -0.5 || pointCoord.x > 0.5 ||
			pointCoord.y < -0.5 || pointCoord.y > 0.5 ||
			pointCoord.z < -0.5 || pointCoord.z > 0.5
			)){
				rwForceBuffer[i.x].groupId = onEventGroup;
			}
			
		}
	}
}

technique11 IsInside
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS_IsInside() ) ); }
}

technique11 IsOutside
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS_IsOutside() ) ); }
}