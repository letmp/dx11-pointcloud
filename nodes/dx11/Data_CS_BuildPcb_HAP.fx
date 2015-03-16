Texture2D tex <string uiname="Texture";>;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;
int elementcount;
SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

#include "_PointData.fxh"
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 DTid : SV_DispatchThreadID )
{
	
	if(DTid.x >= asuint(elementcount)){return;}
	float sX = uv[DTid.x].x;
	float sY = uv[DTid.x].y / 3 + 1;
	float4 pos =  tex.SampleLevel(sPoint,float2(sX,sY),0);
	
	sY = uv[DTid.x].y / 3 + 0.5;
	float4 col =  tex.SampleLevel(sPoint,float2(sX,sY),0);
	
	sY = uv[DTid.x].y / 3;
	int groupId =  tex.SampleLevel(sPoint,uv[DTid.x * 3],0).r;
	
	//float4 col = float4(1,1,1,1);
	//int groupId = 0;
	pointData pd = {pos, col, groupId};
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
