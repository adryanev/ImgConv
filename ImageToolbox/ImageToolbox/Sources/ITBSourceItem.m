#import "ITBSourceItem.h"
#import <os/log.h>

static const unsigned long long kMaxFileSizeBytes = 100 * 1024 * 1024; // 100MB

@interface ITBSourceItem ()
@property (strong, nonatomic, readwrite) NSURL *url;
@property (assign, nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (strong, nonatomic, readwrite, nullable) NSImage *image;
@end

@implementation ITBSourceItem

@synthesize image = _image;

+ (instancetype)itemWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url];
}

#pragma mark - Lazy Loading Image Getter

- (NSImage *)image {
    // For raster images, lazily load from URL if not cached
    if (!_image && self.url && self.type == ITBSourceTypeRaster) {
        NSURL *resolvedURL = self.url.filePathURL ?: self.url;
        _image = [[NSImage alloc] initWithContentsOfURL:resolvedURL];
    }
    return _image;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        _type = ITBSourceTypeNone;
        _loaded = NO;
    }
    return self;
}

- (NSString *)filename {
    return self.url.lastPathComponent;
}

- (BOOL)loadWithVectorConverter:(ITBVectorConverter *)vectorConverter
                          error:(NSError **)error {
    if (self.loaded) return YES;

    NSURL *resolvedURL = self.url.filePathURL ?: self.url;

    // Check file size first
    NSError *attrError = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:resolvedURL.path error:&attrError];
    if (!attrs) {
        os_log_error(OS_LOG_DEFAULT, "Failed to get file attributes for %{public}@: %{public}@",
                     resolvedURL.path, attrError.localizedDescription);
        if (error) {
            *error = attrError;
        }
        return NO;
    }
    NSNumber *fileSize = attrs[NSFileSize];
    if (fileSize.unsignedLongLongValue > kMaxFileSizeBytes) {
        os_log_error(OS_LOG_DEFAULT, "File exceeds maximum size: %{public}@ (%llu bytes)",
                     self.filename, fileSize.unsignedLongLongValue);
        if (error) {
            *error = [NSError errorWithDomain:@"ITBErrorDomain" code:101
                userInfo:@{NSLocalizedDescriptionKey: @"File exceeds maximum size of 100MB"}];
        }
        return NO;
    }
    NSString *extension = resolvedURL.pathExtension.lowercaseString;

    if ([extension isEqualToString:@"xml"]) {
        // Try to load as Android Vector Drawable
        NSError *vdError = nil;
        ITBVectorDocument *doc = [vectorConverter parseVectorDrawableAtURL:resolvedURL error:&vdError];

        if (doc) {
            self.vectorDocument = doc;
            self.type = ITBSourceTypeVector;

            // Create preview image from vector
            NSError *renderError = nil;
            self.image = [vectorConverter renderToImage:doc
                                                   size:CGSizeMake(200, 200)
                                                  scale:1.0
                                                  error:&renderError];
            if (!self.image && renderError) {
                os_log_error(OS_LOG_DEFAULT, "Failed to render vector preview for %{public}@: %{public}@",
                             self.filename, renderError.localizedDescription);
            }
            self.loaded = YES;
            return YES;
        }
        // Fall through to try as raster
    }

    if ([extension isEqualToString:@"svg"]) {
        // SVG import not yet supported
        if (error) {
            *error = [NSError errorWithDomain:@"ITBSourceItemErrorDomain"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"SVG import not yet supported"}];
        }
        return NO;
    }

    // Try to load as raster image
    // Only validate it can be loaded - don't cache the full image
    // The image property uses lazy loading from URL when accessed
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:resolvedURL];

    if (image) {
        // Don't store the image - it will be lazily loaded when needed
        // This prevents memory exhaustion with large batches
        self.vectorDocument = nil;
        self.type = ITBSourceTypeRaster;
        self.loaded = YES;
        return YES;
    }

    os_log_error(OS_LOG_DEFAULT, "Failed to load image file: %{public}@", self.filename);
    if (error) {
        *error = [NSError errorWithDomain:@"ITBSourceItemErrorDomain"
                                     code:2
                                 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to load: %@", self.filename]}];
    }
    return NO;
}

- (void)generateThumbnailWithSize:(CGSize)size {
    if (!self.image) return;

    NSImage *sourceImage = self.image;
    NSSize imageSize = sourceImage.size;

    // Calculate aspect-fit size
    CGFloat scale = MIN(size.width / imageSize.width, size.height / imageSize.height);
    NSSize scaledSize = NSMakeSize(imageSize.width * scale, imageSize.height * scale);

    // Create thumbnail using modern block-based API (thread-safe, not deprecated)
    NSImage *thumbnail = [NSImage imageWithSize:NSMakeSize(size.width, size.height)
                                        flipped:NO
                                 drawingHandler:^BOOL(NSRect dstRect) {
        // Background is already transparent by default

        // Draw centered
        CGFloat x = (size.width - scaledSize.width) / 2;
        CGFloat y = (size.height - scaledSize.height) / 2;

        [sourceImage drawInRect:NSMakeRect(x, y, scaledSize.width, scaledSize.height)
                       fromRect:NSZeroRect
                      operation:NSCompositingOperationSourceOver
                       fraction:1.0];

        return YES;
    }];

    self.thumbnail = thumbnail;
}

- (void)generateThumbnailWithSize:(CGSize)size
                       completion:(void (^)(NSImage * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self generateThumbnailWithSize:size];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(self.thumbnail);
            }
        });
    });
}

#pragma mark - Memory Management

- (void)releaseFullImage {
    // Release the full-resolution image to free memory
    // For raster images, it will be lazily reloaded from URL when accessed again
    // For vector documents, this just releases the cached preview
    _image = nil;
}

@end
