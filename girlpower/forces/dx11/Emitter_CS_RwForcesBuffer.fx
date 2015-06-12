ByteAddressBuffer InputCountBuffer;
StructuredBuffer<uint> updatedBufferIn;

#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

bool Update;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >= cnt ) { return;} // safeguard
		
	// updates the RWBuffer with current pointcloud data
	// =================================================
	if(	Update && updatedBufferIn[i.x] == 1){
		forceData fd = {float3(0,0,0),float3(0,0,0)};
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
