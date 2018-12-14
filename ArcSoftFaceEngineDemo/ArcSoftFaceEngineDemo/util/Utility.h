//
//  Utility.h
//  ArcFace
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreGraphics/CGBase.h>
#import <UIKit/UIKit.h>
#import <ArcSoftFaceEngine/amcomdef.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

typedef struct __tag_ASF_CAMERADATA
{
    MUInt32   u32PixelArrayFormat;
    MInt32    i32Width;
    MInt32    i32Height;
    MUInt8*   ppu8Plane[4];
    MInt32    pi32Pitch[4];
}ASF_CAMERA_DATA, *ASF_CAMERA_INPUT_DATA;
typedef ASF_CAMERA_INPUT_DATA LPAF_ImageData;

@interface Utility : NSObject

+ (ASF_CAMERA_INPUT_DATA)createOffscreen:(MInt32)width height:(MInt32)height format:(MUInt32)format;
+ (ASF_CAMERA_INPUT_DATA)getCameraDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (void)freeCameraData:(ASF_CAMERA_INPUT_DATA)pOffscreen;
+ (UIImage *)clipWithImageRect:(CGRect)clipRect clipImage:(UIImage *)clipImage;
@end
