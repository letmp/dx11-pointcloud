//@author: tmp
//@help: constant shader to draw a pointcloudbuffer
//@tags:
//@credits: 

struct pointData
{
	float4 pos;
	float4 col;
};
StructuredBuffer<pointData> PointcloudBuffer;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};

cbuffer cbPerObj : register( b1 )
{
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct vsInput
{
	float4 pos : POSITION;
	uint ii : SV_InstanceID;
};

struct psInput
{
    float4 pos: SV_POSITION;
	float4 col: COLOR;
};

psInput VS(vsInput input)
{
    psInput output;	
	
	//Lookup index instead
	uint idx = input.ii;
	
	float4 p = input.pos;
	//Get position from full buffer
	p.xyz += PointcloudBuffer[idx].pos.xyz;
    output.pos = mul(p,tVP);
	
	output.col = PointcloudBuffer[idx].col;
	
    return output;
}

float4 PS_Tex(psInput input): SV_Target
{
	float4 col = input.col * cAmb;
	col.a *= Alpha;
    return col;
}


technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}