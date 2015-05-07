float4x4 tW : WORLD;

Texture2D texRGB <string uiname="RGB";>;
Texture2D texDepth <string uiname="Depth";>;
Texture2D texRayTable <string uiname="RayTable";>;
Texture2D texRGBDepth <string uiname="RGBDepth";>;
int drawIndex : DRAWINDEX;
int IdOffset;
int elementcount;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;

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
	
	float2 uvc = uv[DTid.x];
	
	float depth =  texDepth.SampleLevel(sPoint,uvc,0).r * 65.535 ;
	if (depth > 0){
		
		float4 pos = float4(0,0,0,1);
		float2 raytable =  texRayTable.SampleLevel(sPoint,uvc,0).xy;
		pos.x = depth * raytable.x * -1;
		pos.y = depth * raytable.y;
		pos.z = depth;
		pos = mul(pos, tW);
			
		float2 coords = texRGBDepth.SampleLevel(sPoint, uvc ,0).rg;
		float4 col = texRGB.SampleLevel(sPoint,coords,0);
		
		pointData pd = {pos.xyz, col, drawIndex + IdOffset};
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
