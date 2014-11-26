struct pointData
{
	float4 pos;
	float4 col;
	int groupId;
};
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

RWStructuredBuffer<uint> countGroupIdBuffer : BACKBUFFER;
int slice;
bool countmode;

[numthreads(1,1,1)]
void CS_Clear(uint3 i : SV_DispatchThreadID)
{
	countGroupIdBuffer[slice] = 0;
}

[numthreads(64, 1, 1)]
void CS_HitTest( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	if ( !countmode && countGroupIdBuffer[slice] == 1) {return;}
	
	if (pcBuffer[i.x].groupId == slice){
		
		if(countmode){
				uint oldval;
				InterlockedAdd(countGroupIdBuffer[slice],1,oldval);
		}
		else countGroupIdBuffer[slice] = 1;
	}
	
}

technique11 Clear
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Clear() ) );
	}
}

technique11 HitTest
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_HitTest() ) );
	}
}