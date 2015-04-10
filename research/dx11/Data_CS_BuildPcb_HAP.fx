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
	float sX = uv[DTid.x + 2 * elementcount].x;
	float sY = uv[DTid.x + 2 * elementcount].y;
	float3 pos =  tex.SampleLevel(sPoint,float2(sX,sY),0).xyz;
	
	if(pos.x != 0 && pos.y != 0 && pos.z != 0){
		sX = uv[DTid.x + elementcount].x;
		sY = uv[DTid.x + elementcount].y;
		float4 col =  tex.SampleLevel(sPoint,float2(sX , sY),0);
		
		sX = uv[DTid.x].x;
		sY = uv[DTid.x].y;
		int groupId =  tex.SampleLevel(sPoint,float2(sX , sY),0).r;
		
		pointData pd = {pos, col, groupId};
		pcBuffer.Append(pd);
	}
	
	
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
