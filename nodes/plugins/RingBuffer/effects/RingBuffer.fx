struct pointData
{
	float3 fPos;
	int fCol;
	int iGroupId;
};

StructuredBuffer<pointData> bPointcloud : POINTCLOUDBUFFER;
ByteAddressBuffer InputCountBuffer : POINTCLOUDCOUNTBUFFER;

RWStructuredBuffer<pointData> rbPointcloud : POINTCLOUDRINGBUFFER;
RWStructuredBuffer<uint> rbUpdated : UPDATEDRINGBUFFER;
int iRbSize : POINTCLOUDRINGBUFFERSIZE;

ByteAddressBuffer bOffset : OFFSETBUFFER;
RWStructuredBuffer<uint> bCounter : COUNTERBUFFER;

[numthreads(64, 1, 1)]
void CS_AddPoints(uint3 i : SV_DispatchThreadID)
{
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >= cnt) { return; }

	pointData pd = bPointcloud[i.x];
	uint index = (bCounter[0] + bCounter.IncrementCounter()) % iRbSize;
	rbPointcloud[index] = pd;
	rbUpdated[index] = 1;
}

[numthreads(1, 1, 1)]
void CS_CalcOffset(uint3 i : SV_DispatchThreadID)
{
	uint offset = bOffset.Load(0);
	bCounter[0] = (bCounter[0] + offset) % iRbSize;
}

technique11 AddPoints
{
	pass P0 { SetComputeShader(CompileShader(cs_5_0, CS_AddPoints())); }
}

technique11 CalcOffset
{
	pass P0 { SetComputeShader(CompileShader(cs_5_0, CS_CalcOffset())); }
}