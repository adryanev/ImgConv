#import <Cocoa/Cocoa.h>
#import "ITBVectorDocument.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const ITBVectorConverterErrorDomain;

typedef NS_ERROR_ENUM(ITBVectorConverterErrorDomain, ITBVectorConverterError) {
    ITBVectorConverterErrorInvalidXML = 2001,
    ITBVectorConverterErrorUnsupportedElement = 2002,
    ITBVectorConverterErrorInvalidPathData = 2003,
    ITBVectorConverterErrorRenderingFailed = 2004,
    ITBVectorConverterErrorInvalidDocument = 2005,
};

/// Converter for Android Vector Drawable XML format
@interface ITBVectorConverter : NSObject

/// Parse Android Vector Drawable XML data into a vector document
- (nullable ITBVectorDocument *)parseVectorDrawable:(NSData *)xmlData error:(NSError **)error;

/// Parse Android Vector Drawable XML from URL
- (nullable ITBVectorDocument *)parseVectorDrawableAtURL:(NSURL *)url error:(NSError **)error;

/// Convert vector document to SVG string
- (nullable NSString *)convertToSVG:(ITBVectorDocument *)document error:(NSError **)error;

/// Convert vector document to SVG data (UTF-8 encoded)
- (nullable NSData *)convertToSVGData:(ITBVectorDocument *)document error:(NSError **)error;

/// Render vector document to PNG at specified size
- (nullable NSData *)renderToPNG:(ITBVectorDocument *)document
                            size:(CGSize)size
                           scale:(CGFloat)scale
                           error:(NSError **)error;

/// Render vector document to NSImage at specified size
- (nullable NSImage *)renderToImage:(ITBVectorDocument *)document
                               size:(CGSize)size
                              scale:(CGFloat)scale
                              error:(NSError **)error;

/// Export vector document to Android Vector Drawable XML
- (nullable NSString *)exportToVectorDrawable:(ITBVectorDocument *)document error:(NSError **)error;

/// Export vector document to Android Vector Drawable XML data
- (nullable NSData *)exportToVectorDrawableData:(ITBVectorDocument *)document error:(NSError **)error;

/// Check if data appears to be Android Vector Drawable XML
+ (BOOL)isVectorDrawableData:(NSData *)data;

/// Check if file at URL is Android Vector Drawable XML
+ (BOOL)isVectorDrawableAtURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
