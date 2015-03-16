float4x4 tFilter : WORLD;
int groupIds;

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;

[numthreads(64, 1, 1)]
void CS_Restrict( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	if(	pcBuffer[i.x].groupId == groupIds || groupIds == -1){
		pointData pd = pcBuffer[i.x];
		newPcBuffer.Append(pd);
	}
}

[numthreads(64, 1, 1)]
void CS_Subtract( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	if(	pcBuffer[i.x].groupId != groupIds || groupIds == -1){
		pointData pd = pcBuffer[i.x];
		newPcBuffer.Append(pd);
	}
}

technique11 Restrict
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Restrict() ) );
	}
}

technique11 Subtract
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Subtract() ) );
	}
}