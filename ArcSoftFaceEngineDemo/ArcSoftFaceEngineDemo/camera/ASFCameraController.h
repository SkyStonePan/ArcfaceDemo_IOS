#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol ASFCameraControllerDelegate <NSObject>
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
@end


@interface ASFCameraController : NSObject

@property (nonatomic, weak)     id <ASFCameraControllerDelegate>    delegate;

- (BOOL) setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation;
- (void) startCaptureSession;
- (void) stopCaptureSession;

@end




