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
#include "../fxh/PhongPoint.fxh"

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV: VIEW;
	float4x4 tWV: WORLDVIEW;
	float4x4 tWVP: WORLDVIEWPROJECTION;
	float4x4 tVP : VIEWPROJECTION;	
	float4x4 tP: PROJECTION;
	float4x4 tWIT: WORLDINVERSETRANSPOSE;
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
	float3 NormO: NORMAL;
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
	
	float3 LightDirV: TEXCOORD4;
    float3 NormV: TEXCOORD5;
    float3 ViewDirV: TEXCOORD6;
	float3 PosW: TEXCOORD7;
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
	
	 //inverse light direction in view space
	output.PosW = mul(p, tW).xyz;
	float3 LightDirW = normalize(lPos - output.PosW);
    output.LightDirV = mul(float4(LightDirW,0.0f), tV).xyz;
	
    //normal in view space
    output.NormV = normalize(mul(mul(input.NormO, (float3x3)tWIT),(float3x3)tV).xyz);
	output.ViewDirV = -normalize(mul(p, tWV).xyz);
	
	return output;
}

/* ===================== PIXEL SHADER ===================== */

float4 PS_RGB(vs2ps input): SV_Target
{
    return input.col * PhongPoint(input.PosW, input.NormV, input.ViewDirV, input.LightDirV);
}

float4 PS_COLOR(vs2ps input): SV_Target
{
    return PhongPoint(input.PosW, input.NormV, input.ViewDirV, input.LightDirV);
}

float4 PS_POS(vs2ps input): SV_Target
{
    return input.col_pos * PhongPoint(input.PosW, input.NormV, input.ViewDirV, input.LightDirV);
}

float4 PS_GROUP(vs2ps input): SV_Target
{
    return input.col_group * PhongPoint(input.PosW, input.NormV, input.ViewDirV, input.LightDirV);
}

float4 PS_GROUP_FORCE(vs2ps input): SV_Target
{
	return input.col_group_force * PhongPoint(input.PosW, input.NormV, input.ViewDirV, input.LightDirV);
}

float4 PS_FORCE(vs2ps input): SV_Target
{
	return input.col_force * PhongPoint(input.PosW, input.NormV, input.ViewDirV, input.LightDirV);
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

technique10 Color
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_COLOR() ) );
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