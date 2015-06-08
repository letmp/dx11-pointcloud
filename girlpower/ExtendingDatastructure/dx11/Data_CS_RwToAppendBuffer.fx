#include "_PointData.fxh"

StructuredBuffer<pointData> pdBuffer;
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

int elementcount;

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 i : SV_DispatchThreadID )
{
	
	if(i.x >= asuint(elementcount)){return;}
	
	pointData pd = pdBuffer[i.x];
	pcBuffer.Append(pd);
	
}

technique11 FromCustomBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSBuildPointcloudBuffer() ) );
	}
}
