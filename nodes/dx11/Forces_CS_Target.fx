#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;
StructuredBuffer<uint> updatedBufferIn;

StructuredBuffer<float3> Target;
int groupId = -1;
float MaxSpeed = 0.01;
float MaxForce =  0.001;
float LandingRadius =  0.1;
bool updatedOnly;
bool Apply;

float3 limitIt(in float3 v, float3 Maximum)
{
	if (length(v) > length(Maximum)) {
		v = normalize(v) * Maximum;
		return v;
	}
	
	else {
		return v;
	}
	
}

float length(in float3 v)
{
	return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

float3 normalize(in float3 v)
{
	float length = sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
	
	if (length != 0)
	return v * (1 / length);
	else
	return 0;
}

[numthreads(64, 1, 1)]
void CS_Target( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	
	if (Apply) {
		if (updatedOnly && updatedBufferIn[i.x] == 0){ return; }
		
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
			
			float3 p = rwForceBuffer[i.x].position;
			float3 v = rwForceBuffer[i.x].velocity;
			float3 a = rwForceBuffer[i.x].acceleration;
			
			Target.GetDimensions(cnt,stride);	
			float3 target = Target[i.x % cnt];
			float3 desired = target - p; //calculates disired velocity-vector
			
			float d = length(desired); //d = distance
			desired = normalize(desired); //normalize vector
			if (d < LandingRadius)
			{
				float map = saturate(d);
				desired *= map;
				
			} else {
				
				desired *= MaxSpeed;
				
			}
			
			float3 steer = desired - v;
			steer = limitIt(steer,MaxForce);
			
			rwForceBuffer[i.x].acceleration += steer;
		}
		
	}
}

technique11 TargetForce
{
	pass P0{ SetComputeShader(CompileShader(cs_5_0, CS_Target())); }
}
