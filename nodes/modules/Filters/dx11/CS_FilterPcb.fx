float4x4 tFilter : WORLD;
int slice;

struct pointData
{
	float4 pos;
	float4 col;
	int groupId;
};
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

AppendStructuredBuffer<pointData> filteredPdBuffer : BACKBUFFER;

[numthreads(64, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	//check if point position is inside the given filter(s)
	float4 pointCoord = mul(pcBuffer[i.x].pos, tFilter);
	if(	!(pointCoord.x < -0.5 || pointCoord.x > 0.5 ||
		pointCoord.y < -0.5 || pointCoord.y > 0.5 ||
		pointCoord.z < -0.5 || pointCoord.z > 0.5
		)){
			pointData pd = pcBuffer[i.x];
			pd.groupId = slice;
			filteredPdBuffer.Append(pd);
		}
	
}

technique11 Process
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}