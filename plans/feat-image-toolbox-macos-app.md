# feat: Image Toolbox - macOS Image Converter for Mobile Developers

**Created**: 2026-01-06
**Type**: New Application
**Platform**: macOS 11+ (Big Sur) - Native Cocoa / Objective-C
**Status**: Planning (Simplified after review)

---

## Overview

Build a native macOS single-window application for mobile developers that converts images between PNG, JPEG, and WebP formats with a drag-and-drop interface. Future versions will add iOS multi-resolution asset generation and vector format support.

## Problem Statement

Mobile developers need to quickly convert image formats without opening heavy design tools. This lightweight native app solves that with drag-drop simplicity.

---

## Scope: What's In vs Out

### v1.0 (This Plan)
- [x] PNG ↔ JPEG ↔ WebP conversion
- [x] Quality slider for lossy formats
- [x] Background color picker for alpha → JPEG
- [x] Single-file drag-and-drop
- [x] Standard save dialog

### v1.1 (Future)
- [ ] iOS multi-resolution (@1x, @2x, @3x) generation
- [ ] Batch processing multiple files

### v2.0 (Future - Only If Requested)
- [ ] SVG → raster conversion
- [ ] Android Vector Drawable support
- [ ] Menu bar app mode

---

## Technical Approach

### Architecture: Keep It Simple

```
┌────────────────────────────────────────┐
│         Image Toolbox.app              │
├────────────────────────────────────────┤
│  ITBMainWindowController               │
│  ├── Drop zone (accepts images)        │
│  ├── Format selector (PNG/JPEG/WebP)   │
│  ├── Quality slider                    │
│  ├── Color picker (alpha → JPEG)       │
│  └── Save button                       │
├────────────────────────────────────────┤
│  ITBImageConverter                     │
│  └── Uses native ImageIO framework     │
└────────────────────────────────────────┘
```

**No external dependencies for v1.** macOS 11+ has native WebP support via ImageIO.

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| WebP Library | Native ImageIO | macOS 11+ supports WebP natively |
| Class Count | 2 classes | One controller, one converter |
| UI Layout | Single column | Drop zone → options → save |
| Batch Processing | Deferred | Single file solves 80% of use cases |

---

## Implementation: Single Phase

### Deliverables

- [ ] Xcode project with sandbox entitlements
- [ ] `ITBMainWindowController` - Window with drag-drop and controls
- [ ] `ITBImageConverter` - PNG/JPEG/WebP conversion using ImageIO
- [ ] Proper error handling with `NSError **` on all methods
- [ ] Quality slider (0-100%) for JPEG/WebP
- [ ] Color picker for alpha channel compositing
- [ ] Basic unit tests for conversion logic

### File Structure (4 Source Files)

```
ImageToolbox/
├── ImageToolbox.xcodeproj
├── ImageToolbox/
│   ├── main.m
│   ├── AppDelegate.h
│   ├── AppDelegate.m
│   ├── ITBMainWindowController.h
│   ├── ITBMainWindowController.m
│   ├── ITBImageConverter.h
│   ├── ITBImageConverter.m
│   ├── Resources/
│   │   ├── MainMenu.xib
│   │   └── Assets.xcassets
│   └── Supporting Files/
│       ├── Info.plist
│       └── ImageToolbox.entitlements
└── ImageToolboxTests/
    └── ITBImageConverterTests.m
```

---

## API Design

### ITBImageConverter.h

```objc
#import <Cocoa/Cocoa.h>

// Error domain and codes
extern NSErrorDomain const ITBImageConverterErrorDomain;

typedef NS_ERROR_ENUM(ITBImageConverterErrorDomain, ITBImageConverterErrorCode) {
    ITBImageConverterErrorUnsupportedFormat = 1001,
    ITBImageConverterErrorEncodingFailed = 1002,
    ITBImageConverterErrorDecodingFailed = 1003,
    ITBImageConverterErrorInvalidInput = 1004,
};

// Supported formats
typedef NS_ENUM(NSInteger, ITBImageFormat) {
    ITBImageFormatPNG,
    ITBImageFormatJPEG,
    ITBImageFormatWebP,
};

@interface ITBImageConverter : NSObject

/// Convert image to specified format
/// @param image Source image (NSImage)
/// @param format Target format (PNG, JPEG, WebP)
/// @param qualityPercent Quality 0-100 (ignored for PNG)
/// @param backgroundColor Background color for alpha compositing (nil = preserve alpha)
/// @param error Error output
/// @return Encoded image data, or nil on failure
- (nullable NSData *)convertImage:(nonnull NSImage *)image
                         toFormat:(ITBImageFormat)format
                   qualityPercent:(NSInteger)qualityPercent
                  backgroundColor:(nullable NSColor *)backgroundColor
                            error:(NSError *_Nullable *_Nullable)error;

/// Check if format is supported for reading
+ (BOOL)canReadFormat:(nonnull NSString *)fileExtension;

/// Check if format is supported for writing
+ (BOOL)canWriteFormat:(ITBImageFormat)format;

/// Get file extension for format
+ (nonnull NSString *)fileExtensionForFormat:(ITBImageFormat)format;

@end
```

### ITBMainWindowController.h

```objc
#import <Cocoa/Cocoa.h>

@interface ITBMainWindowController : NSWindowController

// UI Outlets
@property (weak) IBOutlet NSView *dropZoneView;
@property (weak) IBOutlet NSSegmentedControl *formatSelector;
@property (weak) IBOutlet NSSlider *qualitySlider;
@property (weak) IBOutlet NSTextField *qualityLabel;
@property (weak) IBOutlet NSColorWell *backgroundColorWell;
@property (weak) IBOutlet NSButton *saveButton;
@property (weak) IBOutlet NSImageView *thumbnailView;
@property (weak) IBOutlet NSTextField *statusLabel;

// Actions
- (IBAction)formatChanged:(id)sender;
- (IBAction)qualityChanged:(id)sender;
- (IBAction)saveClicked:(id)sender;

@end
```

---

## UI Layout

```
┌─────────────────────────────────────────────┐
│  Image Toolbox                    [−][□][×] │
├─────────────────────────────────────────────┤
│                                             │
│        ┌─────────────────────┐              │
│        │                     │              │
│        │   Drop Image Here   │              │
│        │        📁           │              │
│        │                     │              │
│        └─────────────────────┘              │
│                                             │
│  Output Format:                             │
│  [ PNG ]  [ JPEG ]  [ WebP ]                │
│                                             │
│  Quality: ━━━━━━━━━━━○━━━━━━  85%           │
│                                             │
│  Background: [■ White]  (for alpha→JPEG)    │
│                                             │
│              [ Convert & Save... ]          │
│                                             │
│  Status: Ready                              │
└─────────────────────────────────────────────┘
```

**Behavior:**
- Quality slider visible only for JPEG/WebP
- Background color picker visible only when source has alpha AND target is JPEG
- Thumbnail shows dropped image
- Status shows "Ready", "Converting...", or error message

---

## Drag-and-Drop Implementation

```objc
// In ITBMainWindowController.m

- (void)setupDropZone {
    [self.dropZoneView registerForDraggedTypes:@[
        NSPasteboardTypeFileURL
    ]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray<NSURL *> *urls = [pboard readObjectsForClasses:@[[NSURL class]]
                                                   options:@{
        NSPasteboardURLReadingFileURLsOnlyKey: @YES,
        NSPasteboardURLReadingContentsConformToTypesKey: @[
            (__bridge NSString *)kUTTypePNG,
            (__bridge NSString *)kUTTypeJPEG,
            @"org.webmproject.webp"
        ]
    }];

    if (urls.count == 1) {
        self.dropZoneView.layer.borderColor = NSColor.systemBlueColor.CGColor;
        self.dropZoneView.layer.borderWidth = 2.0;
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    // Load dropped image, update UI
    NSURL *url = /* extract from pasteboard */;
    self.sourceImage = [[NSImage alloc] initWithContentsOfURL:url];
    self.thumbnailView.image = self.sourceImage;
    self.saveButton.enabled = YES;
    return YES;
}
```

---

## Error Handling

All errors use `ITBImageConverterErrorDomain` with specific codes:

```objc
// Example error creation in ITBImageConverter.m
- (NSData *)convertImage:(NSImage *)image
                toFormat:(ITBImageFormat)format
          qualityPercent:(NSInteger)qualityPercent
         backgroundColor:(NSColor *)backgroundColor
                   error:(NSError **)error {

    if (!image) {
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorInvalidInput
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"No image provided"
            }];
        }
        return nil;
    }

    // ... conversion logic ...

    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:ITBImageConverterErrorDomain
                                         code:ITBImageConverterErrorEncodingFailed
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to encode image",
                NSLocalizedRecoverySuggestionErrorKey: @"Try a different format"
            }];
        }
        return nil;
    }

    return result;
}
```

---

## Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

---

## Acceptance Criteria

### Functional
- [ ] Drop PNG/JPEG/WebP file onto window
- [ ] Select output format (PNG, JPEG, WebP)
- [ ] Adjust quality for JPEG/WebP (0-100%)
- [ ] Pick background color when converting alpha to JPEG
- [ ] Save converted file via standard save dialog
- [ ] Show error alert on conversion failure

### Non-Functional
- [ ] Convert 1000x1000 image in < 500ms
- [ ] Run on macOS 11.0+ (Big Sur and later)
- [ ] Universal Binary (Intel + Apple Silicon)
- [ ] Sandbox compliant

---

## Testing

### Unit Tests (ITBImageConverterTests.m)

```objc
- (void)testPNGToJPEGConversion {
    NSImage *png = [self loadTestImage:@"rgba_test.png"];
    ITBImageConverter *converter = [[ITBImageConverter alloc] init];

    NSError *error;
    NSData *jpegData = [converter convertImage:png
                                      toFormat:ITBImageFormatJPEG
                                qualityPercent:85
                               backgroundColor:[NSColor whiteColor]
                                         error:&error];

    XCTAssertNotNil(jpegData);
    XCTAssertNil(error);
    XCTAssertTrue(jpegData.length > 0);
}

- (void)testInvalidInputReturnsError {
    ITBImageConverter *converter = [[ITBImageConverter alloc] init];

    NSError *error;
    NSData *result = [converter convertImage:nil
                                    toFormat:ITBImageFormatPNG
                              qualityPercent:100
                             backgroundColor:nil
                                       error:&error];

    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, ITBImageConverterErrorInvalidInput);
}
```

### Test Assets
```
ImageToolboxTests/
└── TestAssets/
    ├── rgb_test.png
    ├── rgba_test.png      (with transparency)
    ├── test.jpg
    ├── test.webp
    └── corrupted.png      (for error handling)
```

---

## Conversion Matrix

| Source | → PNG | → JPEG | → WebP |
|--------|-------|--------|--------|
| **PNG** | — | ✅ (alpha→bg) | ✅ |
| **JPEG** | ✅ | — | ✅ |
| **WebP** | ✅ | ✅ (alpha→bg) | — |

---

## Future Roadmap

### v1.1: iOS Multi-Resolution
```objc
// Add to ITBImageConverter
- (NSDictionary<NSString *, NSData *> *)generateIOSAssets:(NSImage *)source
                                                 baseName:(NSString *)name
                                                   format:(ITBImageFormat)format
                                           qualityPercent:(NSInteger)quality
                                                    error:(NSError **)error;
```
- Assumes source is @3x resolution
- Generates: `name.png`, `name@2x.png`, `name@3x.png`
- Uses vImage for high-quality downscaling

### v2.0: Vector Support (Only If Requested)
- Add SVGKit dependency
- SVG → PNG/JPEG/WebP with size presets
- Android Vector Drawable ↔ SVG conversion

---

## References

- [Apple ImageIO Documentation](https://developer.apple.com/documentation/imageio)
- [NSImage Documentation](https://developer.apple.com/documentation/appkit/nsimage)
- [Drag and Drop Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/DragandDrop/)
- [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)

---

## Review Feedback Applied

| Reviewer | Feedback | Applied |
|----------|----------|---------|
| DHH | "Build UI first, not engine-first" | ✅ Single phase, UI+engine together |
| DHH | "Use native ImageIO for WebP" | ✅ No libwebp dependency |
| DHH | "One converter class, not five" | ✅ Single `ITBImageConverter` |
| DHH | "Cut SVG/Android VD from v1" | ✅ Deferred to v2.0 |
| Kieran | "Add NSError ** to all methods" | ✅ Error handling in API |
| Kieran | "Define error domain and codes" | ✅ `ITBImageConverterErrorDomain` |
| Kieran | "Quality parameter ambiguous" | ✅ Now `qualityPercent` (0-100) |
| Simplicity | "4 source files is enough" | ✅ Minimal structure |
| Simplicity | "Cut batch processing" | ✅ Single-file only for v1 |
| Simplicity | "Defer iOS multi-res" | ✅ Moved to v1.1 |
