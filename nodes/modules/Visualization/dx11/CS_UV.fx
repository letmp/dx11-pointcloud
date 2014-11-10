float4x4 tW : WORLD;

int elementcount;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;

struct pointData
{
	float4 pos;
};
RWStructuredBuffer<pointData> PointcloudBuffer : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 DTid : SV_DispatchThreadID )
{
	
	if(DTid.x >= asuint(elementcount)){return;}
	
	float4 pos = float4(uv[DTid.x],0,1);
		
	//float4 col = float4(uvc,1,1);
	
	pointData pd = {pos};
	PointcloudBuffer[DTid.x] = pd;
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 BuildPointcloudBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSBuildPointcloudBuffer() ) );
	}
}
