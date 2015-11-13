Texture2D texRGB <string uiname="RGB";>;
Texture2D texDepth <string uiname="Depth";>;
Texture2D texRGBDepth <string uiname="RGBDepth";>;

float2 Resolution;
bool useRawData;
SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

struct data {
	float depth;
	int col;
};
#include "../fxh/Helper.fxh"
RWStructuredBuffer<data> depthBuffer : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(8, 8, 1)]
void CSPackKinectBuffer( uint3 i : SV_DispatchThreadID )
{
	uint w,h, dummy;
	texDepth.GetDimensions(0,w,h,dummy);
	if (i.x >= asuint(Resolution.x) || i.y >= asuint(Resolution.y)) { return; }
	
	float2 coord = i.xy * float2(w / Resolution.x, h / Resolution.y) / float2(w,h);
	float depth =  texDepth.SampleLevel(sPoint, coord,0 ).r * 65.535;
	
	// sample color
	float2 map = texRGBDepth.SampleLevel(sPoint,coord,0).rg;
	if(useRawData){
		map.x /= 1920.0f;
		map.y /= 1080.0f;
	}
	
	int col = encodeColor( texRGB.SampleLevel(sPoint,map,0) );
	
	int index = i.x + (Resolution.x * i.y);
	data d = { depth, col };
	depthBuffer[index] = d;
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 PackKinectBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSPackKinectBuffer() ) );
	}
}
