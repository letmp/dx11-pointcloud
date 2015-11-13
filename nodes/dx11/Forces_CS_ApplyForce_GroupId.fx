#include "../fxh/_PointData.fxh"
RWStructuredBuffer<pointData> rwPcBufferOut : BACKBUFFER;

#include "../fxh/_ForceData.fxh"
StructuredBuffer<forceData> rwForceBufferIn;

int groupId = -1;
bool Apply;
bool CopyGroupIds = 0;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	rwPcBufferOut.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }
	
	if (Apply && rwForceBufferIn[i.x].alive == true) {
		pointData pd = rwPcBufferOut[i.x];
		if ( groupId == -1 || pd.groupId == groupId){
			forceData fd = rwForceBufferIn[i.x];			
			pd.pos = fd.position;
			if ( CopyGroupIds ) pd.groupId = fd.groupId;
			rwPcBufferOut[i.x] = pd;
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
