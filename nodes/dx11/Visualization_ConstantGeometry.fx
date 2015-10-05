//@author: tmp 
//@help: Draws a PointCloud
//@tags: DX11.Pointcloud
//@credits: vvvv

#include "../fxh/_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

#include "../fxh/_ForceData.fxh"
StructuredBuffer<forceData> forceBuffer<String uiname="ForceBuffer";>;
StructuredBuffer<uint> indexBuffer<String uiname="ForceIndexBuffer";>;

#include "../fxh/Helper.fxh"

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	bool withHeading <String uiname="Enable Heading";> = false;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	int groupFilter;
};

struct vsInput
{
	float4 pos : POSITION;
	uint ii : SV_InstanceID;
};

struct vs2ps
{
    float4 pos: SV_POSITION;
	float4 col: COLOR;
	float4 col_pos : TEXCOORD0;
	float4 col_group : TEXCOORD1;
	float4 col_group_force : TEXCOORD2;
	float4 col_force : TEXCOORD3;
};

/* ===================== VERTEX SHADER ===================== */

vs2ps VS(vsInput input)
{
    vs2ps output = (vs2ps)0;
    
	uint idx = input.ii; // index of point in pointcloudbuffer
	uint idxf = indexBuffer[idx]; // index of corresponding point in forcebuffer
	
	float4 p = input.pos;
	
	// rotate wrt. velocity
	if (withHeading) p = mul(p,calcRotation(forceBuffer[idxf].velocity));
	
	// apply groupfilter
	if (groupFilter != pcBuffer[idx].groupId && groupFilter != -1) p.w = 0.0f;
	p.xyz += pcBuffer[idx].pos.xyz;
	output.pos = mul(p,mul(tW,tVP));
	
	output.col = decodeColor( pcBuffer[idx].col );
	output.col_pos = float4(pcBuffer[idx].pos,1);
	output.col_group = randColor(pcBuffer[idx].groupId);
	output.col_group_force = randColor(forceBuffer[idxf].groupId);
	output.col_force = float4(forceBuffer[idxf].velocity , 1) * 100;
	
	return output;
}

/* ===================== PIXEL SHADER ===================== */

float4 PS_RGB(vs2ps input): SV_Target
{
	float4 col = input.col * cAmb;
    return col;
}

float4 PS_POS(vs2ps input): SV_Target
{
    return input.col_pos;
}

float4 PS_GROUP(vs2ps input): SV_Target
{
    return input.col_group;
}

float4 PS_GROUP_FORCE(vs2ps input): SV_Target
{
	return input.col_group_force;
}

float4 PS_FORCE(vs2ps input): SV_Target
{
	return input.col_force;
}

/* ===================== TECHNIQUE ===================== */

technique10 RGB
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

technique10 GroupId
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_GROUP() ) );
	}
}

technique10 GroupIdForce
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_GROUP_FORCE() ) );
	}
}

technique10 Force
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_FORCE() ) );
	}
}