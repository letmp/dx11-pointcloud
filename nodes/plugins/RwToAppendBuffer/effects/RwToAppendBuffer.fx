
struct pointData
{
    float3 pos;
    float4 col;
    int groupId;
};

StructuredBuffer<pointData> pdBuffer : POINTCLOUDBUFFERIN;

float4x4 PointTransform : POINTTRANSFORM;

RWStructuredBuffer<pointData> pcBuffer : POINTCLOUDBUFFEROUT;
RWStructuredBuffer<uint> indexBuffer : INDEXBUFFER;

[numthreads(64,1,1)] 
void CS_Build(uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	pdBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }

	pointData pd = pdBuffer[i.x];
	uint index = pcBuffer.IncrementCounter();
	pcBuffer[index]  = pd;
	indexBuffer[index] = i.x;

}

technique11 BuildHash
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Build() ) );
	}
}
