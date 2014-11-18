float4x4 tFilter : WORLD;
struct pointData
{
	float4 pos;
	float4 col;
};
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

AppendStructuredBuffer<pointData> filteredPdBuffer : BACKBUFFER;


[numthreads(64, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	float4 test = mul(pcBuffer[i.x].pos, tFilter);
	if(	!(test.x < -0.5 || test.x > 0.5 ||
		test.y < -0.5 || test.y > 0.5 ||
		test.z < -0.5 || test.z > 0.5
		)){
			filteredPdBuffer.Append(pcBuffer[i.x]);
		}
	
}

technique11 Process
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}