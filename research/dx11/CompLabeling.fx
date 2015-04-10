Texture2DArray<float> texture2d <string uiname="Texture";>;
float2 textureSize;
StructuredBuffer<float4> pcBuffer;

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
};

struct VS_IN
{
	uint iv : SV_VertexID;
	uint ii : SV_InstanceID;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 Col: COLOR;
};

vs2ps VS(VS_IN inp)
{
    vs2ps Out = (vs2ps)0;
	//Out.PosWVP  = input.PosO;
	
	float x = (2.0 / textureSize.x) * (inp.iv + 1.0);
	float y = (2.0 / textureSize.y) * (textureSize.y - inp.ii - 1);
	Out.PosWVP  = float4(x - 1.0,y - 1.0 ,0,1);
	
	float r = (1.0 / textureSize.x) * (inp.iv + 1.0);
	float g = (1.0 / textureSize.y) * (inp.ii + 1.0);
    //Out.Col = float4(r,g,0,1);
	
	Out.Col = pcBuffer[inp.iv + inp.ii * textureSize.x];
    return Out;
}

float4 PS(vs2ps In): SV_Target
{
    return In.Col;
}

technique10 allToOne
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}