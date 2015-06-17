#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;

#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int groupId = -1;
float dragC = 0.01f;
float3 gravity;
bool reset;

void AF (float3 force, uint index)
{
	//accumulating forces 
	force *= rwForceBuffer[index].mass;
	rwForceBuffer[index].acceleration += force;
}

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	// reset particle properties
	if (reset)
	{
		rwForceBuffer[i.x].velocity = 0;
		rwForceBuffer[i.x].age = 0;
		rwForceBuffer[i.x].mass = 0;
	}
	
	pointData pd = pcBuffer[i.x];
	if ( groupId == -1 || pd.groupId == groupId){
		
		float3 drag = rwForceBuffer[i.x].velocity * -1;
		drag *= dragC/10;

		AF(drag, i.x);
		AF(gravity * .001, i.x);
		
		rwForceBuffer[i.x].velocity += rwForceBuffer[i.x].acceleration;
		rwForceBuffer[i.x].acceleration *=0;
		rwForceBuffer[i.x].age ++;
		
	}
	
}

technique11 ApplyForce
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
