//@author: tmp 
//@help: Draws a PointCloud
//@tags: DX11.Pointcloud
//@credits: vvvv

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

#include "_ForceData.fxh"
StructuredBuffer<forceData> forceBuffer<String uiname="ForceBuffer";>;
StructuredBuffer<uint> indexBuffer<String uiname="ForceIndexBuffer";>;

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

/* ===================== HELP FUNCTIONS ===================== */

float4 randColor(in float id) {
    float noiseX = (frac(sin(dot(float2(id,id), float2(12.9898,78.233) 	 )) * 43758.5453));
	float noiseY = (frac(sin(dot(float2(id,id), float2(12.9898,78.233) * 2.0)) * 43758.5453));
    float noiseZ = sqrt(1 - noiseX * noiseX);
    return float4(noiseX, noiseY,noiseZ,1);
}

float4x4 calcRotation (float3 vel){
	static const float PI = 3.14159265f;
	
	float length = sqrt(vel.x * vel.x + vel.y * vel.y  + vel.z * vel.z); //length
	float nVelX = vel.x;
	float nVelY = vel.y;
	float nVelZ = vel.z;
	
	if (length != 0)
	{
		nVelX = vel.x / length;
		nVelY = vel.y / length;
		nVelZ = vel.z / length;
	}
	
	//converter
	float conv = (2 * PI);
	float3 rotationV;
	
	//CONVERT FROM POLAR TO CARTESIAN VVVV-STYLE
	float lengthPol = nVelX * nVelX + nVelY * nVelY + nVelZ * nVelZ;
	
	if (lengthPol > 0)
	{
		lengthPol = sqrt(lengthPol);
		float pitch = asin(nVelY / lengthPol);
		float yaw = 0.0;
		if(nVelZ != 0)
		yaw = atan2(-nVelX, -nVelZ);
		else if (nVelX > 0)
		yaw = -PI / 2;
		else
		yaw = PI / 2;
		
		rotationV = float3(pitch, yaw, lengthPol) / conv ;
	}
	
	else
	
	{
		rotationV = float3(0,0,0);
	}
	
	rotationV*= 2*PI;
	
	float sx = sin(rotationV.x);
	float cx = cos(rotationV.x);
	float sy = sin(rotationV.y);
	float cy = cos(rotationV.y);
	float sz = sin(rotationV.z);
	float cz = cos(rotationV.z);
	
	return float4x4(	 cz*cy+sz*sx*sy, sz*cx, cz*-sy+sz*sx*cy, 0,
	-sz*cy+cz*sx*sy, cz*cx, sz*sy+cz*sx*cy , 0,
	cx * sy       ,-sx   , cx * cy        , 0,
	0             , 0    , 0              , 1);
}

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
	
	output.col = pcBuffer[idx].col;
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