#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;
StructuredBuffer<uint> updatedBufferIn;

int groupId = -1;

//Nice 3D-Perlin-Noise by dottore == natan sinigaglia
#include "_NoiseFunction.fxh"

SamplerState sPoint : IMMUTABLE
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Border;
	AddressV = Border;
};

//NOISE FORCE:
float3 noise_amount = float3(0.0f,0.0f,0.0f);
float noise_time;
int noise_oct;
float noise_freq = 1;
float noise_lacun = 1.666;
float noise_pers = 0.666;

bool updatedOnly;
bool Apply;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if(Apply){
			if (updatedOnly && updatedBufferIn[i.x] == 0){ return; }
		
			float3 pos = rwForceBuffer[i.x].position;
			
			// Noise Force
			float3 noiseF = float3(
			fBm(float4( pos + float3(51,2.36,-5),noise_time),noise_oct,noise_freq,noise_lacun,noise_pers),
			fBm(float4( pos + float3(98.2,-9,-36),noise_time),noise_oct,noise_freq,noise_lacun,noise_pers),
			fBm(float4( pos + float3(0,10.69,6),noise_time),noise_oct,noise_freq,noise_lacun,noise_pers)
			);
			
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			rwForceBuffer[i.x].acceleration += noiseF * noise_amount;
			
		}
		
	}
	
}

technique11 ApplyForce
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
