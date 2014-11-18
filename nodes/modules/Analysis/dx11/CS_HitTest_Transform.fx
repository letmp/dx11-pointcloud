float4x4 tFilter : WORLD;
struct pointData
{
	float4 pos;
	float4 col;
};
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;
RWStructuredBuffer<uint> hitBuffer : BACKBUFFER;
int slice;
bool countmode;

[numthreads(1,1,1)]
void CS_Clear(uint3 i : SV_DispatchThreadID)
{
	hitBuffer[slice] = 0;
}

[numthreads(64, 1, 1)]
void CS_HitTest( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	float4 test = mul(pcBuffer[i.x].pos, tFilter);
	if(	!(test.x < -0.5 || test.x > 0.5 ||
		test.y < -0.5 || test.y > 0.5 ||
		test.z < -0.5 || test.z > 0.5
		)){
			if(countmode){
					uint oldval;
					InterlockedAdd(hitBuffer[slice],1,oldval);
			}
			else hitBuffer[slice] = 1;
		}
	
}

technique11 Clear
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Clear() ) );
	}
}

technique11 HitTest
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_HitTest() ) );
	}
}