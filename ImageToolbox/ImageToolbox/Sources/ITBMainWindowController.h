#import <Cocoa/Cocoa.h>
#import "ITBDropZoneView.h"
#import "ITBImageConverter.h"
#import "ITBVectorConverter.h"
#import "ITBImageTracer.h"
#import "ITBThumbnailGridView.h"
#import "ITBSourceItem.h"

NS_ASSUME_NONNULL_BEGIN

/// Output format types
typedef NS_ENUM(NSInteger, ITBOutputFormat) {
    ITBOutputFormatPNG,
    ITBOutputFormatJPEG,
    ITBOutputFormatWebP,
    ITBOutputFormatSVG,
    ITBOutputFormatVectorDrawable,
};

/// Main window controller for Image Toolbox
@interface ITBMainWindowController : NSWindowController <ITBDropZoneViewDelegate, ITBThumbnailGridViewDelegate>

/// UI Components
@property (strong, nonatomic, readonly) ITBDropZoneView *dropZoneView;
@property (strong, nonatomic, readonly) ITBThumbnailGridView *thumbnailGridView;
@property (strong, nonatomic, readonly) NSSegmentedControl *formatSelector;
@property (strong, nonatomic, readonly) NSSlider *qualitySlider;
@property (strong, nonatomic, readonly) NSTextField *qualityValueLabel;
@property (strong, nonatomic, readonly) NSTextField *qualityTitleLabel;
@property (strong, nonatomic, readonly) NSColorWell *backgroundColorWell;
@property (strong, nonatomic, readonly) NSTextField *backgroundColorLabel;
@property (strong, nonatomic, readonly) NSButton *saveButton;
@property (strong, nonatomic, readonly) NSTextField *statusLabel;
@property (strong, nonatomic, readonly) NSProgressIndicator *batchProgressIndicator;
@property (strong, nonatomic, readonly) NSTextField *batchProgressLabel;

/// Vectorization UI Components
@property (strong, nonatomic, readonly) NSTextField *colorCountLabel;
@property (strong, nonatomic, readonly) NSSlider *colorCountSlider;
@property (strong, nonatomic, readonly) NSTextField *colorCountValueLabel;
@property (strong, nonatomic, readonly) NSTextField *toleranceLabel;
@property (strong, nonatomic, readonly) NSSlider *toleranceSlider;
@property (strong, nonatomic, readonly) NSTextField *toleranceValueLabel;

/// Vector size controls
@property (strong, nonatomic, readonly) NSTextField *sizeLabel;
@property (strong, nonatomic, readonly) NSPopUpButton *sizePopUp;

/// State
@property (strong, nonatomic, readonly) NSMutableArray<ITBSourceItem *> *sourceItems;
@property (strong, nonatomic, nullable) ITBSourceItem *selectedSourceItem;
@property (assign, nonatomic) ITBOutputFormat selectedOutputFormat;
@property (assign, nonatomic) NSInteger qualityPercent;
@property (assign, nonatomic) NSInteger colorCount;
@property (assign, nonatomic) CGFloat tolerance;

/// Converters
@property (strong, nonatomic, readonly) ITBImageConverter *converter;
@property (strong, nonatomic, readonly) ITBVectorConverter *vectorConverter;
@property (strong, nonatomic, readonly) ITBImageTracer *imageTracer;

@end

NS_ASSUME_NONNULL_END
