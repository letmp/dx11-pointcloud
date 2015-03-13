Texture2D texMin;
Texture2D texMax;
RWStructuredBuffer<float3> boundsBuffer : BACKBUFFER;
float pixPos;
int slice;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

[numthreads(1, 1, 1)]
void CS_CalculateBounds( uint3 i : SV_DispatchThreadID)
{ 
	float3 minCoords = texMin.SampleLevel(sPoint, float2(pixPos,0),0).xyz;
	float3 maxCoords = texMax.SampleLevel(sPoint, float2(pixPos,0),0).xyz;
	boundsBuffer[slice * 4 + 0] = (minCoords+maxCoords) / 2;
	boundsBuffer[slice * 4 + 1] = maxCoords - minCoords;
	boundsBuffer[slice * 4 + 2] = minCoords;
	boundsBuffer[slice * 4 + 3] = maxCoords;
}

technique11 CalculateBounds
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_CalculateBounds() ) );
	}
}