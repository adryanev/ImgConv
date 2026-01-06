#import <Cocoa/Cocoa.h>
#import "ITBVectorDocument.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const ITBImageTracerErrorDomain;

typedef NS_ERROR_ENUM(ITBImageTracerErrorDomain, ITBImageTracerError) {
    ITBImageTracerErrorInvalidImage = 3001,
    ITBImageTracerErrorQuantizationFailed = 3002,
    ITBImageTracerErrorTracingFailed = 3003,
};

/// Traces raster images to vector paths using multi-color quantization
@interface ITBImageTracer : NSObject

/// Number of colors to quantize to (2-16, default 8)
@property (nonatomic, assign) NSInteger colorCount;

/// Path simplification tolerance in pixels (0.5-5.0, default 1.0)
@property (nonatomic, assign) CGFloat tolerance;

/// Minimum area threshold for paths (default 4.0 pixels^2)
@property (nonatomic, assign) CGFloat minArea;

/// Trace an image to a vector document
- (nullable ITBVectorDocument *)traceImage:(NSImage *)image error:(NSError **)error;

/// Trace an image at specified output size
- (nullable ITBVectorDocument *)traceImage:(NSImage *)image
                                outputSize:(CGSize)outputSize
                                     error:(NSError **)error;

/// Get quantized colors from image (for preview)
- (nullable NSArray<NSColor *> *)quantizeColors:(NSImage *)image
                                     colorCount:(NSInteger)count
                                          error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
