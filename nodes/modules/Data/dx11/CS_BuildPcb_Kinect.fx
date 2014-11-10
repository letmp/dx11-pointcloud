float4x4 tW : WORLD;

Texture2D texRGB <string uiname="RGB";>;
Texture2D texDepth <string uiname="Depth";>;
Texture2D texRGBDepth <string uiname="RGBDepth";>;
float2 FOV;
int elementcount;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

struct pointData
{
	float4 pos;
	float4 col;
};
AppendStructuredBuffer<pointData> PointcloudBuffer : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 DTid : SV_DispatchThreadID )
{
	
	if(DTid.x >= asuint(elementcount)){return;}
	
	float2 uvc = uv[DTid.x];
	
	float depth =  texDepth.SampleLevel(sPoint,uvc,0).r * 65.535 ;
	float XtoZ = tan(FOV.x/2) * 2;
    float YtoZ = tan(FOV.y/2) * 2;
	
	float4 pos = float4(0,0,0,1);
	pos.x = ((uvc.x - 0.5) * depth * XtoZ * -1);
	pos.y = ((0.5 - uvc.y) * depth * YtoZ);
	pos.z = depth;
	pos = mul(pos, tW);
		
	float2 coords = texRGBDepth.SampleLevel(sPoint, uvc ,0).rg;
	float4 col = texRGB.SampleLevel(sPoint,coords,0);
	
	//float4 col = float4(uvc,1,1);
	pointData pd = {pos, col};
	PointcloudBuffer.Append(pd);
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
