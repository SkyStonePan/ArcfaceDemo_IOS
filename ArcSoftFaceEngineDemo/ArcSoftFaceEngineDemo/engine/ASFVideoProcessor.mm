//
//  AFVideoProcessor.mm
//

#import "ASFVideoProcessor.h"
#import "Utility.h"
#import "ASFRManager.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import <ArcSoftFaceEngine/merror.h>

#define DETECT_MODE          ASF_DETECT_MODE_VIDEO
#define ASF_FACE_NUM         6
#define ASF_FACE_SCALE       16
#define ASF_FACE_COMBINEDMASK ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE

@implementation ASFFace3DAngle
@end

@implementation ASFVideoFaceInfo
@end

@interface ASFVideoProcessor()
{
    ASF_CAMERA_DATA*   _cameraDataForProcessFR;
    dispatch_semaphore_t _processSemaphore;
    dispatch_semaphore_t _processFRSemaphore;
}
@property (nonatomic, assign) BOOL              frModelVersionChecked;
@property (nonatomic, strong) ASFRManager*       frManager;
@property (atomic, strong) ASFRPerson*           frPerson;

@property (nonatomic, strong) ArcSoftFaceEngine*      arcsoftFace;
@end

@implementation ASFVideoProcessor

- (instancetype)init {
    self = [super init];
    if(self) {
        _processSemaphore = NULL;
        _processFRSemaphore = NULL;
    }
    return self;
}

- (void)initProcessor
{
    self.arcsoftFace = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [self.arcsoftFace initFaceEngineWithDetectMode:DETECT_MODE
                                            orientPriority:ASF_OP_0_ONLY
                                                     scale:ASF_FACE_SCALE
                                                maxFaceNum:ASF_FACE_NUM
                                              combinedMask:ASF_FACE_COMBINEDMASK];
    if (mr == ASF_MOK) {
        NSLog(@"初始化成功");
    } else {
        NSLog(@"初始化失败：%ld", mr);
    }
    
    _processSemaphore = dispatch_semaphore_create(1);
    _processFRSemaphore = dispatch_semaphore_create(1);
    
    self.frManager = [[ASFRManager alloc] init];
}

- (void)uninitProcessor
{
    if(_processSemaphore && 0 == dispatch_semaphore_wait(_processSemaphore, DISPATCH_TIME_FOREVER))
    {
        dispatch_semaphore_signal(_processSemaphore);
        _processSemaphore = NULL;
    }
    
    if(_processFRSemaphore && 0 == dispatch_semaphore_wait(_processFRSemaphore, DISPATCH_TIME_FOREVER))
    {
        [Utility freeCameraData:_cameraDataForProcessFR];
        _cameraDataForProcessFR = MNull;
        
        dispatch_semaphore_signal(_processFRSemaphore);
        _processFRSemaphore = NULL;
    }
    
    [self.arcsoftFace unInitFaceEngine];
    self.arcsoftFace = nil;
}

- (void)setDetectFaceUseFD:(BOOL)detectFaceUseFD
{
    if(_detectFaceUseFD == detectFaceUseFD)
        return;
    _detectFaceUseFD = detectFaceUseFD;
    
    [self uninitProcessor];
    [self initProcessor];
}

- (BOOL)isDetectFaceUseFD
{
    return _detectFaceUseFD;
}

- (NSArray*)process:(ASF_CAMERA_DATA*)cameraData
{
    NSMutableArray *arrayFaceInfo = nil;
    if(0 == dispatch_semaphore_wait(_processSemaphore, 0))
    {
        __block BOOL detectFace = NO;
        __block ASF_SingleFaceInfo singleFaceInfo = {0};
        __weak ASFVideoProcessor* weakSelf = self;
        
        do {
            ASF_MultiFaceInfo multiFaceInfo = {0};
            MRESULT mr = [self.arcsoftFace detectFacesWithWidth:cameraData->i32Width
                                                         height:cameraData->i32Height
                                                           data:cameraData->ppu8Plane[0]
                                                         format:cameraData->u32PixelArrayFormat
                                                        faceRes:&multiFaceInfo];
            if(ASF_MOK != mr || multiFaceInfo.faceNum == 0) {
                NSLog(@"FD结果：%ld", mr);
                break;
            }
            
            arrayFaceInfo = [NSMutableArray arrayWithCapacity:0];
            for (int face=0; face<multiFaceInfo.faceNum; face++) {
                ASFVideoFaceInfo *faceInfo = [[ASFVideoFaceInfo alloc] init];
                faceInfo.faceRect = multiFaceInfo.faceRect[face];
                [arrayFaceInfo addObject:faceInfo];
            }
            
            detectFace = YES;
            singleFaceInfo.rcFace = multiFaceInfo.faceRect[0];
            singleFaceInfo.orient = multiFaceInfo.faceOrient[0];
            
            NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
            mr = [self.arcsoftFace processWithWidth:cameraData->i32Width
                                             height:cameraData->i32Height
                                               data:cameraData->ppu8Plane[0]
                                             format:cameraData->u32PixelArrayFormat
                                            faceRes:&multiFaceInfo
                                               mask:ASF_FACE3DANGLE | ASF_AGE | ASF_GENDER];
            NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
            NSLog(@"processTime=%dms", (int)(cost * 1000));
            if(ASF_MOK != mr) {
                NSLog(@"process失败：%ld", mr);
                break;
            }
            
            ASF_Face3DAngle face3DAngle = {0};
            if(ASF_MOK != [self.arcsoftFace getFace3DAngle:&face3DAngle] || face3DAngle.num != multiFaceInfo.faceNum)
                break;
            
            ASF_AgeInfo ageInfo = {0};
            if(ASF_MOK != [self.arcsoftFace getAge:&ageInfo] || ageInfo.num != multiFaceInfo.faceNum)
                break;
            
            ASF_GenderInfo genderInfo = {0};
            if(ASF_MOK != [self.arcsoftFace getGender:&genderInfo] || genderInfo.num != multiFaceInfo.faceNum)
                break;
            
            for (int face=0; face<multiFaceInfo.faceNum; face++) {
                ASFFace3DAngle *face3DAngleInfo = [[ASFFace3DAngle alloc] init];
                face3DAngleInfo.yawAngle = face3DAngle.yaw[face];
                face3DAngleInfo.pitchAngle = face3DAngle.pitch[face];
                face3DAngleInfo.rollAngle = face3DAngle.roll[face];
                face3DAngleInfo.status = face3DAngle.status[face];
                
                ASFVideoFaceInfo *faceInfo = arrayFaceInfo[face];
                faceInfo.face3DAngle = face3DAngleInfo;
                faceInfo.age = ageInfo.ageArray[face];
                faceInfo.gender = genderInfo.genderArray[face];
            }
        } while (NO);
        
        dispatch_semaphore_signal(_processSemaphore);

        if(0 == dispatch_semaphore_wait(_processFRSemaphore, 0))
        {
            __block ASF_CAMERA_INPUT_DATA offscreenProcess = [self copyCameraDataForProcessFR:cameraData];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                
                if(!weakSelf.frModelVersionChecked)
                {
                    weakSelf.frModelVersionChecked = YES;
                }
                
                if(detectFace)
                {
                    ASF_FaceFeature faceFeature = {0};
                    NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
                    MRESULT mr = [self.arcsoftFace extractFaceFeatureWithWidth:offscreenProcess->i32Width
                                                                        height:offscreenProcess->i32Height
                                                                          data:offscreenProcess->ppu8Plane[0]
                                                                        format:offscreenProcess->u32PixelArrayFormat
                                                                      faceInfo:&singleFaceInfo
                                                                       feature:&faceFeature];
                    NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
                    NSLog(@"FRTime=%dms", (int)(cost * 1000));
                    if(mr == ASF_MOK)
                    {
                        ASFRPerson* currentPerson = [[ASFRPerson alloc] init];
                        currentPerson.faceFeatureData =
                        [NSData dataWithBytes:faceFeature.feature
                                       length:faceFeature.featureSize];
                        NSArray* persons = self.frManager.allPersons;
                        NSString* recognizedName = nil;
                        float maxScore = 0.0;
                        for (ASFRPerson* person in persons)
                        {
                            ASF_FaceFeature refFaceFeature = {0};
                            refFaceFeature.feature = (MByte*)[person.faceFeatureData bytes];
                            refFaceFeature.featureSize = (MInt32)[person.faceFeatureData length];
                            
                            MFloat fConfidenceLevel =  0.0;
                            MRESULT mr = [self.arcsoftFace compareFaceWithFeature:&faceFeature
                                                                         feature2:&refFaceFeature
                                                                        confidenceLevel:&fConfidenceLevel];
                            NSLog(@"compareFeature:similar=%.2f", fConfidenceLevel);
                            if (mr == ASF_MOK && fConfidenceLevel >= maxScore) {
                                maxScore = fConfidenceLevel;
                                recognizedName = person.name;
                            }
                        }
                        
                        MFloat scoreThreshold = 0.81;
                        if (maxScore > scoreThreshold) {
                            currentPerson.name = recognizedName;
                        }
                        
                        self.frPerson = currentPerson;
                    }
                    else
                    {
                        self.frPerson = nil;
                    }
                }
                else
                {
                    self.frPerson = nil;
                }
                dispatch_semaphore_signal(_processFRSemaphore);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:)])
                        [self.delegate processRecognized:self.frPerson.name];
                });
            });
        }
    }

    return arrayFaceInfo;
}

- (BOOL)registerDetectedPerson:(NSString *)personName
{
    ASFRPerson *registerPerson = self.frPerson;
    if(registerPerson == nil || registerPerson.registered)
        return NO;
    
    registerPerson.name = personName;
    registerPerson.Id = [self.frManager getNewPersonID];
    registerPerson.registered = [self.frManager addPerson:registerPerson];

    return registerPerson.registered;
}

- (ASF_CAMERA_INPUT_DATA)copyCameraDataForProcessFR:(ASF_CAMERA_INPUT_DATA)pOffscreenIn
{
    if (pOffscreenIn == MNull) {
        return  MNull;
    }
    
    if (_cameraDataForProcessFR != NULL)
    {
        if (_cameraDataForProcessFR->i32Width != pOffscreenIn->i32Width ||
            _cameraDataForProcessFR->i32Height != pOffscreenIn->i32Height ||
            _cameraDataForProcessFR->u32PixelArrayFormat != pOffscreenIn->u32PixelArrayFormat) {
            [Utility freeCameraData:_cameraDataForProcessFR];
            _cameraDataForProcessFR = NULL;
        }
    }
    
    if (_cameraDataForProcessFR == NULL) {
        _cameraDataForProcessFR = [Utility createOffscreen:pOffscreenIn->i32Width
                                                   height:pOffscreenIn->i32Height
                                                   format:pOffscreenIn->u32PixelArrayFormat];
    }
    
    if (ASVL_PAF_NV12 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_cameraDataForProcessFR->ppu8Plane[0],
               pOffscreenIn->ppu8Plane[0],
               pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
        memcpy(_cameraDataForProcessFR->ppu8Plane[1],
               pOffscreenIn->ppu8Plane[1],
               pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[1] / 2);
    }
    
    return _cameraDataForProcessFR;
}
@end
