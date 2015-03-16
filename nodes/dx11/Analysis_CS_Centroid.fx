Texture2D tex;
RWStructuredBuffer<float4> centroidBuffer : BACKBUFFER;
float pixPos;
int slice;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

[numthreads(1, 1, 1)]
void CS_CalculateCentroid( uint3 i : SV_DispatchThreadID)
{ 
	float4 accum = tex.SampleLevel(sPoint, float2(pixPos,0),0);
	if (accum.w > 0.0f){
		centroidBuffer[slice] = float4(accum.x/accum.w, accum.y/accum.w, accum.z/accum.w , accum.w);		
	}
	else centroidBuffer[slice] = float4(0,0,0,0);
}

technique11 CalculateCentroid
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_CalculateCentroid() ) );
	}
}