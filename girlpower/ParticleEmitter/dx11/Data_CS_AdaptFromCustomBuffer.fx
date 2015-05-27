// Original Pointcloud Data
#include "_PointData.fxh"
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

// Our Custom Buffer
#include "_CustomPointData.fxh"
StructuredBuffer<customPointData> cpcBuffer;

int elementcount;

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 i : SV_DispatchThreadID )
{
	
	if(i.x >= asuint(elementcount)){return;}
	
	customPointData cpd = cpcBuffer[i.x];
	float3 pos = cpd.pos;
	float4 col = cpd.col;
	int groupId = cpd.groupId;
	
	if(pos.x != 0.0 && pos.y != 0.0 && pos.z != 0.0){
		pointData pd = {pos,col, groupId};
		pcBuffer.Append(pd);
	}
	
}

technique11 FromCustomBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSBuildPointcloudBuffer() ) );
	}
}
