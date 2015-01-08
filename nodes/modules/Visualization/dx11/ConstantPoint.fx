//@author: tmp 
//@help: Generates a colored PointCloud
//@tags: DX11, Kinect, Pointcloud
//@credits: vvvv

struct pointData
{
	float4 pos;
	float4 col;
	int filterId;
};
StructuredBuffer<pointData> pcBuffer;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct vsInput
{
	uint ii : SV_VertexID;
};

struct vs2ps
{
    float4 pos: SV_POSITION;
	float4 col: COLOR;
	float4 col_pos : TEXCOORD0;
};

/* ===================== VERTEX SHADER ===================== */

vs2ps VS(vsInput input)
{
    vs2ps output = (vs2ps)0;
    
	uint idx = input.ii;
	
	float4 p = float4(0,0,0,1);
	p.xyz += pcBuffer[idx].pos.xyz;
	output.pos = mul(p,mul(tW,tVP));
	
	output.col = pcBuffer[idx].col;
	output.col_pos = pcBuffer[idx].pos;
	
	return output;
}

/* ===================== PIXEL SHADER ===================== */

float4 PS_RGB(vs2ps input): SV_Target
{
	float4 col = input.col * cAmb;
	col.a *= Alpha;
    return col;
}

float4 PS_POS(vs2ps input): SV_Target
{
    return input.col_pos;
}

float4 PS_COLOR(vs2ps input): SV_Target
{
	float4 col = cAmb;
	col.a *= Alpha;
    return col;
}

/* ===================== TECHNIQUE ===================== */

technique10 Rgb
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_RGB() ) );
	}
}

technique10 Position
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_POS() ) );
	}
}

technique10 Color
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_COLOR() ) );
	}
}