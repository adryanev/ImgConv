#import <Cocoa/Cocoa.h>
#import "ITBDropZoneView.h"
#import "ITBImageConverter.h"

NS_ASSUME_NONNULL_BEGIN

/// Main window controller for Image Toolbox
@interface ITBMainWindowController : NSWindowController <ITBDropZoneViewDelegate>

/// UI Components
@property (strong, nonatomic, readonly) ITBDropZoneView *dropZoneView;
@property (strong, nonatomic, readonly) NSSegmentedControl *formatSelector;
@property (strong, nonatomic, readonly) NSSlider *qualitySlider;
@property (strong, nonatomic, readonly) NSTextField *qualityValueLabel;
@property (strong, nonatomic, readonly) NSTextField *qualityTitleLabel;
@property (strong, nonatomic, readonly) NSColorWell *backgroundColorWell;
@property (strong, nonatomic, readonly) NSTextField *backgroundColorLabel;
@property (strong, nonatomic, readonly) NSButton *saveButton;
@property (strong, nonatomic, readonly) NSTextField *statusLabel;

/// State
@property (strong, nonatomic, nullable) NSImage *sourceImage;
@property (strong, nonatomic, nullable) NSURL *sourceURL;
@property (assign, nonatomic) ITBImageFormat selectedFormat;
@property (assign, nonatomic) NSInteger qualityPercent;

/// Image converter
@property (strong, nonatomic, readonly) ITBImageConverter *converter;

@end

NS_ASSUME_NONNULL_END
