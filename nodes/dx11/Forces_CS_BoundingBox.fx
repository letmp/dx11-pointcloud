#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int groupId = -1;
int onEventGroup = -1;
float3 width = float3(1,1,1);
bool Apply;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply) {
		if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
	
	if (rwForceBuffer[i.x].position.x > width.x/2)
	{
		rwForceBuffer[i.x].position.x = width.x/2;
		rwForceBuffer[i.x].velocity.x *= -1; 
		rwForceBuffer[i.x].groupId = onEventGroup;
	}
	else if (rwForceBuffer[i.x].position.x < -width.x/2)
	  {
	  	rwForceBuffer[i.x].velocity.x *= -1;
	  	rwForceBuffer[i.x].position.x = -width.x/2;
		rwForceBuffer[i.x].groupId = onEventGroup;
	  	
	  }
		if (rwForceBuffer[i.x].position.y > width.y/2)
	{
		rwForceBuffer[i.x].position.y = width.y/2;
		rwForceBuffer[i.x].velocity.y *= -1; 
		rwForceBuffer[i.x].groupId = onEventGroup;
	}
	else if (rwForceBuffer[i.x].position.y < -width.y/2)
	  {
	  	rwForceBuffer[i.x].velocity.y *= -1;
	  	rwForceBuffer[i.x].position.y = -width.y/2;
		rwForceBuffer[i.x].groupId = onEventGroup;
	  	
	  }
		if (rwForceBuffer[i.x].position.z > width.z/2)
	{
		rwForceBuffer[i.x].position.z = width.z/2;
		rwForceBuffer[i.x].velocity.z *= -1; 
		rwForceBuffer[i.x].groupId = onEventGroup;
	}
	else if (rwForceBuffer[i.x].position.z < -width.z/2)
	  {
	  	rwForceBuffer[i.x].velocity.z *= -1;
	  	rwForceBuffer[i.x].position.z = -width.z/2;
		rwForceBuffer[i.x].groupId = onEventGroup;
	  	
	  }
	  
			
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
