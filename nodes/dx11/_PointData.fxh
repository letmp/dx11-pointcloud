//stride: 36

struct pointData
{
    float4 pos;
    float4 col;
    int groupId;
};

// NOTES ABOUT EXTENDING G THE STRUCT
// * pos,col & groupId are mandatory
// * update the stride value in the first line of this file
// * change the initialization of the pointData elements in:
//		- dx11/Data_CS_BuildPcb_DynamicBuffer.fx
// 		- dx11/Data_CS_BuildPcb_Kinect.fx