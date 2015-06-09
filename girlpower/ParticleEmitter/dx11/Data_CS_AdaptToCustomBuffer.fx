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
float movementThreshold = 0.001;
float speed = 0.0025;
int bufferslot;

[numthreads(64, 1, 1)]
void CS_Apply( uint3 i : SV_DispatchThreadID)
{
	uint pcBufferSize = InputCountBuffer.Load(0);
	if (i.x >=  asuint(elementcount)) { return;} // safeguard
		
	// update bufferslot (number of slots is set by BufferSizeMultiplicator in your patch)
	if(	i.x > (bufferslot * pcBufferSize) &&
		i.x < ((bufferslot + 1) * pcBufferSize)
	){
		
		pointData pd = pcBuffer[i.x % pcBufferSize]; // get element of your pointcloud
		// set pos, col and group
		float3 pos = pd.pos;
		float4 col = pd.col;
		int groupId = pd.groupId;

		// now set the movement-direction with the help of the optical flow texture
		float4 ppos = mul(float4(pd.pos,1), tVP);
		float2 uv = ppos.xy/ppos.w; // these are the uv coords where we sample
		uv.x = uv.x * 0.5 + 0.5;
		uv.y = uv.y * -0.5 + 0.5;
		float3 direction = -(texOptFlow.SampleLevel(sPoint,uv,0).rgb );

		float age = 0; // set age to 0
		
		// add the new element to our buffer (if the movement is above a certain threshold)
		if(	direction.x >= movementThreshold || direction.y >= movementThreshold ||
			direction.x <= movementThreshold * -1 || direction.y <= movementThreshold * -1){
			
			customPointData cpd = {pos,col,groupId,direction,age}; // create the new element	
			cpcBuffer[i.x] = cpd;
		}
		
	}
	// update all elements that are not it the current bufferslot
	else{
		customPointData cpd	= cpcBuffer[i.x]; // get current element
		// update age, pos and color
		cpd.age += aging;
		cpd.pos += cpd.direction * speed;
		cpd.pos += float3(0,speed,0);
		cpd.col *= 1- (cpd.age/1000);
		
		if (cpd.col.a <= 0.3f) cpd.pos = float3(0,0,0); // set particle position to 0 oif alpha is below 0.5 
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
