#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

float4x4 tW: WORLD;
Texture2D texVelocity <string uiname="Texture Velocity";>;
Texture2D texAcceleration <string uiname="Texture Acceleration";>;
Texture2D texMass <string uiname="Texture Mass";>;
SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

int groupId = -1;
bool Apply;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if(Apply){
		pointData pd = pcBuffer[i.x];
		if ( groupId == -1 || pd.groupId == groupId){
			float3 pos = pd.pos;
			float4 ppos = mul(float4(pd.pos,1), tW);
			float2 uv = ppos.xy/ppos.w; // these are the uv coords where we sample
			uv.x = uv.x * 0.5 + 0.5;
			uv.y = uv.y * -0.5 + 0.5;
			
			float3 vel = texVelocity.SampleLevel(sPoint,uv,0).xyz;
			if (vel.r > 0.0f || vel.g > 0.0f || vel.b > 0.0f) rwForceBuffer[i.x].velocity = vel;
			
			float3 acc = texAcceleration.SampleLevel(sPoint,uv,0).xyz;
			if (acc.r > 0.0f || acc.g > 0.0f || acc.b > 0.0f) rwForceBuffer[i.x].acceleration = acc;
			
			float m = texMass.SampleLevel(sPoint,uv,0).x;
			if (m > 0.0f) rwForceBuffer[i.x].mass = m;
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
