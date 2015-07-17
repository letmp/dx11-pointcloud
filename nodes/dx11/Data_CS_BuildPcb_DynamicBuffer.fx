float4x4 tW : WORLD;

int drawIndex : DRAWINDEX;
int IdOffset;
int elementcount;
StructuredBuffer<float3> posBuffer <string uiname="Position Buffer";>;
StructuredBuffer<float4> colBuffer <string uiname="Color Buffer";>;

#include "_PointData.fxh"
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 DTid : SV_DispatchThreadID )
{
	
	if(DTid.x >= asuint(elementcount)){return;}
	
	float4 pos = float4(posBuffer[DTid.x],1);
	pos = mul(pos, tW);
	
	uint cnt, stride;
	colBuffer.GetDimensions(cnt,stride);
	float4 col = colBuffer[DTid.x % cnt];

	pointData pd = {pos.xyz, col, drawIndex + IdOffset};
	pcBuffer.Append(pd);
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
