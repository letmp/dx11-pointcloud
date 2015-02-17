float4x4 PointTransform : WORLD;
struct pointData
{
	float4 pos;
	float4 col;
	int groupId;
};
StructuredBuffer<pointData> pcBuffer;

struct LinkedListElement 
{
    uint id;
    uint next;
};
StructuredBuffer<LinkedListElement> LinkBuffer;
StructuredBuffer<uint> OffsetBuffer;

RWStructuredBuffer<int> groupBuffer : BACKBUFFER;
//AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;
ByteAddressBuffer InputCountBuffer;
int GridCellSize;
float radius;

groupshared uint groupId = -1;

uint getCell(float3 pos){
	float4 tp = mul(float4(pos,1), PointTransform);
	tp = tp * 0.5f + 0.5f;
	tp.y = 1.0f -tp.y;
	int3 cl = tp.xyz * GridCellSize;
	return cl.z * GridCellSize * GridCellSize + cl.y * GridCellSize + cl.x;
}

[numthreads(1, 1, 1)]
void CS_CalculateBounds( uint3 i : SV_DispatchThreadID)
{ 
	
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  1 ) { return;}
	
	// reset all groupIds
	for (int j = 0; j < asint(cnt); j++){
		groupBuffer[j] = -1;
	}
	
	// iterate through all elements
	for (int k = 0; k < asint(cnt); k++){
		// have a look at all elements with groupId == -1
		if(groupBuffer[k] == -1){
			groupId++; // increment groupId 
			groupBuffer[k] = groupId; // set the new groupId for the current element
			
			// now find all neighbours of this element and set the same groupId
			float3 actPos = pcBuffer[k].pos.xyz;
			float3 firstPos = actPos;
			bool looknextcell = true;
			//[allow_uav_condition]
			//while (looknextcell){
				
				uint cellId = getCell(actPos);
			
				if(cellId < (GridCellSize*GridCellSize*GridCellSize) && OffsetBuffer[cellId] != 0xFFFFFFFF){
					uint nextEle = OffsetBuffer[cellId];				
					bool hasNext = true;				
					[allow_uav_condition]
					while (hasNext){
						if (groupBuffer[LinkBuffer[nextEle].id] == -1 )groupBuffer[LinkBuffer[nextEle].id] = groupId;
						if (LinkBuffer[nextEle].next != 0xFFFFFFFF && LinkBuffer[nextEle].next != LinkBuffer[nextEle].id) hasNext = true;
						else hasNext = false;
						nextEle = LinkBuffer[nextEle].next;					
					}				
				}
				//else looknextcell = false;
				
				//actPos = actPos + float3(radius,0,0);
				
			//}
			
			
			
		}
	}
	
}

technique11 SetGroupId
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_CalculateBounds() ) );
	}
}