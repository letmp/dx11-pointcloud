float4x4 tW : WORLD;

int drawIndex : DRAWINDEX;
int IdOffset;
int elementcount;

bool useEncodedPosition = false;
StructuredBuffer<float3> posBuffer <string uiname="Position Buffer";>;
StructuredBuffer<float> posBufferEncoded <string uiname="Encoded Position Buffer";>;
float2 Resolution;
float2 FOV;

bool useEncodedColor = false;
StructuredBuffer<float4> colBuffer <string uiname="Color Buffer";>;
StructuredBuffer<int> colBufferEncoded <string uiname="Encoded Color Buffer";>;

bool useGroupIdBuffer = false;
StructuredBuffer<int> groupIdBuffer <string uiname="GroupId Buffer";>;

#include "../fxh/_PointData.fxh"
AppendStructuredBuffer<pointData> pcBuffer : BACKBUFFER;

#include "../fxh/Helper.fxh"

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSBuildPointcloudBuffer( uint3 DTid : SV_DispatchThreadID )
{
	
	if(DTid.x >= (uint) elementcount){return;}
	
	// ======= SET POSITION =======
	float4 pos;
	if (useEncodedPosition){
		int2 iPos = int2(DTid.x % Resolution.x, DTid.x / Resolution.x);
		float2 coord = iPos / Resolution;
		float depth = posBufferEncoded[DTid.x];
		float XtoZ = tan(FOV.x/2) * 2;
	    float YtoZ = tan(FOV.y/2) * 2;
		pos.x = ((coord.x - 0.5) * depth * XtoZ * -1);
		pos.y = ((0.5 - coord.y) * depth * YtoZ);		
		pos.z = depth;
		
		// set pos.w to 0 if there was no depth value
		// this is used to skip appending this element
		if (depth == 0.0f) pos.w = 0;
		else pos.w = 1;
	}
	else{
		pos = float4(posBuffer[DTid.x],1);
	}
	pos = mul(pos, tW);
	
	uint cnt, stride;
	
	// ======= SET COLOR =======
	int col;
	if(useEncodedColor){
		colBufferEncoded.GetDimensions(cnt,stride);
		col = colBufferEncoded[DTid.x % cnt];
	} 
	else{
		colBuffer.GetDimensions(cnt,stride);
		col = encodeColor( colBuffer[DTid.x % cnt] );
	}
	
	// ======= SET GROUP ID =======
	int groupId;
	if (useGroupIdBuffer){
		groupIdBuffer.GetDimensions(cnt,stride);
		groupId = groupIdBuffer[DTid.x % cnt];	
	}
	else {
		groupId = drawIndex + IdOffset;
	}
	
	// ======= APPEND POINT =======
	if(pos.w != 0.0f){
		pointData pd = {pos.xyz, col,groupId };
		pcBuffer.Append(pd);
	}
	
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 BuildPointcloudBuffer
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSBuildPointcloudBuffer() ) );
	}
}
