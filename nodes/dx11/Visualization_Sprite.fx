//@author: tmp
//@help: Draws a Sprite per Point
//@tags: DX11.Pointcloud
//@credits: vvvv

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

Texture2D texture2d <string uiname="Texture";>;

SamplerState sampler0 <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV  : VIEW;
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tWVP: WORLDVIEWPROJECTION;
	
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	int groupFilter;
};

float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };

struct vsInput
{
	float4 pos : POSITION;
	float4 TexCd: TEXCOORD0;
	uint ii : SV_InstanceID;
};

struct vs2ps
{
	float4 pos: SV_POSITION;
	float4 col: COLOR;
	float4 col_pos : TEXCOORD0;
	float4 col_group : TEXCOORD1;
	float4 TexCd: TEXCOORD2;
};

/* ===================== VERTEX SHADER ===================== */

float4 randColor(in float id) {
	float noiseX = (frac(sin(dot(float2(id,id), float2(12.9898,78.233) 	 )) * 43758.5453));
	float noiseY = (frac(sin(dot(float2(id,id), float2(12.9898,78.233) * 2.0)) * 43758.5453));
	float noiseZ = sqrt(1 - noiseX * noiseX);
	return float4(noiseX, noiseY,noiseZ,1);
}

vs2ps VS_SPRITE(vsInput input)
{
	vs2ps output = (vs2ps)0;
	
	uint idx = input.ii;
	
	float4 p;
	p.xyz = pcBuffer[idx].pos;
	float4 pv = mul(tV,input.pos);
	float3 PosV = float3(pv.xyz)  + float3(p.xyz);
	float4 finalPos = float4(PosV,1.0);
	// apply groupfilter
	if (groupFilter != pcBuffer[idx].groupId && groupFilter != -1) finalPos.w = 0.0f;
	
	output.pos =  mul(finalPos, tWVP);

	output.col = pcBuffer[idx].col;
	output.col_pos.xyz = pcBuffer[idx].pos;
	output.col_group = randColor(pcBuffer[idx].groupId);
	output.TexCd = input.TexCd;
	return output;
}

/* ===================== PIXEL SHADER ===================== */


float4 PS_TEXTURE(vs2ps input): SV_Target
{
	float4 col = texture2d.Sample(sampler0,input.TexCd.xy) * cAmb;

	return col;
}

float4 PS_COLORTEXTURE(vs2ps input): SV_Target
{
	float4 rgb = input.col * cAmb;
	float4 col = texture2d.Sample(sampler0,input.TexCd.xy) * cAmb;
	
	return col * rgb;
}

/* ===================== TECHNIQUE ===================== */

technique10 Rgb
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_SPRITE() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_COLORTEXTURE() ) );
	}
}

technique10 Color
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_SPRITE() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_TEXTURE() ) );
	}
}