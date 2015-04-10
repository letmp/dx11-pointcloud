Texture2D tex <string uiname="Texture";>;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;
float2 textureSize;

RWStructuredBuffer<float4> LabelBuffer : BACKBUFFER;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

[numthreads(64, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 

	float2 offset = float2(1 / textureSize.x, 1 / textureSize.y);
	
	float2 scoord = uv[i.x];
	float4 coords = tex.SampleLevel(sPoint,scoord,0);
	int index = ((scoord.x - 0.5) * textureSize.x) + (scoord.y * textureSize.y) * textureSize.x;
	
	LabelBuffer[index] = coords;
}

technique11 ImageToBuffer
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS() ) );}
}