float4x4 tFilter : WORLD;
int slice;

#include "../fxh/_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

AppendStructuredBuffer<pointData> filteredPcBuffer : BACKBUFFER;

[numthreads(64, 1, 1)]
void CS_Restrict( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	//check if point position is inside the given filter(s)
	float3 pointCoord = mul(float4(pcBuffer[i.x].pos,1), tFilter).xyz;
	if(	!(pointCoord.x < -0.5 || pointCoord.x > 0.5 ||
		pointCoord.y < -0.5 || pointCoord.y > 0.5 ||
		pointCoord.z < -0.5 || pointCoord.z > 0.5
		)){
			pointData pd = pcBuffer[i.x];
			pd.groupId = slice;
			filteredPcBuffer.Append(pd);
		}
}

[numthreads(64, 1, 1)]
void CS_Subtract( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	//check if point position is inside the given filter(s)
	float3 pointCoord = mul(float4(pcBuffer[i.x].pos,1), tFilter).xyz;
	if(	(pointCoord.x < -0.5 || pointCoord.x > 0.5 ||
		pointCoord.y < -0.5 || pointCoord.y > 0.5 ||
		pointCoord.z < -0.5 || pointCoord.z > 0.5
		)){
			filteredPcBuffer.Append(pcBuffer[i.x]);
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