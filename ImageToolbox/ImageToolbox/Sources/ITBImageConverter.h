#import <Cocoa/Cocoa.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

NS_ASSUME_NONNULL_BEGIN

/// Error domain for ITBImageConverter errors
extern NSErrorDomain const ITBImageConverterErrorDomain;

/// Error codes for ITBImageConverter
typedef NS_ERROR_ENUM(ITBImageConverterErrorDomain, ITBImageConverterErrorCode) {
    /// The input format is not supported
    ITBImageConverterErrorUnsupportedFormat = 1001,
    /// Failed to encode the image
    ITBImageConverterErrorEncodingFailed = 1002,
    /// Failed to decode the image
    ITBImageConverterErrorDecodingFailed = 1003,
    /// Invalid input provided (nil image, etc.)
    ITBImageConverterErrorInvalidInput = 1004,
};

/// Supported image formats for conversion
typedef NS_ENUM(NSInteger, ITBImageFormat) {
    ITBImageFormatPNG,
    ITBImageFormatJPEG,
    ITBImageFormatWebP,
};

/// Image converter for PNG, JPEG, and WebP formats using native ImageIO
@interface ITBImageConverter : NSObject

/// Convert image to specified format
/// @param image Source image (NSImage)
/// @param format Target format (PNG, JPEG, WebP)
/// @param qualityPercent Quality 0-100 (ignored for PNG)
/// @param backgroundColor Background color for alpha compositing (nil = preserve alpha)
/// @param error Error output
/// @return Encoded image data, or nil on failure
- (nullable NSData *)convertImage:(NSImage *)image
                         toFormat:(ITBImageFormat)format
                   qualityPercent:(NSInteger)qualityPercent
                  backgroundColor:(nullable NSColor *)backgroundColor
                            error:(NSError *_Nullable *_Nullable)error;

/// Check if file extension is supported for reading
/// @param fileExtension File extension (e.g., "png", "jpg", "webp")
/// @return YES if format can be read
+ (BOOL)canReadFormat:(NSString *)fileExtension;

/// Check if format is supported for writing
/// @param format Target format
/// @return YES if format can be written
+ (BOOL)canWriteFormat:(ITBImageFormat)format;

/// Get file extension for format
/// @param format Target format
/// @return File extension string (e.g., "png", "jpg", "webp")
+ (NSString *)fileExtensionForFormat:(ITBImageFormat)format;

/// Get UTType for format
/// @param format Target format
/// @return UTType for the format
+ (UTType *)utTypeForFormat:(ITBImageFormat)format;

/// Check if image has alpha channel
/// @param image Image to check
/// @return YES if image has alpha channel
+ (BOOL)imageHasAlpha:(NSImage *)image;

@end

NS_ASSUME_NONNULL_END
