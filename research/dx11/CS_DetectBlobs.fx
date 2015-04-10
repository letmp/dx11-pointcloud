AppendStructuredBuffer<float4> buffer : BACKBUFFER;
Texture2D tex <string uiname="Texture";>;
StructuredBuffer<float2> uv <string uiname="UV Buffer";>;

float2 imageSize <string uiname="Image Size";>;
int2 steps <string uiname="Lookup Radius";>;
int minNeighbours <string uiname="Min Neighbour Count";>;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

[numthreads(64, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 

	float2 offset = float2(1 / imageSize.x, 1 / imageSize.y);
	float4 coords = tex.SampleLevel(sPoint,uv[i.x],0);
	
	bool isMax = false;
	int count = 0;
	
	if( coords.w != 0.0f ){ // discard all pixels that have alpha value = 0
		isMax = true;
		for (int stepX = -steps.x; stepX <= steps.x; stepX++){
			for (int stepY = -steps.y; stepY <= steps.y; stepY++){
				if (!(stepY == 0 && stepX == 0)) { 
					float4 testSample = tex.SampleLevel(sPoint,uv[i.x] + float2((stepX * offset.x) , (stepY * offset.y)),0);
					if ( testSample.w > 0.0f){
						if (coords.y < testSample.y ){
							isMax = false;
						}
						else if ( coords.y == testSample.y && (coords.x < testSample.x || coords.z < testSample.z) ){
							isMax = false;
						}
						else {
							count++;
						}	
					}
				}
				if(!isMax) break;				
			}
			if(!isMax) break;
		}		
	}
	if(isMax && count > minNeighbours){
		buffer.Append(float4(coords.xyz, count));
	}
}

technique11 DetectBlobs
{
	pass P0{ SetComputeShader( CompileShader( cs_5_0, CS() ) );}
}