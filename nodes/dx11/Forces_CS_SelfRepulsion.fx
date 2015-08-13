#include "_ForceData.fxh"
RWStructuredBuffer<forceData> rwForceBuffer : BACKBUFFER;

int groupId = -1;
float gamma;
float radius;
float repulseAmount;
bool Apply;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwForceBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	float dist = 0;
	float g = gamma/(1.00001-gamma);

	for( uint j = 0; j < cnt; j++ )
	{
		if (Apply) {
			if ( groupId == -1 || rwForceBuffer[i.x].groupId == groupId){
				dist = distance(rwForceBuffer[i.x].position,rwForceBuffer[j].position);
				if (i.x != j){
					if (dist < radius){
			  			float f = saturate( 1 - dist * 2);
			  			f = pow( f, g );
						rwForceBuffer[i.x].velocity += (rwForceBuffer[i.x].position - rwForceBuffer[j].position) * lerp(0.0f,1.00f,f)*radius*repulseAmount;
				 	}
				}	
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
