float4x4 tW : WORLD;

Texture2D texRGB <string uiname="RGB";>;
Texture2D texDepth <string uiname="Depth";>;
int drawIndex : DRAWINDEX;
int IdOffset;
float2 FOV;
float2 Resolution;

float4x4 tP <string uiname="Projection";>;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

#include "../fxh/_PointData.fxh"
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

#include "../fxh/Helper.fxh"

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================
#define linstep(a,b,x) saturate((x-a)/(b-a))

[numthreads(8, 8, 1)]
void CSBuildPointcloudBuffer( uint3 i : SV_DispatchThreadID )
{
	if (i.x >= (uint)Resolution.x || i.y >= (uint) Resolution.y) { return; }
	
	float2 coord = i.xy / Resolution;
	float4 col = texRGB.SampleLevel(sPoint,coord,0);
	float depth =  texDepth.SampleLevel(sPoint,coord,0).r;
	float ld = tP._43 / (depth - tP._33);
	depth = ld;
	
	if (depth > 0 && col.a > 0){
		float XtoZ = tan(FOV.x/2) * 2;
	    float YtoZ = tan(FOV.y/2) * 2;
		
		float4 pos = float4(0,0,0,1);
		pos.x = ((coord.x - 0.5) * depth * XtoZ );
		pos.y = ((0.5 - coord.y) * depth * YtoZ);
		pos.z = depth;
		pos = mul(pos, tW);
		
		pointData pd = {pos.xyz, encodeColor(col), drawIndex + IdOffset};
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
