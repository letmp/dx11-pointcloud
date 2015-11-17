StructuredBuffer<float> posBufferEncoded <string uiname="Encoded Position Buffer";>;
StructuredBuffer<int> indexBuffer <string uiname="IndexBuffer";>;
StructuredBuffer<int> colBufferEncoded <string uiname="Encoded Color Buffer";>;
float2 Resolution;
float2 FOV;
int elementcount;

#include "../fxh/_PointData.fxh"
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

#include "../fxh/Helper.fxh"

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSUnpackKinectBuffer( uint3 i : SV_DispatchThreadID )
{
	if(i.x >= (uint)elementcount){return;}
	
	float4 pos;
	int index = indexBuffer[i.x];
	int2 iPos = int2(index % Resolution.x, index / Resolution.x);
	float2 coord = iPos / Resolution;
	float depth = posBufferEncoded[i.x];
	float XtoZ = tan(FOV.x/2) * 2;
    float YtoZ = tan(FOV.y/2) * 2;
	pos.x = ((coord.x - 0.5) * depth * XtoZ * -1);
	pos.y = ((0.5 - coord.y) * depth * YtoZ);		
	pos.z = depth;
	
	int col = colBufferEncoded[i.x];
	
	pointData pd = {pos.xyz, col, 0 };
	pcBuffer.Append(pd);
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 PackKinectBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSUnpackKinectBuffer() ) );
	}
}
