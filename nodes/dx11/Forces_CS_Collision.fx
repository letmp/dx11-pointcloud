#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

float4x4 tW: WORLD;
float4x4 Rotation;

int groupId = -1;
int onEventGroup = -1;
bool Bounce;
float BounceMultiplicator = 1.0f;
bool ChangeGroup;
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
				if (ChangeGroup){
					rwForceBuffer[i.x].groupId = onEventGroup;
				}
				
				if (Bounce){
					if( !(pointCoord.x < -0.5 || pointCoord.x > 0.5)) rwForceBuffer[i.x].velocity *= float3(-BounceMultiplicator,BounceMultiplicator,BounceMultiplicator);
					if( !(pointCoord.y < -0.5 || pointCoord.y > 0.5)) rwForceBuffer[i.x].velocity *= float3(BounceMultiplicator,-BounceMultiplicator,BounceMultiplicator);
					if( !(pointCoord.z < -0.5 || pointCoord.z > 0.5)) rwForceBuffer[i.x].velocity *= float3(BounceMultiplicator,BounceMultiplicator,-BounceMultiplicator);
					rwForceBuffer[i.x].velocity = mul(float4(rwForceBuffer[i.x].velocity,1), Rotation).xyz;
				}
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
				if (ChangeGroup){
					rwForceBuffer[i.x].groupId = onEventGroup;
				}
				
				if (Bounce){
					if(pointCoord.x < -0.5 || pointCoord.x > 0.5) rwForceBuffer[i.x].velocity *= float3(-1,1,1);
					if(pointCoord.y < -0.5 || pointCoord.y > 0.5) rwForceBuffer[i.x].velocity *= float3(1,-1,1);
					if(pointCoord.z < -0.5 || pointCoord.z > 0.5) rwForceBuffer[i.x].velocity *= float3(1,1,-1);
					rwForceBuffer[i.x].velocity = mul(float4(rwForceBuffer[i.x].velocity,1), Rotation).xyz;
				}
				
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