struct LinkedListElement 
{
    uint id;
    uint next;
};

struct pointData
{
	float4 pos;
	float4 col;
	int groupId;
};

StructuredBuffer<pointData> PositionBuffer : POINTCLOUDBUFFER;

RWStructuredBuffer<LinkedListElement> RWLinkBuffer : RWLINKBUFFER;
RWStructuredBuffer<uint> RWOffsetBuffer : RWOFFSETBUFFER;

int GridCellSize : GRIDCELLSIZE;

[numthreads(64,1,1)] 
void CS_Build(uint3 i : SV_DispatchThreadID)
{
	uint cnt, stride;
	PositionBuffer.GetDimensions(cnt,stride);
	if (i.x >= cnt) { return; }

	float3 pos = PositionBuffer[i.x].pos.xyz;
	float4 tp = float4(pos,1);

	tp = tp * 0.5f + 0.5f;
	tp.y = 1.0f -tp.y;
	int3 cl = tp.xyz * GridCellSize;

	LinkedListElement element;
	element.id = i.x;

	uint counter = RWLinkBuffer.IncrementCounter();
    uint cellindex = cl.z * GridCellSize * GridCellSize + cl.y * GridCellSize + cl.x;
	
	uint oldoffset;
	InterlockedExchange(RWOffsetBuffer[cellindex],counter,oldoffset);

    element.next = oldoffset;
    RWLinkBuffer[counter] = element;

}

technique11 BuildHash
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Build() ) );
	}
}