float4x4 tVP: VIEWPROJECTION;
float2 textureSize;

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

StructuredBuffer<int> labelBuffer;
StructuredBuffer<int> groupIdBuffer;

ByteAddressBuffer InputCountBuffer;
AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;

[numthreads(64, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	pointData pd = pcBuffer[i.x];
	float4 pos = mul(float4(pd.pos,1), tVP);
	float2 uv = pos.xy/pos.w;
	
	float x = uv.x * 0.5 + 0.5;
	float y = uv.y * -0.5 + 0.5;

	int count = y * textureSize.y;
	int id = (x * textureSize.x) + (count * textureSize.x);
	if (id > 0 && id < textureSize.x * textureSize.y){
		int label = labelBuffer[id];
		//pd.groupId = label; 
		if( label > 0 && groupIdBuffer[label - 1] != -1) pd.groupId = groupIdBuffer[label - 1]; 
	}
	
	newPcBuffer.Append(pd);
}

technique11 SetGroupIds
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS() ) );}
}