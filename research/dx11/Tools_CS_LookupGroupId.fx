float4x4 tW: WORLD;
float2 textureSize;

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
StructuredBuffer<int> groupIdBuffer;
ByteAddressBuffer InputCountBuffer;
AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;

[numthreads(64, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	pointData pd = pcBuffer[i.x];
	float4 pos = mul(float4(pd.pos,1), tW);
	float2 uv = pos.xy/pos.w;
	
	float x = uv.x * 0.5 + 0.5;
	float y = uv.y * -0.5 + 0.5;
	int count = y * textureSize.y;
	int id = (x * textureSize.x) + (count * textureSize.x);
	if (id < 0 || id > textureSize.x * textureSize.y) id = 0;
	
	pd.groupId = groupIdBuffer[id];
	newPcBuffer.Append(pd);
}

technique11 LookupGroupId
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS() ) );}
}