RWStructuredBuffer<float3> rwbuffer : BACKBUFFER;
Texture2D posTex <string uiname="Texture Positions";>;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;
int count;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};


[numthreads(1, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 
	if (i.x >=  asuint(count)) { return;}
	float3 pos = posTex.SampleLevel(sPoint,uv[i.x],0).xyz;
	rwbuffer[i.x] = pos.xyz;
}

technique11 Process
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}







