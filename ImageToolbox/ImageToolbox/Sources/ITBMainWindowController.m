#import "ITBMainWindowController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <stdatomic.h>
#import <os/log.h>

static const CGFloat kWindowWidth = 420.0;
static const CGFloat kWindowHeight = 700.0;
static const CGFloat kPadding = 20.0;
static const CGFloat kSpacing = 12.0;

@interface ITBMainWindowController ()

@property (strong, nonatomic, readwrite) ITBDropZoneView *dropZoneView;
@property (strong, nonatomic, readwrite) ITBThumbnailGridView *thumbnailGridView;
@property (strong, nonatomic, readwrite) NSSegmentedControl *formatSelector;
@property (strong, nonatomic, readwrite) NSSlider *qualitySlider;
@property (strong, nonatomic, readwrite) NSTextField *qualityValueLabel;
@property (strong, nonatomic, readwrite) NSTextField *qualityTitleLabel;
@property (strong, nonatomic, readwrite) NSColorWell *backgroundColorWell;
@property (strong, nonatomic, readwrite) NSTextField *backgroundColorLabel;
@property (strong, nonatomic, readwrite) NSButton *saveButton;
@property (strong, nonatomic, readwrite) NSTextField *statusLabel;
@property (strong, nonatomic, readwrite) NSProgressIndicator *batchProgressIndicator;
@property (strong, nonatomic, readwrite) NSTextField *batchProgressLabel;
@property (strong, nonatomic, readwrite) ITBImageConverter *converter;

// Vectorization controls
@property (strong, nonatomic, readwrite) NSTextField *colorCountLabel;
@property (strong, nonatomic, readwrite) NSSlider *colorCountSlider;
@property (strong, nonatomic, readwrite) NSTextField *colorCountValueLabel;
@property (strong, nonatomic, readwrite) NSTextField *toleranceLabel;
@property (strong, nonatomic, readwrite) NSSlider *toleranceSlider;
@property (strong, nonatomic, readwrite) NSTextField *toleranceValueLabel;

// Vector size controls
@property (strong, nonatomic, readwrite) NSTextField *sizeLabel;
@property (strong, nonatomic, readwrite) NSPopUpButton *sizePopUp;

// Converters
@property (strong, nonatomic, readwrite) ITBVectorConverter *vectorConverter;
@property (strong, nonatomic, readwrite) ITBImageTracer *imageTracer;

// State
@property (strong, nonatomic, readwrite) NSMutableArray<ITBSourceItem *> *sourceItems;

@property (strong, nonatomic) NSView *contentView;

@end

@implementation ITBMainWindowController

#pragma mark - Initialization

- (instancetype)init {
    NSWindow *window = [self createWindow];
    self = [super initWithWindow:window];
    if (self) {
        _converter = [[ITBImageConverter alloc] init];
        _vectorConverter = [[ITBVectorConverter alloc] init];
        _imageTracer = [[ITBImageTracer alloc] init];
        _sourceItems = [NSMutableArray array];

        _selectedOutputFormat = ITBOutputFormatJPEG;
        _qualityPercent = 85;
        _colorCount = 8;
        _tolerance = 1.0;

        [self setupUI];
        [self setupConstraints];
        [self updateUIState];
    }
    return self;
}

#pragma mark - Window Creation

- (NSWindow *)createWindow {
    NSRect frame = NSMakeRect(0, 0, kWindowWidth, kWindowHeight);
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
                              NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable;

    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:style
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"Image Toolbox";
    window.minSize = NSMakeSize(380, 550);
    [window center];

    return window;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.contentView = self.window.contentView;
    self.contentView.wantsLayer = YES;

    [self setupDropZone];
    [self setupThumbnailGridView];
    [self setupFormatSelector];
    [self setupQualityControls];
    [self setupBackgroundColorControls];
    [self setupVectorizationControls];
    [self setupSizeControls];
    [self setupSaveButton];
    [self setupBatchProgressControls];
    [self setupStatusLabel];
}

- (void)setupDropZone {
    _dropZoneView = [[ITBDropZoneView alloc] initWithFrame:NSZeroRect];
    _dropZoneView.translatesAutoresizingMaskIntoConstraints = NO;
    _dropZoneView.delegate = self;
    [self.contentView addSubview:_dropZoneView];
}

- (void)setupThumbnailGridView {
    _thumbnailGridView = [[ITBThumbnailGridView alloc] initWithFrame:NSZeroRect];
    _thumbnailGridView.translatesAutoresizingMaskIntoConstraints = NO;
    _thumbnailGridView.delegate = self;
    _thumbnailGridView.hidden = YES; // Hidden until files are added
    [self.contentView addSubview:_thumbnailGridView];
}

- (void)setupFormatSelector {
    _formatSelector = [NSSegmentedControl segmentedControlWithLabels:@[@"PNG", @"JPEG", @"WebP", @"SVG", @"VD"]
                                                        trackingMode:NSSegmentSwitchTrackingSelectOne
                                                              target:self
                                                              action:@selector(formatChanged:)];
    _formatSelector.translatesAutoresizingMaskIntoConstraints = NO;
    _formatSelector.selectedSegment = 1; // JPEG by default

    // Set tooltips for segments
    [_formatSelector setToolTip:@"PNG - Lossless format" forSegment:0];
    [_formatSelector setToolTip:@"JPEG - Lossy format" forSegment:1];
    [_formatSelector setToolTip:@"WebP - Modern format" forSegment:2];
    [_formatSelector setToolTip:@"SVG - Scalable vector" forSegment:3];
    [_formatSelector setToolTip:@"Android Vector Drawable" forSegment:4];

    [self.contentView addSubview:_formatSelector];
}

- (void)setupQualityControls {
    _qualityTitleLabel = [NSTextField labelWithString:@"Quality:"];
    _qualityTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_qualityTitleLabel];

    _qualitySlider = [[NSSlider alloc] initWithFrame:NSZeroRect];
    _qualitySlider.translatesAutoresizingMaskIntoConstraints = NO;
    _qualitySlider.minValue = 0;
    _qualitySlider.maxValue = 100;
    _qualitySlider.integerValue = 85;
    _qualitySlider.target = self;
    _qualitySlider.action = @selector(qualityChanged:);
    _qualitySlider.continuous = YES;
    [self.contentView addSubview:_qualitySlider];

    _qualityValueLabel = [NSTextField labelWithString:@"85%"];
    _qualityValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _qualityValueLabel.alignment = NSTextAlignmentRight;
    [_qualityValueLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.contentView addSubview:_qualityValueLabel];
}

- (void)setupBackgroundColorControls {
    _backgroundColorLabel = [NSTextField labelWithString:@"Background:"];
    _backgroundColorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_backgroundColorLabel];

    _backgroundColorWell = [[NSColorWell alloc] initWithFrame:NSZeroRect];
    _backgroundColorWell.translatesAutoresizingMaskIntoConstraints = NO;
    _backgroundColorWell.color = [NSColor whiteColor];
    if (@available(macOS 13.0, *)) {
        _backgroundColorWell.colorWellStyle = NSColorWellStyleMinimal;
    }
    [self.contentView addSubview:_backgroundColorWell];
}

- (void)setupVectorizationControls {
    // Color count
    _colorCountLabel = [NSTextField labelWithString:@"Colors:"];
    _colorCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_colorCountLabel];

    _colorCountSlider = [[NSSlider alloc] initWithFrame:NSZeroRect];
    _colorCountSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _colorCountSlider.minValue = 2;
    _colorCountSlider.maxValue = 16;
    _colorCountSlider.integerValue = 8;
    _colorCountSlider.target = self;
    _colorCountSlider.action = @selector(colorCountChanged:);
    _colorCountSlider.continuous = YES;
    [self.contentView addSubview:_colorCountSlider];

    _colorCountValueLabel = [NSTextField labelWithString:@"8"];
    _colorCountValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _colorCountValueLabel.alignment = NSTextAlignmentRight;
    [_colorCountValueLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.contentView addSubview:_colorCountValueLabel];

    // Tolerance
    _toleranceLabel = [NSTextField labelWithString:@"Simplify:"];
    _toleranceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_toleranceLabel];

    _toleranceSlider = [[NSSlider alloc] initWithFrame:NSZeroRect];
    _toleranceSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _toleranceSlider.minValue = 0.5;
    _toleranceSlider.maxValue = 5.0;
    _toleranceSlider.floatValue = 1.0;
    _toleranceSlider.target = self;
    _toleranceSlider.action = @selector(toleranceChanged:);
    _toleranceSlider.continuous = YES;
    [self.contentView addSubview:_toleranceSlider];

    _toleranceValueLabel = [NSTextField labelWithString:@"1.0"];
    _toleranceValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _toleranceValueLabel.alignment = NSTextAlignmentRight;
    [_toleranceValueLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.contentView addSubview:_toleranceValueLabel];
}

- (void)setupSizeControls {
    _sizeLabel = [NSTextField labelWithString:@"Size:"];
    _sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_sizeLabel];

    _sizePopUp = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    _sizePopUp.translatesAutoresizingMaskIntoConstraints = NO;
    [_sizePopUp addItemsWithTitles:@[@"24dp", @"48dp", @"96dp", @"Original"]];
    [_sizePopUp selectItemAtIndex:0];
    [self.contentView addSubview:_sizePopUp];
}

- (void)setupSaveButton {
    _saveButton = [NSButton buttonWithTitle:@"Convert & Save..."
                                     target:self
                                     action:@selector(saveClicked:)];
    _saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    _saveButton.bezelStyle = NSBezelStyleRounded;
    _saveButton.keyEquivalent = @"\r"; // Enter key
    _saveButton.enabled = NO;
    [self.contentView addSubview:_saveButton];
}

- (void)setupBatchProgressControls {
    _batchProgressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    _batchProgressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _batchProgressIndicator.style = NSProgressIndicatorStyleBar;
    _batchProgressIndicator.indeterminate = NO;
    _batchProgressIndicator.minValue = 0;
    _batchProgressIndicator.maxValue = 100;
    _batchProgressIndicator.hidden = YES;
    [self.contentView addSubview:_batchProgressIndicator];

    _batchProgressLabel = [NSTextField labelWithString:@""];
    _batchProgressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _batchProgressLabel.textColor = [NSColor secondaryLabelColor];
    _batchProgressLabel.alignment = NSTextAlignmentCenter;
    _batchProgressLabel.font = [NSFont systemFontOfSize:11];
    _batchProgressLabel.hidden = YES;
    [self.contentView addSubview:_batchProgressLabel];
}

- (void)setupStatusLabel {
    _statusLabel = [NSTextField labelWithString:@"Ready"];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.textColor = [NSColor secondaryLabelColor];
    _statusLabel.alignment = NSTextAlignmentCenter;
    _statusLabel.font = [NSFont systemFontOfSize:12];
    [self.contentView addSubview:_statusLabel];
}

#pragma mark - Constraints

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // Drop zone (shown when no items)
        [_dropZoneView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kPadding],
        [_dropZoneView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_dropZoneView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_dropZoneView.heightAnchor constraintEqualToConstant:160],

        // Thumbnail grid view (shown when items exist, same position as drop zone)
        [_thumbnailGridView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kPadding],
        [_thumbnailGridView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_thumbnailGridView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_thumbnailGridView.heightAnchor constraintEqualToConstant:180],

        // Format selector
        [_formatSelector.topAnchor constraintEqualToAnchor:_dropZoneView.bottomAnchor constant:kSpacing],
        [_formatSelector.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],

        // Quality controls
        [_qualityTitleLabel.topAnchor constraintEqualToAnchor:_formatSelector.bottomAnchor constant:kSpacing],
        [_qualityTitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_qualityTitleLabel.widthAnchor constraintEqualToConstant:75],

        [_qualitySlider.centerYAnchor constraintEqualToAnchor:_qualityTitleLabel.centerYAnchor],
        [_qualitySlider.leadingAnchor constraintEqualToAnchor:_qualityTitleLabel.trailingAnchor constant:8],
        [_qualitySlider.trailingAnchor constraintEqualToAnchor:_qualityValueLabel.leadingAnchor constant:-8],

        [_qualityValueLabel.centerYAnchor constraintEqualToAnchor:_qualityTitleLabel.centerYAnchor],
        [_qualityValueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_qualityValueLabel.widthAnchor constraintEqualToConstant:45],

        // Background color controls
        [_backgroundColorLabel.topAnchor constraintEqualToAnchor:_qualityTitleLabel.bottomAnchor constant:kSpacing],
        [_backgroundColorLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_backgroundColorLabel.widthAnchor constraintEqualToConstant:75],

        [_backgroundColorWell.centerYAnchor constraintEqualToAnchor:_backgroundColorLabel.centerYAnchor],
        [_backgroundColorWell.leadingAnchor constraintEqualToAnchor:_backgroundColorLabel.trailingAnchor constant:8],
        [_backgroundColorWell.widthAnchor constraintEqualToConstant:44],
        [_backgroundColorWell.heightAnchor constraintEqualToConstant:28],

        // Vectorization controls - Color count
        [_colorCountLabel.topAnchor constraintEqualToAnchor:_backgroundColorLabel.bottomAnchor constant:kSpacing],
        [_colorCountLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_colorCountLabel.widthAnchor constraintEqualToConstant:75],

        [_colorCountSlider.centerYAnchor constraintEqualToAnchor:_colorCountLabel.centerYAnchor],
        [_colorCountSlider.leadingAnchor constraintEqualToAnchor:_colorCountLabel.trailingAnchor constant:8],
        [_colorCountSlider.trailingAnchor constraintEqualToAnchor:_colorCountValueLabel.leadingAnchor constant:-8],

        [_colorCountValueLabel.centerYAnchor constraintEqualToAnchor:_colorCountLabel.centerYAnchor],
        [_colorCountValueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_colorCountValueLabel.widthAnchor constraintEqualToConstant:45],

        // Vectorization controls - Tolerance
        [_toleranceLabel.topAnchor constraintEqualToAnchor:_colorCountLabel.bottomAnchor constant:kSpacing],
        [_toleranceLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_toleranceLabel.widthAnchor constraintEqualToConstant:75],

        [_toleranceSlider.centerYAnchor constraintEqualToAnchor:_toleranceLabel.centerYAnchor],
        [_toleranceSlider.leadingAnchor constraintEqualToAnchor:_toleranceLabel.trailingAnchor constant:8],
        [_toleranceSlider.trailingAnchor constraintEqualToAnchor:_toleranceValueLabel.leadingAnchor constant:-8],

        [_toleranceValueLabel.centerYAnchor constraintEqualToAnchor:_toleranceLabel.centerYAnchor],
        [_toleranceValueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_toleranceValueLabel.widthAnchor constraintEqualToConstant:45],

        // Size controls
        [_sizeLabel.topAnchor constraintEqualToAnchor:_toleranceLabel.bottomAnchor constant:kSpacing],
        [_sizeLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_sizeLabel.widthAnchor constraintEqualToConstant:75],

        [_sizePopUp.centerYAnchor constraintEqualToAnchor:_sizeLabel.centerYAnchor],
        [_sizePopUp.leadingAnchor constraintEqualToAnchor:_sizeLabel.trailingAnchor constant:8],
        [_sizePopUp.widthAnchor constraintEqualToConstant:100],

        // Save button
        [_saveButton.topAnchor constraintEqualToAnchor:_sizeLabel.bottomAnchor constant:kSpacing * 1.5],
        [_saveButton.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_saveButton.widthAnchor constraintGreaterThanOrEqualToConstant:150],

        // Batch progress indicator
        [_batchProgressIndicator.topAnchor constraintEqualToAnchor:_saveButton.bottomAnchor constant:kSpacing],
        [_batchProgressIndicator.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_batchProgressIndicator.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],

        // Batch progress label
        [_batchProgressLabel.topAnchor constraintEqualToAnchor:_batchProgressIndicator.bottomAnchor constant:4],
        [_batchProgressLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_batchProgressLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],

        // Status label
        [_statusLabel.topAnchor constraintEqualToAnchor:_batchProgressLabel.bottomAnchor constant:kSpacing],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_statusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-kPadding],
    ]];
}

#pragma mark - Actions

- (void)formatChanged:(id)sender {
    switch (_formatSelector.selectedSegment) {
        case 0:
            self.selectedOutputFormat = ITBOutputFormatPNG;
            break;
        case 1:
            self.selectedOutputFormat = ITBOutputFormatJPEG;
            break;
        case 2:
            self.selectedOutputFormat = ITBOutputFormatWebP;
            break;
        case 3:
            self.selectedOutputFormat = ITBOutputFormatSVG;
            break;
        case 4:
            self.selectedOutputFormat = ITBOutputFormatVectorDrawable;
            break;
    }
    [self updateUIState];
}

- (void)qualityChanged:(id)sender {
    self.qualityPercent = _qualitySlider.integerValue;
    _qualityValueLabel.stringValue = [NSString stringWithFormat:@"%ld%%", (long)self.qualityPercent];
}

- (void)colorCountChanged:(id)sender {
    self.colorCount = _colorCountSlider.integerValue;
    _colorCountValueLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)self.colorCount];
}

- (void)toleranceChanged:(id)sender {
    self.tolerance = _toleranceSlider.floatValue;
    _toleranceValueLabel.stringValue = [NSString stringWithFormat:@"%.1f", self.tolerance];
}

- (void)saveClicked:(id)sender {
    if (self.sourceItems.count == 0) {
        return;
    }

    if (self.sourceItems.count == 1) {
        // Single file: use save panel
        [self showSavePanelForSingleItem];
    } else {
        // Multiple files: use folder chooser for batch export
        [self showFolderChooserForBatchExport];
    }
}

- (void)showSavePanelForSingleItem {
    ITBSourceItem *item = self.sourceItems.firstObject;

    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[[self utTypeForOutputFormat:self.selectedOutputFormat]];

    NSString *baseName = item.filename.stringByDeletingPathExtension ?: @"converted";
    NSString *extension = [self fileExtensionForOutputFormat:self.selectedOutputFormat];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.%@", baseName, extension];

    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (result == NSModalResponseOK && panel.URL) {
            [strongSelf exportItem:item toURL:panel.URL];
        }
    }];
}

- (void)showFolderChooserForBatchExport {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    panel.canCreateDirectories = YES;
    panel.prompt = @"Choose Output Folder";
    panel.message = [NSString stringWithFormat:@"Export %lu files to folder", (unsigned long)self.sourceItems.count];

    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (result == NSModalResponseOK && panel.URL) {
            [strongSelf batchExportToFolder:panel.URL];
        }
    }];
}

#pragma mark - Filename Sanitization

- (NSString *)sanitizedFilename:(NSString *)filename {
    // Get just the filename, not path
    NSString *name = [filename lastPathComponent];
    // Remove path separators and dangerous characters
    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/:\\"];
    name = [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
    // Ensure not empty
    if (name.length == 0) {
        name = @"unnamed";
    }
    return name;
}

#pragma mark - Format Helpers

- (UTType *)utTypeForOutputFormat:(ITBOutputFormat)format {
    switch (format) {
        case ITBOutputFormatPNG:
            return UTTypePNG;
        case ITBOutputFormatJPEG:
            return UTTypeJPEG;
        case ITBOutputFormatWebP:
            return UTTypeWebP;
        case ITBOutputFormatSVG:
            return UTTypeSVG;
        case ITBOutputFormatVectorDrawable:
            return UTTypeXML;
    }
}

- (NSString *)fileExtensionForOutputFormat:(ITBOutputFormat)format {
    switch (format) {
        case ITBOutputFormatPNG:
            return @"png";
        case ITBOutputFormatJPEG:
            return @"jpg";
        case ITBOutputFormatWebP:
            return @"webp";
        case ITBOutputFormatSVG:
            return @"svg";
        case ITBOutputFormatVectorDrawable:
            return @"xml";
    }
}

#pragma mark - Export

- (void)exportItem:(ITBSourceItem *)item toURL:(NSURL *)url {
    self.statusLabel.stringValue = @"Converting...";
    self.saveButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        NSError *error = nil;
        NSData *data = [strongSelf convertItem:item error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) innerSelf = weakSelf;
            if (!innerSelf) return;

            if (data) {
                NSError *writeError = nil;
                BOOL success = [data writeToURL:url options:NSDataWritingAtomic error:&writeError];

                if (success) {
                    innerSelf.statusLabel.stringValue = [NSString stringWithFormat:@"Saved: %@", url.lastPathComponent];
                } else {
                    [innerSelf showError:writeError ?: error];
                }
            } else {
                [innerSelf showError:error];
            }
            innerSelf.saveButton.enabled = YES;
        });
    });
}

- (void)batchExportToFolder:(NSURL *)folderURL {
    self.saveButton.enabled = NO;
    self.batchProgressIndicator.hidden = NO;
    self.batchProgressLabel.hidden = NO;
    self.batchProgressIndicator.doubleValue = 0;
    self.batchProgressLabel.stringValue = @"Starting batch export...";

    NSArray<ITBSourceItem *> *items = [self.sourceItems copy];
    NSString *extension = [self fileExtensionForOutputFormat:self.selectedOutputFormat];
    NSUInteger totalCount = items.count;

    // Thread-safe counters for tracking progress using C11 atomic operations
    __block atomic_int_fast64_t completedCount = 0;
    __block atomic_int_fast64_t successCount = 0;
    __block atomic_int_fast64_t failCount = 0;
    NSMutableArray<NSString *> *failedFiles = [NSMutableArray array];
    NSLock *failedFilesLock = [[NSLock alloc] init];

    // Create dispatch group for tracking completion without blocking
    dispatch_group_t group = dispatch_group_create();

    // Use concurrent queue for parallel processing
    dispatch_queue_t processingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // Weak reference to self to avoid retain cycles in blocks
    __weak typeof(self) weakSelf = self;

    // Process all items concurrently
    for (NSUInteger i = 0; i < items.count; i++) {
        ITBSourceItem *item = items[i];

        dispatch_group_enter(group);
        dispatch_async(processingQueue, ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                dispatch_group_leave(group);
                return;
            }

            NSError *error = nil;
            NSData *data = [strongSelf convertItem:item error:&error];

            BOOL itemSuccess = NO;
            if (data) {
                NSString *sanitizedName = [strongSelf sanitizedFilename:item.filename];
                NSString *baseName = sanitizedName.stringByDeletingPathExtension;
                NSString *outputName = [NSString stringWithFormat:@"%@.%@", baseName, extension];
                NSURL *outputURL = [folderURL URLByAppendingPathComponent:outputName];

                NSError *writeError = nil;
                if ([data writeToURL:outputURL options:NSDataWritingAtomic error:&writeError]) {
                    itemSuccess = YES;
                } else {
                    os_log_error(OS_LOG_DEFAULT, "Failed to write file %{public}@: %{public}@",
                                 outputName, writeError.localizedDescription);
                }
            } else {
                os_log_error(OS_LOG_DEFAULT, "Failed to convert file %{public}@: %{public}@",
                             item.filename, error.localizedDescription);
            }

            // Update counters atomically using C11 atomics
            int64_t newCompleted = atomic_fetch_add_explicit(&completedCount, 1, memory_order_relaxed) + 1;
            if (itemSuccess) {
                atomic_fetch_add_explicit(&successCount, 1, memory_order_relaxed);
            } else {
                atomic_fetch_add_explicit(&failCount, 1, memory_order_relaxed);
                [failedFilesLock lock];
                [failedFiles addObject:item.filename];
                [failedFilesLock unlock];
            }

            // Update progress on main thread (non-blocking)
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) innerSelf = weakSelf;
                if (!innerSelf) return;
                innerSelf.batchProgressLabel.stringValue = [NSString stringWithFormat:@"Processed %lld/%lu",
                                                       newCompleted, (unsigned long)totalCount];
                innerSelf.batchProgressIndicator.doubleValue = ((double)newCompleted / totalCount) * 100;
            });

            dispatch_group_leave(group);
        });
    }

    // Non-blocking completion handler using dispatch_group_notify
    // This runs on main queue when all items are processed, without blocking UI
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        // Hide progress indicators
        strongSelf.batchProgressIndicator.hidden = YES;
        strongSelf.batchProgressLabel.hidden = YES;
        strongSelf.saveButton.enabled = YES;

        // Show completion alert
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        [alert addButtonWithTitle:@"OK"];

        int64_t finalSuccessCount = atomic_load_explicit(&successCount, memory_order_relaxed);
        int64_t finalFailCount = atomic_load_explicit(&failCount, memory_order_relaxed);

        if (finalFailCount == 0) {
            alert.messageText = @"Batch Export Complete";
            alert.informativeText = [NSString stringWithFormat:@"Successfully exported %lld files.",
                                     finalSuccessCount];
            strongSelf.statusLabel.stringValue = [NSString stringWithFormat:@"Exported %lld files successfully",
                                            finalSuccessCount];
        } else {
            alert.messageText = @"Batch Export Completed with Errors";
            alert.informativeText = [NSString stringWithFormat:@"Exported %lld/%lu files. %lld files failed.",
                                     finalSuccessCount, (unsigned long)totalCount, finalFailCount];
            strongSelf.statusLabel.stringValue = [NSString stringWithFormat:@"Exported %lld/%lu (failed: %lld)",
                                            finalSuccessCount, (unsigned long)totalCount, finalFailCount];
        }

        [alert beginSheetModalForWindow:strongSelf.window completionHandler:nil];
    });
}

- (nullable NSData *)convertItem:(ITBSourceItem *)item error:(NSError **)error {
    if (item.type == ITBSourceTypeVector) {
        return [self exportVectorItem:item error:error];
    } else {
        return [self exportRasterItem:item error:error];
    }
}

- (nullable NSData *)exportVectorItem:(ITBSourceItem *)item error:(NSError **)error {
    ITBVectorDocument *doc = item.vectorDocument;

    switch (self.selectedOutputFormat) {
        case ITBOutputFormatPNG: {
            CGSize size = [self selectedOutputSizeForDocument:doc];
            return [self.vectorConverter renderToPNG:doc size:size scale:1.0 error:error];
        }
        case ITBOutputFormatJPEG: {
            CGSize size = [self selectedOutputSizeForDocument:doc];
            NSImage *image = [self.vectorConverter renderToImage:doc size:size scale:1.0 error:error];
            if (!image) return nil;

            NSColor *bgColor = self.backgroundColorWell.color;
            return [self.converter convertImage:image
                                       toFormat:ITBImageFormatJPEG
                                 qualityPercent:self.qualityPercent
                                backgroundColor:bgColor
                                          error:error];
        }
        case ITBOutputFormatWebP: {
            CGSize size = [self selectedOutputSizeForDocument:doc];
            NSImage *image = [self.vectorConverter renderToImage:doc size:size scale:1.0 error:error];
            if (!image) return nil;

            return [self.converter convertImage:image
                                       toFormat:ITBImageFormatWebP
                                 qualityPercent:self.qualityPercent
                                backgroundColor:nil
                                          error:error];
        }
        case ITBOutputFormatSVG:
            return [self.vectorConverter convertToSVGData:doc error:error];
        case ITBOutputFormatVectorDrawable:
            return [self.vectorConverter exportToVectorDrawableData:doc error:error];
    }
}

- (nullable NSData *)exportRasterItem:(ITBSourceItem *)item error:(NSError **)error {
    NSImage *image = item.image;

    switch (self.selectedOutputFormat) {
        case ITBOutputFormatPNG:
            return [self.converter convertImage:image
                                       toFormat:ITBImageFormatPNG
                                 qualityPercent:100
                                backgroundColor:nil
                                          error:error];
        case ITBOutputFormatJPEG: {
            NSColor *bgColor = nil;
            if ([ITBImageConverter imageHasAlpha:image]) {
                bgColor = self.backgroundColorWell.color;
            }
            return [self.converter convertImage:image
                                       toFormat:ITBImageFormatJPEG
                                 qualityPercent:self.qualityPercent
                                backgroundColor:bgColor
                                          error:error];
        }
        case ITBOutputFormatWebP:
            return [self.converter convertImage:image
                                       toFormat:ITBImageFormatWebP
                                 qualityPercent:self.qualityPercent
                                backgroundColor:nil
                                          error:error];
        case ITBOutputFormatSVG:
        case ITBOutputFormatVectorDrawable: {
            self.imageTracer.colorCount = self.colorCount;
            self.imageTracer.tolerance = self.tolerance;

            ITBVectorDocument *doc = [self.imageTracer traceImage:image error:error];
            if (!doc) return nil;

            if (self.selectedOutputFormat == ITBOutputFormatSVG) {
                return [self.vectorConverter convertToSVGData:doc error:error];
            } else {
                return [self.vectorConverter exportToVectorDrawableData:doc error:error];
            }
        }
    }
}

- (CGSize)selectedOutputSizeForDocument:(ITBVectorDocument *)doc {
    NSInteger index = [self.sizePopUp indexOfSelectedItem];
    CGSize originalSize = doc.outputSize;

    switch (index) {
        case 0: return CGSizeMake(24, 24);
        case 1: return CGSizeMake(48, 48);
        case 2: return CGSizeMake(96, 96);
        default: return originalSize;
    }
}

- (void)showError:(NSError *)error {
    self.statusLabel.stringValue = @"Error occurred";

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Conversion Failed";
    alert.informativeText = error.localizedDescription ?: @"An unknown error occurred";
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

#pragma mark - UI State

- (void)updateUIState {
    BOOL hasItems = (self.sourceItems.count > 0);

    // Show drop zone when empty, grid when has items
    _dropZoneView.hidden = hasItems;
    _thumbnailGridView.hidden = !hasItems;

    // Update save button
    _saveButton.enabled = hasItems;
    if (self.sourceItems.count > 1) {
        _saveButton.title = @"Batch Convert & Save...";
    } else {
        _saveButton.title = @"Convert & Save...";
    }

    // Determine source type from selected item or first item
    ITBSourceItem *activeItem = self.selectedSourceItem ?: self.sourceItems.firstObject;
    BOOL isVectorSource = (activeItem.type == ITBSourceTypeVector);
    BOOL isRasterSource = (activeItem.type == ITBSourceTypeRaster);

    BOOL isVectorOutput = (self.selectedOutputFormat == ITBOutputFormatSVG ||
                           self.selectedOutputFormat == ITBOutputFormatVectorDrawable);
    BOOL isRasterOutput = !isVectorOutput;

    // Quality controls: visible for JPEG/WebP raster output
    BOOL showQuality = isRasterOutput && (self.selectedOutputFormat != ITBOutputFormatPNG);
    _qualityTitleLabel.hidden = !showQuality;
    _qualitySlider.hidden = !showQuality;
    _qualityValueLabel.hidden = !showQuality;

    // Background color: visible for JPEG output when source may have alpha
    BOOL hasAlpha = activeItem ? [ITBImageConverter imageHasAlpha:activeItem.image] : NO;
    BOOL showBackgroundColor = (self.selectedOutputFormat == ITBOutputFormatJPEG) && (hasAlpha || isVectorSource);
    _backgroundColorLabel.hidden = !showBackgroundColor;
    _backgroundColorWell.hidden = !showBackgroundColor;

    // Vectorization controls: visible when converting raster to vector
    BOOL showVectorization = isVectorOutput && isRasterSource && hasItems;
    _colorCountLabel.hidden = !showVectorization;
    _colorCountSlider.hidden = !showVectorization;
    _colorCountValueLabel.hidden = !showVectorization;
    _toleranceLabel.hidden = !showVectorization;
    _toleranceSlider.hidden = !showVectorization;
    _toleranceValueLabel.hidden = !showVectorization;

    // Size controls: visible when outputting raster from vector source
    BOOL showSize = isRasterOutput && isVectorSource && hasItems;
    _sizeLabel.hidden = !showSize;
    _sizePopUp.hidden = !showSize;

    // Update status label
    if (hasItems) {
        if (self.sourceItems.count == 1) {
            _statusLabel.stringValue = [NSString stringWithFormat:@"Ready | 1 file loaded"];
        } else {
            _statusLabel.stringValue = [NSString stringWithFormat:@"Ready | %lu files loaded",
                                        (unsigned long)self.sourceItems.count];
        }
    } else {
        _statusLabel.stringValue = @"Ready";
    }
}

#pragma mark - ITBDropZoneViewDelegate

- (void)dropZoneView:(ITBDropZoneView *)view didReceiveImageAtURL:(NSURL *)url {
    // Legacy single-file method - redirect to multi-URL method
    [self dropZoneView:view didReceiveImageURLs:@[url]];
}

- (void)dropZoneView:(ITBDropZoneView *)view didReceiveImageURLs:(NSArray<NSURL *> *)urls {
    [self addItemsFromURLs:urls];
}

- (void)addItemsFromURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        NSURL *resolvedURL = url.filePathURL ?: url;

        // Check for SVG (unsupported)
        if ([resolvedURL.pathExtension.lowercaseString isEqualToString:@"svg"]) {
            continue; // Skip SVG files for now
        }

        ITBSourceItem *item = [ITBSourceItem itemWithURL:resolvedURL];
        NSError *error = nil;

        if ([item loadWithVectorConverter:self.vectorConverter error:&error]) {
            [item generateThumbnailWithSize:CGSizeMake(80, 80)];
            [self.sourceItems addObject:item];
        } else if (error) {
            os_log_error(OS_LOG_DEFAULT, "Failed to load file %{public}@: %{public}@",
                         resolvedURL.lastPathComponent, error.localizedDescription);
        }
    }

    [self.thumbnailGridView setItems:self.sourceItems];
    [self updateUIState];
}

#pragma mark - ITBThumbnailGridViewDelegate

- (void)thumbnailGridView:(ITBThumbnailGridView *)view didRequestRemoveItem:(ITBSourceItem *)item {
    [self.sourceItems removeObject:item];
    [self.thumbnailGridView setItems:self.sourceItems];

    if (self.selectedSourceItem == item) {
        self.selectedSourceItem = nil;
    }

    [self updateUIState];
}

- (void)thumbnailGridViewDidRequestAddFiles:(ITBThumbnailGridView *)view {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = YES;
    panel.allowedContentTypes = @[UTTypePNG, UTTypeJPEG, UTTypeWebP, UTTypeXML];
    panel.message = @"Select images to add";

    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (result == NSModalResponseOK) {
            [strongSelf addItemsFromURLs:panel.URLs];
        }
    }];
}

- (void)thumbnailGridView:(ITBThumbnailGridView *)view didSelectItem:(nullable ITBSourceItem *)item {
    self.selectedSourceItem = item;
    [self updateUIState];
}

@end
