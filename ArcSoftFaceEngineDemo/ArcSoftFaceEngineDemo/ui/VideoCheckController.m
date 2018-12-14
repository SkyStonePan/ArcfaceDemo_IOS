//
//  VideoCheckController.m
//  ArcSoftFaceEngineDemo
//
//  Created by noit on 2018/9/5.
//  Copyright © 2018年 ArcSoft. All rights reserved.
//

#import "VideoCheckController.h"
#import "ASFCameraController.h"
#import "GLKitView.h"
#import "Utility.h"
#import "ASFVideoProcessor.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

#define IMAGE_WIDTH     720
#define IMAGE_HEIGHT    1280

@interface VideoCheckController ()<ASFCameraControllerDelegate, ASFVideoProcessorDelegate>
{
    ASF_CAMERA_DATA*   _offscreenIn;
}
@property (nonatomic, strong) ASFCameraController* cameraController;
@property (nonatomic, strong) ASFVideoProcessor* videoProcessor;
@property (nonatomic, strong) NSMutableArray* arrayAllFaceRectView;
@property (weak, nonatomic) IBOutlet GLKitView *glView;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UIButton *buttonRegister;

@end

@implementation VideoCheckController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;
    
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
    
    self.videoProcessor = [[ASFVideoProcessor alloc] init];
    self.videoProcessor.delegate = self;
    [self.videoProcessor initProcessor];
    
    self.cameraController = [[ASFCameraController alloc]init];
    self.cameraController.delegate = self;
    [self.cameraController setupCaptureSession:videoOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.cameraController startCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraController stopCaptureSession];
}
- (IBAction)cancel:(id)sender {
    [self.cameraController stopCaptureSession];
    [self.videoProcessor uninitProcessor];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnRegisterFace:(UIButton *)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"注册人脸" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField* nameText = alertController.textFields.firstObject;
        NSString* name = nameText.text;
        if (name != NULL && name.length > 0) {
            if([self.videoProcessor registerDetectedPerson:name])
            {
                UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"注册成功" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:alertController animated:YES completion:nil];
                NSTimer *timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(timerHideAlertViewController:) userInfo:alertController repeats:NO];
                [timer fire];
            }
        }
    }];
    [alertController addAction:okAction];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入名称";
    }];
    
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)timerHideAlertViewController:(id)sender {
    NSTimer *timer = (NSTimer*)sender;
    UIAlertController *alertViewController = (UIAlertController*)timer.userInfo;
    [alertViewController dismissViewControllerAnimated:YES completion:nil];
    alertViewController = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    NSArray *arrayFaceInfo = [self.videoProcessor process:cameraData];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [self.glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
        
        if(self.arrayAllFaceRectView.count >= arrayFaceInfo.count)
        {
            for (NSUInteger face=arrayFaceInfo.count; face<self.arrayAllFaceRectView.count; face++) {
                UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
                faceRectView.hidden = YES;
            }
        }
        else
        {
            for (NSUInteger face=self.arrayAllFaceRectView.count; face<arrayFaceInfo.count; face++) {
                UIStoryboard *faceRectStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIView *faceRectView = [faceRectStoryboard instantiateViewControllerWithIdentifier:@"FaceRectVideoController"].view;
                [self.view addSubview:faceRectView];
                [self.arrayAllFaceRectView addObject:faceRectView];
            }
        }
        
        for (NSUInteger face = 0; face < arrayFaceInfo.count; face++) {
            UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
            ASFVideoFaceInfo *faceInfo = [arrayFaceInfo objectAtIndex:face];
            faceRectView.hidden = NO;
            faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
            UILabel* labelInfo = (UILabel*)[faceRectView viewWithTag:1];
            [labelInfo setTextColor:[UIColor yellowColor]];
            labelInfo.font = [UIFont boldSystemFontOfSize:15];
            MInt32 gender = faceInfo.gender;
            NSString *genderInfo = gender == 0 ? @"男" : (gender == 1 ? @"女" : @"不确定");
            labelInfo.text = [NSString stringWithFormat:@"age:%d gender:%@", faceInfo.age, genderInfo];
            UILabel* labelFaceAngle = (UILabel*)[faceRectView viewWithTag:6];
            labelFaceAngle.font = [UIFont boldSystemFontOfSize:15];
            [labelFaceAngle setTextColor:[UIColor yellowColor]];
            if(faceInfo.face3DAngle.status == 0) {
                labelFaceAngle.text = [NSString stringWithFormat:@"r=%.2f y=%.2f p=%.2f", faceInfo.face3DAngle.rollAngle, faceInfo.face3DAngle.yawAngle, faceInfo.face3DAngle.pitchAngle];
            } else {
                labelFaceAngle.text = @"Failed face 3D Angle";
            }
        }
    });
    [Utility freeCameraData:cameraData];
}

#pragma mark - AFVideoProcessorDelegate
- (void)processRecognized:(NSString *)personName
{
    NSString *result = [NSString stringWithFormat:@"%@%@", @"比对结果：", personName];
    self.labelName.text = result;
}

- (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect
{
    CGRect frameFaceRect = {0};
    CGRect frameGLView = self.glView.frame;
    frameFaceRect.size.width = CGRectGetWidth(frameGLView)*(faceRect.right-faceRect.left)/IMAGE_WIDTH;
    frameFaceRect.size.height = CGRectGetHeight(frameGLView)*(faceRect.bottom-faceRect.top)/IMAGE_HEIGHT;
    frameFaceRect.origin.x = CGRectGetWidth(frameGLView)*faceRect.left/IMAGE_WIDTH;
    frameFaceRect.origin.y = CGRectGetHeight(frameGLView)*faceRect.top/IMAGE_HEIGHT;
    
    return frameFaceRect;
}

@end
