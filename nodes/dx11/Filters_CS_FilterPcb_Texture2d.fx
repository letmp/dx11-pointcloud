float4x4 tVP: VIEWPROJECTION;
int groupIds;

#include "_PointData.fxh"
StructuredBuffer<pointData> pcBuffer;
ByteAddressBuffer InputCountBuffer;

AppendStructuredBuffer<pointData> newPcBuffer : BACKBUFFER;

Texture2D texFilter <string uiname="Texture Filter";>;
SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

[numthreads(64, 1, 1)]
void CS_Restrict( uint3 i : SV_DispatchThreadID)
{ 
	uint cnt = InputCountBuffer.Load(0);
	if (i.x >=  cnt ) { return;}
	
	if(	pcBuffer[i.x].groupId == groupIds || groupIds == -1){
		pointData pd = pcBuffer[i.x];
		float3 pos = pd.pos;

		float4 ppos = mul(float4(pd.pos,1), tVP);
		float2 uv = ppos.xy/ppos.w; // these are the uv coords where we sample
		uv.x = uv.x * 0.5 + 0.5;
		uv.y = uv.y * -0.5 + 0.5;
		float4 col = texFilter.SampleLevel(sPoint,uv,0);
		
		if (col.r > 0.0f || col.g > 0.0f || col.b > 0.0f) newPcBuffer.Append(pd);
	}
}

technique11 Filter
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Restrict() ) );
	}
}
