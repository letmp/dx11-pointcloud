// Original Pointcloud Data
#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

// Our Extension Buffer
#include "_pointDataExtension.fxh"
RWStructuredBuffer<pointDataExtension> rwForceBuffer : BACKBUFFER;

int elementcount;

float aging = 0.1;
float speed = 0.04;

bool update;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint pcBufferSize = InputCountBuffer.Load(0);
	if (i.x >=  asuint(elementcount)) { return;} // safeguard
		
	// on update:
	// load data from the current pointcloudbuffer and
	// use the position of each point as force
	// ================================================
	if(	 update ){
		pointData pd = pcBuffer[i.x % pcBufferSize];
		float3 force = pd.pos * speed;
		float age = 0;
		pointDataExtension pde = {force,age}; // create the new element	
		rwForceBuffer[i.x] = pde; // and write it to the forceBuffer
	}
	
	
	// update the current ForceBuffer
	// =================================================
	pointDataExtension pde	= rwForceBuffer[i.x]; // get current element
	pde.age += aging;
	pde.force -= float3(0, 0.01f, 0) * speed;
	rwForceBuffer[i.x] = pde;

}

technique11 ToCustomBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
