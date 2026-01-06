#import "ITBMainWindowController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static const CGFloat kWindowWidth = 400.0;
static const CGFloat kWindowHeight = 520.0;
static const CGFloat kPadding = 20.0;
static const CGFloat kSpacing = 16.0;

@interface ITBMainWindowController ()

@property (strong, nonatomic, readwrite) ITBDropZoneView *dropZoneView;
@property (strong, nonatomic, readwrite) NSSegmentedControl *formatSelector;
@property (strong, nonatomic, readwrite) NSSlider *qualitySlider;
@property (strong, nonatomic, readwrite) NSTextField *qualityValueLabel;
@property (strong, nonatomic, readwrite) NSTextField *qualityTitleLabel;
@property (strong, nonatomic, readwrite) NSColorWell *backgroundColorWell;
@property (strong, nonatomic, readwrite) NSTextField *backgroundColorLabel;
@property (strong, nonatomic, readwrite) NSButton *saveButton;
@property (strong, nonatomic, readwrite) NSTextField *statusLabel;
@property (strong, nonatomic, readwrite) ITBImageConverter *converter;

@property (strong, nonatomic) NSView *contentView;

@end

@implementation ITBMainWindowController

#pragma mark - Initialization

- (instancetype)init {
    NSWindow *window = [self createWindow];
    self = [super initWithWindow:window];
    if (self) {
        _converter = [[ITBImageConverter alloc] init];
        _selectedFormat = ITBImageFormatJPEG;
        _qualityPercent = 85;
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
    window.minSize = NSMakeSize(350, 450);
    [window center];

    return window;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.contentView = self.window.contentView;
    self.contentView.wantsLayer = YES;

    [self setupDropZone];
    [self setupFormatSelector];
    [self setupQualityControls];
    [self setupBackgroundColorControls];
    [self setupSaveButton];
    [self setupStatusLabel];
}

- (void)setupDropZone {
    _dropZoneView = [[ITBDropZoneView alloc] initWithFrame:NSZeroRect];
    _dropZoneView.translatesAutoresizingMaskIntoConstraints = NO;
    _dropZoneView.delegate = self;
    [self.contentView addSubview:_dropZoneView];
}

- (void)setupFormatSelector {
    _formatSelector = [NSSegmentedControl segmentedControlWithLabels:@[@"PNG", @"JPEG", @"WebP"]
                                                        trackingMode:NSSegmentSwitchTrackingSelectOne
                                                              target:self
                                                              action:@selector(formatChanged:)];
    _formatSelector.translatesAutoresizingMaskIntoConstraints = NO;
    _formatSelector.selectedSegment = 1; // JPEG by default
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
        // Drop zone
        [_dropZoneView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kPadding],
        [_dropZoneView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_dropZoneView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_dropZoneView.heightAnchor constraintEqualToConstant:180],

        // Format selector
        [_formatSelector.topAnchor constraintEqualToAnchor:_dropZoneView.bottomAnchor constant:kSpacing],
        [_formatSelector.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],

        // Quality controls
        [_qualityTitleLabel.topAnchor constraintEqualToAnchor:_formatSelector.bottomAnchor constant:kSpacing],
        [_qualityTitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],

        [_qualitySlider.centerYAnchor constraintEqualToAnchor:_qualityTitleLabel.centerYAnchor],
        [_qualitySlider.leadingAnchor constraintEqualToAnchor:_qualityTitleLabel.trailingAnchor constant:8],
        [_qualitySlider.trailingAnchor constraintEqualToAnchor:_qualityValueLabel.leadingAnchor constant:-8],

        [_qualityValueLabel.centerYAnchor constraintEqualToAnchor:_qualityTitleLabel.centerYAnchor],
        [_qualityValueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_qualityValueLabel.widthAnchor constraintEqualToConstant:45],

        // Background color controls
        [_backgroundColorLabel.topAnchor constraintEqualToAnchor:_qualityTitleLabel.bottomAnchor constant:kSpacing],
        [_backgroundColorLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],

        [_backgroundColorWell.centerYAnchor constraintEqualToAnchor:_backgroundColorLabel.centerYAnchor],
        [_backgroundColorWell.leadingAnchor constraintEqualToAnchor:_backgroundColorLabel.trailingAnchor constant:8],
        [_backgroundColorWell.widthAnchor constraintEqualToConstant:44],
        [_backgroundColorWell.heightAnchor constraintEqualToConstant:28],

        // Save button
        [_saveButton.topAnchor constraintEqualToAnchor:_backgroundColorLabel.bottomAnchor constant:kSpacing * 1.5],
        [_saveButton.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_saveButton.widthAnchor constraintGreaterThanOrEqualToConstant:150],

        // Status label
        [_statusLabel.topAnchor constraintEqualToAnchor:_saveButton.bottomAnchor constant:kSpacing],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
        [_statusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-kPadding],
    ]];
}

#pragma mark - Actions

- (void)formatChanged:(id)sender {
    switch (_formatSelector.selectedSegment) {
        case 0:
            self.selectedFormat = ITBImageFormatPNG;
            break;
        case 1:
            self.selectedFormat = ITBImageFormatJPEG;
            break;
        case 2:
            self.selectedFormat = ITBImageFormatWebP;
            break;
    }
    [self updateUIState];
}

- (void)qualityChanged:(id)sender {
    self.qualityPercent = _qualitySlider.integerValue;
    _qualityValueLabel.stringValue = [NSString stringWithFormat:@"%ld%%", (long)self.qualityPercent];
}

- (void)saveClicked:(id)sender {
    if (!self.sourceImage) {
        return;
    }

    // Create save panel
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[[ITBImageConverter utTypeForFormat:self.selectedFormat]];

    // Suggest filename based on source
    NSString *baseName = self.sourceURL.lastPathComponent.stringByDeletingPathExtension ?: @"converted";
    NSString *extension = [ITBImageConverter fileExtensionForFormat:self.selectedFormat];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.%@", baseName, extension];

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK && panel.URL) {
            [self exportToURL:panel.URL];
        }
    }];
}

#pragma mark - Export

- (void)exportToURL:(NSURL *)url {
    self.statusLabel.stringValue = @"Converting...";
    self.saveButton.enabled = NO;

    // Determine background color
    NSColor *backgroundColor = nil;
    if (self.selectedFormat == ITBImageFormatJPEG && [ITBImageConverter imageHasAlpha:self.sourceImage]) {
        backgroundColor = self.backgroundColorWell.color;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [self.converter convertImage:self.sourceImage
                                           toFormat:self.selectedFormat
                                     qualityPercent:self.qualityPercent
                                    backgroundColor:backgroundColor
                                              error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSError *writeError = nil;
                BOOL success = [data writeToURL:url options:NSDataWritingAtomic error:&writeError];

                if (success) {
                    self.statusLabel.stringValue = [NSString stringWithFormat:@"Saved: %@", url.lastPathComponent];
                } else {
                    [self showError:writeError ?: error];
                }
            } else {
                [self showError:error];
            }
            self.saveButton.enabled = YES;
        });
    });
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
    // Quality controls visible only for JPEG and WebP
    BOOL showQuality = (self.selectedFormat != ITBImageFormatPNG);
    _qualityTitleLabel.hidden = !showQuality;
    _qualitySlider.hidden = !showQuality;
    _qualityValueLabel.hidden = !showQuality;

    // Background color visible only when source has alpha AND target is JPEG
    BOOL hasAlpha = [ITBImageConverter imageHasAlpha:self.sourceImage];
    BOOL showBackgroundColor = hasAlpha && (self.selectedFormat == ITBImageFormatJPEG);
    _backgroundColorLabel.hidden = !showBackgroundColor;
    _backgroundColorWell.hidden = !showBackgroundColor;
}

#pragma mark - ITBDropZoneViewDelegate

- (void)dropZoneView:(ITBDropZoneView *)view didReceiveImageAtURL:(NSURL *)url {
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];

    if (image) {
        self.sourceImage = image;
        self.sourceURL = url;
        [self.dropZoneView setImage:image];
        self.saveButton.enabled = YES;
        self.statusLabel.stringValue = [NSString stringWithFormat:@"Loaded: %@", url.lastPathComponent];
        [self updateUIState];
    } else {
        self.statusLabel.stringValue = @"Failed to load image";
    }
}

@end
