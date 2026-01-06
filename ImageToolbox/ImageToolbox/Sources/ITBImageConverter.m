#import "ITBImageConverter.h"
#import <os/log.h>

NSErrorDomain const ITBImageConverterErrorDomain = @"ITBImageConverterErrorDomain";

@implementation ITBImageConverter

#pragma mark - Public Methods

- (nullable NSData *)convertImage:(NSImage *)image
                         toFormat:(ITBImageFormat)format
                   qualityPercent:(NSInteger)qualityPercent
                  backgroundColor:(nullable NSColor *)backgroundColor
                            error:(NSError *_Nullable *_Nullable)error {

    // Validate input
    if (!image) {
        os_log_error(OS_LOG_DEFAULT, "Image conversion failed: No image provided");
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorInvalidInput
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"No image provided",
                NSLocalizedRecoverySuggestionErrorKey: @"Please provide a valid image"
            }];
        }
        return nil;
    }

    // Clamp quality to valid range
    NSInteger quality = MAX(0, MIN(100, qualityPercent));

    // Get CGImage from NSImage
    CGImageRef cgImage = [self cgImageFromNSImage:image withBackgroundColor:backgroundColor];
    if (!cgImage) {
        os_log_error(OS_LOG_DEFAULT, "Image conversion failed: Failed to decode image to CGImage");
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorDecodingFailed
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to decode image",
                NSLocalizedRecoverySuggestionErrorKey: @"The image format may be unsupported"
            }];
        }
        return nil;
    }

    // Get UTType for target format
    UTType *utType = [ITBImageConverter utTypeForFormat:format];
    if (!utType) {
        os_log_error(OS_LOG_DEFAULT, "Image conversion failed: Unsupported output format %d", (int)format);
        CGImageRelease(cgImage);
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorUnsupportedFormat
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Unsupported output format",
                NSLocalizedRecoverySuggestionErrorKey: @"Try PNG, JPEG, or WebP"
            }];
        }
        return nil;
    }

    // Create mutable data and image destination
    NSMutableData *outputData = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(
        (__bridge CFMutableDataRef)outputData,
        (__bridge CFStringRef)utType.identifier,
        1,
        NULL
    );

    if (!destination) {
        os_log_error(OS_LOG_DEFAULT, "Image conversion failed: Failed to create image encoder for format %{public}@",
                     utType.identifier);
        CGImageRelease(cgImage);
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorEncodingFailed
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to create image encoder",
                NSLocalizedRecoverySuggestionErrorKey: @"Try a different format"
            }];
        }
        return nil;
    }

    // Set encoding options
    NSDictionary *options = [self encodingOptionsForFormat:format quality:quality];
    CGImageDestinationAddImage(destination, cgImage, (__bridge CFDictionaryRef)options);

    // Finalize
    BOOL success = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    CGImageRelease(cgImage);

    if (!success) {
        os_log_error(OS_LOG_DEFAULT, "Image conversion failed: Failed to finalize image encoding");
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorEncodingFailed
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to encode image",
                NSLocalizedRecoverySuggestionErrorKey: @"Try a different format or quality setting"
            }];
        }
        return nil;
    }

    return [outputData copy];
}

#pragma mark - Class Methods

+ (BOOL)canReadFormat:(NSString *)fileExtension {
    NSString *ext = [fileExtension lowercaseString];
    if ([ext hasPrefix:@"."]) {
        ext = [ext substringFromIndex:1];
    }

    NSSet<NSString *> *supportedExtensions = [NSSet setWithArray:@[
        @"png", @"jpg", @"jpeg", @"webp"
    ]];

    return [supportedExtensions containsObject:ext];
}

+ (BOOL)canWriteFormat:(ITBImageFormat)format {
    switch (format) {
        case ITBImageFormatPNG:
        case ITBImageFormatJPEG:
        case ITBImageFormatWebP:
            return YES;
    }
    return NO;
}

+ (NSString *)fileExtensionForFormat:(ITBImageFormat)format {
    switch (format) {
        case ITBImageFormatPNG:
            return @"png";
        case ITBImageFormatJPEG:
            return @"jpg";
        case ITBImageFormatWebP:
            return @"webp";
    }
    return @"png";
}

+ (UTType *)utTypeForFormat:(ITBImageFormat)format {
    switch (format) {
        case ITBImageFormatPNG:
            return UTTypePNG;
        case ITBImageFormatJPEG:
            return UTTypeJPEG;
        case ITBImageFormatWebP:
            return UTTypeWebP;
    }
    return nil;
}

+ (BOOL)imageHasAlpha:(NSImage *)image {
    if (!image) return NO;

    NSBitmapImageRep *rep = nil;
    for (NSImageRep *imageRep in image.representations) {
        if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
            rep = (NSBitmapImageRep *)imageRep;
            break;
        }
    }

    if (!rep) {
        // Try to create bitmap rep from TIFF data
        NSData *tiffData = [image TIFFRepresentation];
        if (tiffData) {
            rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
        }
    }

    return rep ? rep.hasAlpha : NO;
}

#pragma mark - Private Methods

- (CGImageRef)cgImageFromNSImage:(NSImage *)image withBackgroundColor:(nullable NSColor *)backgroundColor {
    if (!image) return NULL;

    NSSize size = image.size;
    if (size.width <= 0 || size.height <= 0) return NULL;

    // Create bitmap context
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:(NSInteger)size.width
                      pixelsHigh:(NSInteger)size.height
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSCalibratedRGBColorSpace
                     bytesPerRow:0
                    bitsPerPixel:0];

    if (!rep) return NULL;

    rep.size = size;

    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    [NSGraphicsContext setCurrentContext:context];

    // Fill background if color provided (for alpha compositing)
    if (backgroundColor) {
        [backgroundColor setFill];
        NSRectFill(NSMakeRect(0, 0, size.width, size.height));
    }

    // Draw image
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
             fromRect:NSZeroRect
            operation:NSCompositingOperationSourceOver
             fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];

    // Get CGImage (caller must release)
    CGImageRef cgImage = CGImageRetain([rep CGImage]);
    return cgImage;
}

- (NSDictionary *)encodingOptionsForFormat:(ITBImageFormat)format quality:(NSInteger)quality {
    NSMutableDictionary *options = [NSMutableDictionary dictionary];

    // Convert quality from 0-100 to 0.0-1.0
    CGFloat qualityValue = quality / 100.0;

    switch (format) {
        case ITBImageFormatPNG:
            // PNG is lossless, no quality setting needed
            break;

        case ITBImageFormatJPEG:
            options[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(qualityValue);
            break;

        case ITBImageFormatWebP:
            options[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(qualityValue);
            break;
    }

    return options;
}

@end
