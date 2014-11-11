float4x4 tW : WORLD;
float4x4 tVP : VIEWPROJECTION;
float4x4 tWVP : WORLDVIEWPROJECTION;
float4x4 tWV : WORLDVIEW;
float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };

struct vsin
{
	float4 pos : POSITION;
};

struct vs2gs
{
    float4 pos : POSITION;
};

struct psIn
{
    float4 pos: SV_POSITION;
};

vs2gs VS_Pass(vsin input)
{
	//Passtrough in that case, since we will process in gs
	
	//We don't need normals we will calculate them on the fly
	vs2gs output;
	output.pos =input.pos;
    return output;
}

psIn VS(vsin input)
{
	//Standard displat, so transform as we would usually do
	psIn output;
	output.pos = mul(input.pos,tWVP);
    return output;
}


float eps : EPSILON = 0.000001f;

[maxvertexcount(6)]
void GS_Diag(triangle vs2gs input[3], inout LineStream<psIn> gsout)
{
	psIn o;
	
	float EPSILON = 0.01f;
	
	//Grab triangles positions
	float3 t1 = input[0].pos.xyz;
    float3 t2 = input[1].pos.xyz;
	float3 t3 = input[2].pos.xyz;
	
	
	//Compute lines
	float3 l1 = t2 - t1;
	float3 l2 = t3 - t2;
	float3 l3 = t3 - t1;
	
	//Compute edge length
	float dl1 = dot(l1,l1);
	float dl2 = dot(l2,l2);
	float dl3 = dot(l3,l3);
	
	//Get max length
	float maxdistsqr = max(max(dl1,dl2),dl3);
	
	/*Append if lower than max length
	please note that will not work with all goemetries,
	but for grid/boxes/spheres type of topology this is a very simple
	way. Also note this is not optimized, 
	code is quite expanded for readability*/
	
	if (dl1 < maxdistsqr)
	{
		o.pos = mul(float4(t1,1),tWVP);
		gsout.Append(o);
	
		o.pos = mul(float4(t2,1),tWVP);
		gsout.Append(o);
		
		gsout.RestartStrip();
	}
		
	if (dl2 < maxdistsqr)
	{
		o.pos = mul(float4(t3,1),tWVP);
		gsout.Append(o);
	
		o.pos = mul(float4(t2,1),tWVP);
		gsout.Append(o);
		
		gsout.RestartStrip();
	}
	
	
	if (dl3 < maxdistsqr)
	{
		o.pos = mul(float4(t3,1),tWVP);
		gsout.Append(o);
	
		o.pos = mul(float4(t1,1),tWVP);
		gsout.Append(o);
		
		gsout.RestartStrip();
	}
	
}

float4 PS(psIn input): SV_Target
{
    return cAmb;
}

technique10 Render
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

technique10 RenderNoDiagonals
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_Pass() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS_Diag() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





