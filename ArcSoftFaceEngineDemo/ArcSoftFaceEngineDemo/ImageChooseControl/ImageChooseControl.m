#import "ImageChooseControl.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>

@implementation ImageChooseControl
{
    UILabel  * _markLabel;
    UIButton * _imgBtn;
}

- (id)init{
    self = [super init];
    if (self) {
        [self initData];
        [self buildViews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        [self buildViews];
        [self setFrames];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    
    [self setFrames];
}

- (void)initData{
    _pickerTitle = @"选择";
    _image       = nil;
}

- (void)buildViews{
    
    self.backgroundColor = [UIColor lightGrayColor];
    
    // 标签
    _markLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    _markLabel.text            = @"点击添加图2";
    _markLabel.textColor       = [UIColor blackColor];
    _markLabel.textAlignment   = NSTextAlignmentCenter;
    _markLabel.font            = [UIFont systemFontOfSize:15.f];
    _markLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_markLabel];
    
    // 图片按钮
    _imgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_imgBtn setImage:nil forState:UIControlStateNormal];
    [_imgBtn addTarget:self action:@selector(clickImgBtnAddImage:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_imgBtn];
}

- (void)setFrames{
    _markLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [_imgBtn setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}

#pragma mark - ClickBtn Methods

- (void)clickImgBtnAddImage:(UIButton *)button{
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusRestricted || author ==ALAuthorizationStatusDenied){
        //无权限
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"未获得授权访问相册" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去设置", nil];
        [alertView show];
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate      = self;
    imagePicker.allowsEditing = YES;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.superViewController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)clickClearBtn{
    [_imgBtn setImage:nil forState:UIControlStateNormal];
    _image = nil;
    
    if ([self.delegate respondsToSelector:@selector(imageChooseControl:didClearImage:)]) {
        [self.delegate imageChooseControl:self didClearImage:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    UIImage *image =  [info objectForKey:UIImagePickerControllerEditedImage];
    _image = image;
    if ([self.delegate respondsToSelector:@selector(imageChooseControl:didChooseFinished:)]) {
        [self.delegate imageChooseControl:self didChooseFinished:image];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:SettingCenterUrl]];
    }
}

@end
