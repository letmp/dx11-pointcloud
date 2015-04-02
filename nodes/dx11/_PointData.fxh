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
//		- dx11/Data_CS_BuildPcb_DynamicBuffer.fx &  modules/data/PointcloudBuffer (DX11.Pointcloud DynamicBuffer).v4p
// 		- dx11/Data_CS_BuildPcb_Kinect.fx & modules/data/PointcloudBuffer (DX11.Pointcloud Kinect).v4p
// * the network nodes UDP(DX11.Pointcloud Client) & UDP(DX11.Pointcloud Server) are transfering position
//	 and color by default. Have a look at these patches if you want to change that.