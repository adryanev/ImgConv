#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ITBDropZoneView;

/// Delegate protocol for ITBDropZoneView
@protocol ITBDropZoneViewDelegate <NSObject>

/// Called when an image file is dropped onto the view
/// @param view The drop zone view
/// @param url URL of the dropped image file
- (void)dropZoneView:(ITBDropZoneView *)view didReceiveImageAtURL:(NSURL *)url;

@end

/// A view that accepts drag-and-drop of image files
@interface ITBDropZoneView : NSView

/// Delegate to receive drop events
@property (weak, nonatomic, nullable) id<ITBDropZoneViewDelegate> delegate;

/// Image view for displaying thumbnail
@property (strong, nonatomic, readonly) NSImageView *thumbnailView;

/// Label showing instructions
@property (strong, nonatomic, readonly) NSTextField *instructionLabel;

/// Whether the view is currently highlighted (during drag hover)
@property (assign, nonatomic, readonly) BOOL isHighlighted;

/// Set the image to display in the drop zone
/// @param image The image to display, or nil to show instructions
- (void)setImage:(nullable NSImage *)image;

/// Reset the drop zone to its initial state
- (void)reset;

@end

NS_ASSUME_NONNULL_END
