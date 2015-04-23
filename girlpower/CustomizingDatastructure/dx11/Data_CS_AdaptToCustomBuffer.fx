// Original Pointcloud Data
#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

// Our Custom Buffer
#include "_CustomPointData.fxh"
RWStructuredBuffer<customPointData> cpcBuffer : BACKBUFFER;

int elementcount;

StructuredBuffer<float3> rndDir;
int rndDirCnt;
float aging = 1;
bool reset;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint pcBufferSize = InputCountBuffer.Load(0);
	if (i.x >=  asuint(elementcount)) { return;}
	
	// RESET BUFFER
	if(reset){
		
		// init with standard values
		float3 pos = float3(0,0,0);
		float4 col = float4(0,0,0,0);
		int groupId = 0;
		
		float3 direction = rndDir[i.x % rndDirCnt];
		float age = 0;
		// the original buffer can be smaller than our custom buffer
		// -> adopt original values as long as there are some in our original buffer
		if (i.x <= pcBufferSize){
			pointData pd = pcBuffer[i.x];
			pos = pd.pos;
			col = pd.col;
			groupId = pd.groupId;
		}
		
		customPointData cpd = {pos,col,groupId,direction,age};
		cpcBuffer[i.x] = cpd;
	}
	
	// UPDATE BUFFER
	else{
		customPointData cpd	= cpcBuffer[i.x];
		
		cpd.age += aging;
		cpd.pos += cpd.direction - float3(0, cpd.age/500, 0);
		cpd.col *= 1- (cpd.age/1000);
		
		cpcBuffer[i.x] = cpd;
	}
}

technique11 ToCustomBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Apply() ) );
	}
}
