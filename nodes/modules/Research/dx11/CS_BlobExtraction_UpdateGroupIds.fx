struct pointData
{
	float4 pos;
	float4 col;
	int groupId;
};
StructuredBuffer<pointData> pcBuffer;
StructuredBuffer<int> groupIdBuffer;

AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;
ByteAddressBuffer InputCountBuffer;

[numthreads(64, 1, 1)]
void CS_CalculateBounds( uint3 i : SV_DispatchThreadID)
{ 
	
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	pointData pd = pcBuffer[i.x];
	pd.groupId = groupIdBuffer[i.x];
	newPcBuffer.Append(pd);
	
}

technique11 SetGroupIds
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_CalculateBounds() ) );
	}
}