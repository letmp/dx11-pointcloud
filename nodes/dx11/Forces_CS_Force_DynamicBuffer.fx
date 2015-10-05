#include "../fxh/_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;
StructuredBuffer<uint> updatedBufferIn;

StructuredBuffer<float3> velocity;
StructuredBuffer<float3> acceleration;
StructuredBuffer<float> mass;
int groupId = -1;
bool Apply;
bool updatedOnly;

[numthreads(64, 1, 1)]
void CS_Add( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if(Apply){
		
		if (updatedOnly && updatedBufferIn[i.x] == 0){ return; }
		
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			velocity.GetDimensions(cnt,stride);
			rwForceBuffer[i.x].velocity += velocity[i.x % cnt];
			
			acceleration.GetDimensions(cnt,stride);
			rwForceBuffer[i.x].acceleration += acceleration[i.x % cnt];
			
			mass.GetDimensions(cnt,stride);
			rwForceBuffer[i.x].mass += mass[i.x % cnt];
		}
	}	
}

[numthreads(64, 1, 1)]
void CS_Mult( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if(Apply){
		
		if (updatedOnly && updatedBufferIn[i.x] == 0){ return; }
		
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			velocity.GetDimensions(cnt,stride);
			rwForceBuffer[i.x].velocity *= velocity[i.x % cnt];
			
			acceleration.GetDimensions(cnt,stride);
			rwForceBuffer[i.x].acceleration *= acceleration[i.x % cnt];
			
			mass.GetDimensions(cnt,stride);
			rwForceBuffer[i.x].mass *= mass[i.x % cnt];
		}
	}	
}

technique11 Add
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Add() ) );
	}
}

technique11 Multiply
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Mult() ) );
	}
}
