// Original Pointcloud Data
#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

// Our Custom Buffer
#include "_CustomPointData.fxh"
RWStructuredBuffer<customPointData> cpcBuffer : BACKBUFFER;

int elementcount;

float4x4 tVP: VIEWPROJECTION;
Texture2D texOptFlow <string uiname="Texture OpticalFlow";>;
SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

float aging = 0.1;
bool reset;
float movementThreshold = 0.001;

int bufferslot;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint pcBufferSize = InputCountBuffer.Load(0);
	if (i.x >=  asuint(elementcount)) { return;}
		
	// RESET BUFFER
	if(	reset && 
		i.x > (bufferslot * pcBufferSize) &&
		i.x < ((bufferslot + 1) * pcBufferSize)
	){
		
		pointData pd = pcBuffer[i.x % pcBufferSize];
		float3 pos = pd.pos;
		float4 col = pd.col;
		int groupId = pd.groupId;

		float4 ppos = mul(float4(pd.pos,1), tVP);
		float2 uv = ppos.xy/ppos.w;
		uv.x = uv.x * 0.5 + 0.5;
		uv.y = uv.y * -0.5 + 0.5;
		
		float3 direction = -(texOptFlow.SampleLevel(sPoint,uv,0).rgb )/ 400.0f;
		//float3 direction = float3 (0,0,0);
		
		
		
		//float3 direction = rndDir[i.x % rndDirCnt];
		float age = 0;
		
		customPointData cpd = {pos,col,groupId,direction,age};
		
		
		if(	direction.x >= movementThreshold || direction.y >= movementThreshold ||
			direction.x <= movementThreshold * -1 || direction.y <= movementThreshold * -1){
			cpcBuffer[i.x] = cpd;
		}
		
	}
	
	// UPDATE BUFFER
	else{
		customPointData cpd	= cpcBuffer[i.x];
		
		cpd.age += aging;
		//cpd.pos += cpd.direction - float3(0, cpd.age/2000, 0);
		cpd.pos += cpd.direction;
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
