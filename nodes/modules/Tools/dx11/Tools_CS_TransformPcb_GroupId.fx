float4x4 tW : WORLD;
int groupIds;

#include "..\..\Data\PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;
AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;

[numthreads(64, 1, 1)]
void CS_Transform( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	pointData pd = pcBuffer[i.x];
	if(	pcBuffer[i.x].groupId == groupIds || groupIds == -1){
		pd.pos = mul(pd.pos, tW);
		newPcBuffer.Append(pd);
	}
}

technique11 Transform
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Transform() ) );
	}
}