#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

RWStructuredBuffer<uint> countGroupIdBuffer : BACKBUFFER;
int drawIndex : DRAWINDEX;
int groupId;
bool countmode;

[numthreads(1,1,1)]
void CS_Clear(uint3 i : SV_DispatchThreadID)
{
	countGroupIdBuffer[drawIndex] = 0;
}

[numthreads(64, 1, 1)]
void CS_HitTest( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	if ( !countmode && countGroupIdBuffer[drawIndex] > 0) {return;}
	
	if (pcBuffer[i.x].groupId == groupId){
		
		if(countmode){
				uint oldval;
				InterlockedAdd(countGroupIdBuffer[drawIndex],1,oldval);
		}
		else countGroupIdBuffer[drawIndex] = 1;
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