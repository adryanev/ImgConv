#import "ITBDropZoneView.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ITBDropZoneView ()

@property (strong, nonatomic, readwrite) NSImageView *thumbnailView;
@property (strong, nonatomic, readwrite) NSTextField *instructionLabel;
@property (assign, nonatomic, readwrite) BOOL isHighlighted;

@end

@implementation ITBDropZoneView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.wantsLayer = YES;
    self.layer.cornerRadius = 8.0;
    self.layer.borderWidth = 2.0;
    self.layer.borderColor = [NSColor separatorColor].CGColor;

    [self setupThumbnailView];
    [self setupInstructionLabel];
    [self setupDragTypes];

    _isHighlighted = NO;
}

#pragma mark - Setup

- (void)setupThumbnailView {
    _thumbnailView = [[NSImageView alloc] initWithFrame:NSZeroRect];
    _thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
    _thumbnailView.imageScaling = NSImageScaleProportionallyUpOrDown;
    _thumbnailView.imageAlignment = NSImageAlignCenter;
    _thumbnailView.hidden = YES;
    [self addSubview:_thumbnailView];

    [NSLayoutConstraint activateConstraints:@[
        [_thumbnailView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_thumbnailView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_thumbnailView.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.8],
        [_thumbnailView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.8],
    ]];
}

- (void)setupInstructionLabel {
    _instructionLabel = [NSTextField labelWithString:@"Drop Image Here\nPNG, JPEG, WebP, SVG, or Android VD"];
    _instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _instructionLabel.alignment = NSTextAlignmentCenter;
    _instructionLabel.textColor = [NSColor secondaryLabelColor];
    _instructionLabel.font = [NSFont systemFontOfSize:16 weight:NSFontWeightMedium];
    _instructionLabel.maximumNumberOfLines = 2;
    [self addSubview:_instructionLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_instructionLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_instructionLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_instructionLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.9],
    ]];
}

- (void)setupDragTypes {
    [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
}

#pragma mark - Public Methods

- (void)setImage:(nullable NSImage *)image {
    if (image) {
        self.thumbnailView.image = image;
        self.thumbnailView.hidden = NO;
        self.instructionLabel.hidden = YES;
    } else {
        self.thumbnailView.image = nil;
        self.thumbnailView.hidden = YES;
        self.instructionLabel.hidden = NO;
    }
}

- (void)reset {
    [self setImage:nil];
    [self setHighlighted:NO];
}

#pragma mark - Private Methods

- (void)setHighlighted:(BOOL)highlighted {
    _isHighlighted = highlighted;

    if (highlighted) {
        self.layer.borderColor = [NSColor systemBlueColor].CGColor;
        self.layer.borderWidth = 3.0;
        self.layer.backgroundColor = [[NSColor systemBlueColor] colorWithAlphaComponent:0.1].CGColor;
    } else {
        self.layer.borderColor = [NSColor separatorColor].CGColor;
        self.layer.borderWidth = 2.0;
        self.layer.backgroundColor = nil;
    }
}

- (BOOL)isValidFileExtension:(NSString *)extension {
    NSSet *validExtensions = [NSSet setWithArray:@[@"png", @"jpg", @"jpeg", @"webp", @"svg", @"xml"]];
    return [validExtensions containsObject:extension.lowercaseString];
}

- (NSArray<NSURL *> *)imageURLsFromPasteboard:(NSPasteboard *)pasteboard {
    NSArray *classes = @[[NSURL class]];
    NSDictionary *options = @{NSPasteboardURLReadingFileURLsOnlyKey: @YES};
    NSArray *urls = [pasteboard readObjectsForClasses:classes options:options];

    NSMutableArray *validURLs = [NSMutableArray array];
    for (NSURL *url in urls) {
        if ([self isValidFileExtension:url.pathExtension]) {
            [validURLs addObject:url];
        }
    }
    return validURLs;
}

- (BOOL)isValidDragForInfo:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];

    if (![pboard.types containsObject:NSPasteboardTypeFileURL]) {
        return NO;
    }

    NSArray<NSURL *> *urls = [self imageURLsFromPasteboard:pboard];
    return urls.count > 0;
}

- (NSArray<NSURL *> *)imageURLsFromDraggingInfo:(id<NSDraggingInfo>)sender {
    return [self imageURLsFromPasteboard:[sender draggingPasteboard]];
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([self isValidDragForInfo:sender]) {
        [self setHighlighted:YES];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    if ([self isValidDragForInfo:sender]) {
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    [self setHighlighted:NO];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    return [self isValidDragForInfo:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls = [self imageURLsFromDraggingInfo:sender];

    if (urls.count > 0 && self.delegate &&
        [self.delegate respondsToSelector:@selector(dropZoneView:didReceiveImageURLs:)]) {
        [self.delegate dropZoneView:self didReceiveImageURLs:urls];
        return YES;
    }
    return NO;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    [self setHighlighted:NO];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Draw dashed border when empty
    if (self.thumbnailView.hidden && !self.isHighlighted) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 1, 1)
                                                             xRadius:8
                                                             yRadius:8];
        CGFloat dashPattern[] = {6.0, 4.0};
        [path setLineDash:dashPattern count:2 phase:0];
        [[NSColor separatorColor] setStroke];
        path.lineWidth = 2.0;
        [path stroke];
    }
}

@end
