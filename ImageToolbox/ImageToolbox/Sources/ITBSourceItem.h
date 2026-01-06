#import <Cocoa/Cocoa.h>
#import "ITBVectorDocument.h"
#import "ITBVectorConverter.h"

NS_ASSUME_NONNULL_BEGIN

/// Source type for loaded content
typedef NS_ENUM(NSInteger, ITBSourceType) {
    ITBSourceTypeNone,
    ITBSourceTypeRaster,
    ITBSourceTypeVector,
};

/// Represents a single source item (image or vector document) for batch processing
@interface ITBSourceItem : NSObject

/// The file URL
@property (strong, nonatomic, readonly) NSURL *url;

/// The loaded image (for raster) or rendered preview (for vector)
/// For raster images, this is lazily loaded from URL and can be released to save memory.
@property (strong, nonatomic, nullable, readonly) NSImage *image;

/// The vector document (for vector files)
@property (strong, nonatomic, nullable) ITBVectorDocument *vectorDocument;

/// The source type
@property (assign, nonatomic) ITBSourceType type;

/// Thumbnail for grid display (80x80)
@property (strong, nonatomic, nullable) NSImage *thumbnail;

/// Whether the item has been loaded
@property (assign, nonatomic, readonly, getter=isLoaded) BOOL loaded;

/// The filename (without path)
@property (copy, nonatomic, readonly) NSString *filename;

/// Create an item with a URL
+ (instancetype)itemWithURL:(NSURL *)url;

/// Initialize with a URL
- (instancetype)initWithURL:(NSURL *)url;

/// Load the file content (image or vector)
- (BOOL)loadWithVectorConverter:(ITBVectorConverter *)vectorConverter
                          error:(NSError **)error;

/// Generate thumbnail from loaded content
- (void)generateThumbnailWithSize:(CGSize)size;

/// Generate thumbnail asynchronously
- (void)generateThumbnailWithSize:(CGSize)size
                       completion:(void (^)(NSImage * _Nullable thumbnail))completion;

/// Release the full-resolution image from memory to reduce memory usage.
/// The image will be lazily reloaded from URL when accessed again (raster only).
/// For vector documents, this releases the cached preview image.
- (void)releaseFullImage;

@end

NS_ASSUME_NONNULL_END
