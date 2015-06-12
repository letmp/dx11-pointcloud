#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

StructuredBuffer<float3> velocity;
StructuredBuffer<float3> acceleration;
StructuredBuffer<float> mass;
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
			rwForceBuffer[i.x].velocity = velocity[i.x];
			rwForceBuffer[i.x].acceleration = acceleration[i.x];
			rwForceBuffer[i.x].mass = mass[i.x];
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
