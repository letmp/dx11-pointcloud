//@author: tmp 
//@help: Generates a colored PointCloud
//@tags: DX11, Kinect, Pointcloud
//@credits: vvvv

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
float maxElementCount;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	
};
float2 R:TARGETSIZE;
cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	int groupFilter;
};

struct vsInput
{
	uint iv : SV_VertexID;
	uint ii : SV_InstanceID;
};

struct vs2ps
{
    float4 pos: SV_POSITION;
	float4 col: COLOR;
	//float4 enc_pos: TEXCOORD0;
	//float enc_groupId: TEXCOORD1;
};

/* ===================== VERTEX SHADER ===================== */

vs2ps VS(vsInput input)
{
    vs2ps output = (vs2ps)0;
    float x = (2.0 / R.x) * (input.iv + 1.0f);
	float y = (2.0 / R.y) * (input.ii);
	output.pos  = float4(x - 1.0f,y - 1.0f ,0.0f,1.0f);
	
	int index = (input.iv + input.ii * R.x);
	
	float4 col;
	if (index <= maxElementCount){
		col = float4(pcBuffer[index].pos,1);
	}
	
	else if( maxElementCount < index && index < maxElementCount * 2){
		col = pcBuffer[index/2.0].col;
	}
	
	else if( maxElementCount * 2 < index && index < maxElementCount * 3){
		int groupId = pcBuffer[index/3.0].groupId;
		col = float4(groupId,0,0,1);
	}
		
	output.col = col;

	return output;
}

/* ===================== PIXEL SHADER ===================== */

float4 PS_RGB(vs2ps input): SV_Target
{
	float4 col = input.col;
    return col;
}

/* ===================== TECHNIQUE ===================== */

technique10 DataToTexture
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_RGB() ) );
	}
}