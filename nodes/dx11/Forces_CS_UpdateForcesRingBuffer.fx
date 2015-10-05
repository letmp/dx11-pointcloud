ByteAddressBuffer InputCountBuffer;
StructuredBuffer<uint> updatedBufferIn;

#include "../fxh/_PointData.fxh"
StructuredBuffer<pointData> pcBufferIn;

#include "../fxh/_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

bool Update;
bool Reset;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >= cnt ) { return;} // safeguard

	float3 position = pcBufferIn[i.x].pos;
	int groupId = pcBufferIn[i.x].groupId;
	
	// updates the RWBuffer with current pointcloud data
	// =================================================
	if(	Update && updatedBufferIn[i.x] == 1){
		float3 velocity = float3(0,0,0);
		float3 acceleration = float3(0,0,0);
		float mass = 1.0;
		int age = 0;
		forceData fd = {position, velocity, acceleration, mass, age, groupId};
		rwForceBuffer[i.x]  = fd;
	}
	
	if (Reset){
		float3 velocity = float3(0,0,0);
		float3 acceleration = float3(0,0,0);
		float mass = 1.0;
		int age = 0;
		forceData fd = {position, velocity, acceleration, mass, age, groupId};
		rwForceBuffer[i.x]  = fd;
	}
	
}

technique11 Emit
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
