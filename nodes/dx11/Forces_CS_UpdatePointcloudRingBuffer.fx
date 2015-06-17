#include "_PointData.fxh"
StructuredBuffer<pointData> pcBufferIn;
StructuredBuffer<uint> updatedBufferIn;
ByteAddressBuffer InputCountBuffer;

RWStructuredBuffer<pointData> rwPcBufferOut : BACKBUFFER;

bool Update;
bool Reset;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >= cnt ) { return;} // safeguard
	
	if(	Update && updatedBufferIn[i.x] == 1){
		pointData pd = pcBufferIn[i.x];
		rwPcBufferOut[i.x]  = pd;
	}
	
	if (Reset){
		pointData pd = pcBufferIn[i.x];
		pd.pos = float3(0,0,0);
		rwPcBufferOut[i.x]  = pd;
	}
}

technique11 Emit
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
