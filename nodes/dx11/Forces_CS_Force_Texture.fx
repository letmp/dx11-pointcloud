#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;
StructuredBuffer<uint> updatedBufferIn;

float4x4 tW: WORLD;
float4x4 tVP;

Texture2D texVelocity <string uiname="Texture Velocity";>;
float3 multiplicator_vel = float3(0.0f,0.0f,0.0f);

Texture2D texAcceleration <string uiname="Texture Acceleration";>;
float3 multiplicator_acc = float3(0.0f,0.0f,0.0f);

Texture2D texMass <string uiname="Texture Mass";>;
float multiplicator_mass = 0.0f;
SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

float threshold = 0.00;

int groupId = -1;
bool Apply;
bool updatedOnly;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if(Apply){
		
		if (updatedOnly && updatedBufferIn[i.x] == 0){ return; }
		
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			float4 ppos = mul(float4(rwForceBuffer[i.x].position,1), tVP);
			float2 uv = ppos.xy/ppos.w; // these are the uv coords where we sample
			uv.x = uv.x * 0.5 + 0.5;
			uv.y = uv.y * -0.5 + 0.5;
			
			float3 vel = mul(tW, float4(texVelocity.SampleLevel(sPoint,uv,0).xyz,1)).xyz;
			if (vel.r > threshold || vel.g > threshold || vel.b > threshold ||
			 vel.r < -threshold || vel.g < -threshold || vel.b < -threshold) rwForceBuffer[i.x].velocity += vel * multiplicator_vel;
						
			float3 acc = mul(tW, float4(texAcceleration.SampleLevel(sPoint,uv,0).xyz,1)).xyz;
			if (acc.r > threshold || acc.g > threshold || acc.b > threshold ||
			 acc.r < -threshold || acc.g < -threshold || acc.b < -threshold) rwForceBuffer[i.x].acceleration += acc * multiplicator_acc;
			
			float m = texMass.SampleLevel(sPoint,uv,0).x;
			if (m > threshold || m < - threshold) rwForceBuffer[i.x].mass += m * multiplicator_mass;
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
