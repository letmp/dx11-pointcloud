#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int groupId = -1;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	pointData pd = pcBuffer[i.x];
	if ( groupId == -1 || pd.groupId == groupId){
		
		float3 velocity = rwForceBuffer[i.x].acceleration;
		//Save the new Velocity in Buffer
		rwForceBuffer[i.x].velocity += velocity;
		//Apply Velocity to Position
		rwForceBuffer[i.x].position += rwForceBuffer[i.x].velocity;
		//increment Age
		rwForceBuffer[i.x].age ++;
		// stop accumulating forces
		rwForceBuffer[i.x].acceleration *=0;
		
	}
	
}

technique11 ApplyForce
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
