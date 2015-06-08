// Original Pointcloud Data
#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

// Our Extension Buffer
#include "_pointDataExtension.fxh"
StructuredBuffer<pointDataExtension> rwForceBuffer;

RWStructuredBuffer<pointData> pdBuffer : BACKBUFFER;


int elementcount;
bool update;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint pcBufferSize = InputCountBuffer.Load(0);
	if (i.x >=  asuint(elementcount)) { return;} // safeguard
		
	// updates the RWBuffer with current pointcloud data
	// =================================================
	if(	update	){		
		pointData pd = pcBuffer[i.x % pcBufferSize];
		pdBuffer[i.x] = pd;
	}
	
	// update the RWBuffer with data from the RWForceBuffer
	// =================================================
	pointData pd	= pdBuffer[i.x]; // get current element
	pointDataExtension pde	= rwForceBuffer[i.x]; // get current element
	
	pd.pos += pde.force;
	pd.col *= 1- (pde.age/1000);
	
	pdBuffer[i.x] = pd;
	
}

technique11 ToCustomBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
