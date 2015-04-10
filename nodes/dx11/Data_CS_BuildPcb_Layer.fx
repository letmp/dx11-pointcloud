float4x4 tW : WORLD;

Texture2D texRGB <string uiname="RGB";>;
Texture2D texDepth <string uiname="Depth";>;
Texture2D texRGBDepth <string uiname="RGBDepth";>;
int drawIndex : DRAWINDEX;
int IdOffset;
float2 FOV;
int elementcount;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;

float4x4 tP <string uiname="Projection";>;

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
#define linstep(a,b,x) saturate((x-a)/(b-a))

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 DTid : SV_DispatchThreadID )
{
	
	if(DTid.x >= asuint(elementcount)){return;}
	
	float2 uvc = uv[DTid.x];
	float4 col = texRGB.SampleLevel(sPoint,uvc,0);
	float depth =  texDepth.SampleLevel(sPoint,uvc,0).r;
	float ld = tP._43 / (depth - tP._33);
	depth = ld;
	
	if (depth > 0 && col.a > 0){
		float XtoZ = tan(FOV.x/2) * 2;
	    float YtoZ = tan(FOV.y/2) * 2;
		
		float4 pos = float4(0,0,0,1);
		pos.x = ((uvc.x - 0.5) * depth * XtoZ );
		pos.y = ((0.5 - uvc.y) * depth * YtoZ);
		pos.z = depth;
		pos = mul(pos, tW);
		
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
