
#import <UIKit/UIKit.h>

@class ImageChooseControl;

#define SettingCenterUrl @"prefs:root=com.ArtPollo.Artpollo"

@protocol ImageChooseControlDelegate <NSObject>

@optional
- (void)imageChooseControl:(ImageChooseControl *)control didChooseFinished:(UIImage *)image;

- (void)imageChooseControl:(ImageChooseControl *)control didClearImage:(UIImage *)image;

@end

@interface ImageChooseControl : UIView <UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,copy) NSString * pickerTitle;

@property (nonatomic,assign) UIViewController * superViewController;

@property (nonatomic,assign) id<ImageChooseControlDelegate> delegate;

@property (nonatomic,strong,readonly) UIImage * image;

@end
