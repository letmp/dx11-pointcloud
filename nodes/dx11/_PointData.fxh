//stride: 32

struct pointData
{
    float3 pos;
    float4 col;
    int groupId;
};

// NOTES ABOUT EXTENDING THE POINT STRUCTURE
// ==========================================================
// * pos,col & groupId are mandatory
// * update the stride value in the first line of this file
// * change the initialization of the pointData elements in:
//		- dx11/Data_CS_BuildPcb_DynamicBuffer.fx
// 		- dx11/Data_CS_BuildPcb_Kinect.fx
// 		- dx11/Data_CS_BuildPcb_Layer.fx