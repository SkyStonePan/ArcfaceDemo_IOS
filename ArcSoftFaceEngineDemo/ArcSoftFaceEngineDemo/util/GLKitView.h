//
//  GLKitView.h
//  OpenGLView
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface GLKitView : GLKView

-(void) renderWithRGBA32Data:(unsigned int) nWidth height:(unsigned int) nHeight imageData:(GLbyte*) imageData format:(CIFormat) format;
-(void) renderWithTexture:(unsigned int) nTextureID width:(unsigned int) nWidth height:(unsigned int) nHeight;
-(void) renderWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer orientation:(int)nOrientation mirror:(BOOL) bMirror;

@end
