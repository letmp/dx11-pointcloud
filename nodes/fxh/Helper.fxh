int encodeColor(float4 fCol)
{
    int iRed   = (int)(clamp(fCol.r,0,1) * 255);
    int iGreen = (int)(clamp(fCol.g,0,1) * 255) << 8;
    int iBlue  = (int)(clamp(fCol.b,0,1) * 255) << 16;
    int iAlpha = (int)(clamp(fCol.a,0,1) * 255) << 24;
    return iRed + iGreen + iBlue + iAlpha;
}

float4 decodeColor(int iCol)
{
    float4 fCol;
    fCol.x = (float)(( iCol & 0x000000ff)      ) / 255.0f; 
    fCol.y = (float)(( iCol & 0x0000ff00) >> 8 ) / 255.0f;
    fCol.z = (float)(( iCol & 0x00ff0000) >> 16) / 255.0f;
    fCol.w = (float)(( iCol & 0xff000000) >> 24) / 255.0f;
    return fCol;
}

float4 randColor(in float id) {
    float noiseX = (frac(sin(dot(float2(id,id), float2(12.9898,78.233)   )) * 43758.5453));
    float noiseY = (frac(sin(dot(float2(id,id), float2(12.9898,78.233) * 2.0)) * 43758.5453));
    float noiseZ = sqrt(1 - noiseX * noiseX);
    return float4(noiseX, noiseY,noiseZ,1);
}

float4x4 calcRotation (float3 vel){
    static const float PI = 3.14159265f;
    
    float length = sqrt(vel.x * vel.x + vel.y * vel.y  + vel.z * vel.z); //length
    float nVelX = vel.x;
    float nVelY = vel.y;
    float nVelZ = vel.z;
    
    if (length != 0)
    {
        nVelX = vel.x / length;
        nVelY = vel.y / length;
        nVelZ = vel.z / length;
    }
    
    //converter
    float conv = (2 * PI);
    float3 rotationV;
    
    //CONVERT FROM POLAR TO CARTESIAN VVVV-STYLE
    float lengthPol = nVelX * nVelX + nVelY * nVelY + nVelZ * nVelZ;
    
    if (lengthPol > 0)
    {
        lengthPol = sqrt(lengthPol);
        float pitch = asin(nVelY / lengthPol);
        float yaw = 0.0;
        if(nVelZ != 0)
        yaw = atan2(-nVelX, -nVelZ);
        else if (nVelX > 0)
        yaw = -PI / 2;
        else
        yaw = PI / 2;
        
        rotationV = float3(pitch, yaw, lengthPol) / conv ;
    }
    
    else
    
    {
        rotationV = float3(0,0,0);
    }
    
    rotationV*= 2*PI;
    
    float sx = sin(rotationV.x);
    float cx = cos(rotationV.x);
    float sy = sin(rotationV.y);
    float cy = cos(rotationV.y);
    float sz = sin(rotationV.z);
    float cz = cos(rotationV.z);
    
    return float4x4(     cz*cy+sz*sx*sy, sz*cx, cz*-sy+sz*sx*cy, 0,
    -sz*cy+cz*sx*sy, cz*cx, sz*sy+cz*sx*cy , 0,
    cx * sy       ,-sx   , cx * cy        , 0,
    0             , 0    , 0              , 1);
}