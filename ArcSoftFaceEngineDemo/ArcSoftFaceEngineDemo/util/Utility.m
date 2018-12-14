//
//  Utility.m
//

#import "Utility.h"

@implementation Utility

+ (ASF_CAMERA_INPUT_DATA) createOffscreen:(MInt32) width height:(MInt32) height format:(MUInt32) format
{
    ASF_CAMERA_DATA* pCameraData = MNull;
    do
    {
        pCameraData = (ASF_CAMERA_DATA*)malloc(sizeof(ASF_CAMERA_DATA));
        if(!pCameraData)
            break;
        memset(pCameraData, 0, sizeof(ASF_CAMERA_DATA));
        pCameraData->u32PixelArrayFormat = format;
        pCameraData->i32Width = width;
        pCameraData->i32Height = height;
        
        if (ASVL_PAF_NV12 == format) {
            pCameraData->pi32Pitch[0] = pCameraData->i32Width;        //Y
            pCameraData->pi32Pitch[1] = pCameraData->i32Width;        //UV
            pCameraData->ppu8Plane[0] = (MUInt8*)malloc(height * 3/2 * pCameraData->pi32Pitch[0]) ;    // Y
            pCameraData->ppu8Plane[1] = pCameraData->ppu8Plane[0] + pCameraData->i32Height * pCameraData->pi32Pitch[0]; // UV
            memset(pCameraData->ppu8Plane[0], 0, height * 3/2 * pCameraData->pi32Pitch[0]);
        } else if (ASVL_PAF_RGB24_B8G8R8 == format) {
            pCameraData->pi32Pitch[0] = pCameraData->i32Width * 3;
            pCameraData->ppu8Plane[0] = (MUInt8*)malloc(height * pCameraData->pi32Pitch[0]);
        }
    } while(false);
    
    return pCameraData;
}

#pragma mark - Private Methods
+ (ASF_CAMERA_INPUT_DATA)getCameraDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (NULL == sampleBuffer)
        return NULL;
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    ASF_CAMERA_DATA* _cameraData;
    if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType
             || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) // NV12
    {
        _cameraData = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
        ASF_CAMERA_DATA* pCameraData = _cameraData;
        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
        
        //Y Data
        if (rowBytePlane0 == pCameraData->pi32Pitch[0])
        {
            memcpy(pCameraData->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
        }
        else
        {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pCameraData->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
            }
        }
        //uv data
        if (rowBytePlane1 == pCameraData->pi32Pitch[1])
        {
            memcpy(pCameraData->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
        }
        else
        {
            uint8_t  *pPlanUV = pCameraData->ppu8Plane[1];
            for (int i = 0; i < bufferHeight / 2; ++i) {
                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    return _cameraData;
}

+ (void) freeCameraData:(ASF_CAMERA_INPUT_DATA) pOffscreen
{
    if (MNull != pOffscreen)
    {
        if (MNull != pOffscreen->ppu8Plane[0])
        {
            free(pOffscreen->ppu8Plane[0]);
            pOffscreen->ppu8Plane[0] = MNull;
        }
        free(pOffscreen);
        pOffscreen = MNull;
    }
}

+ (UIImage *)clipWithImageRect:(CGRect)clipRect clipImage:(UIImage *)clipImage
{
    UIGraphicsBeginImageContext(clipRect.size);
    [clipImage drawInRect:CGRectMake(0,0,clipRect.size.width,clipRect.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return  newImage;
}

@end
