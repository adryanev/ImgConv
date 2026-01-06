---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, security, threading, concurrency]
dependencies: []
---

# Thread Safety Issue with lockFocus

## Problem Statement

The thumbnail generation code uses `lockFocus`/`unlockFocus` on background threads via `dispatch_async`. NSImage's `lockFocus` is not thread-safe and can cause crashes or visual corruption when called from non-main threads.

**Why it matters:** Race conditions can cause random crashes, corrupted thumbnails, or memory corruption that's difficult to debug.

## Findings

- **Location:** `ITBSourceItem.m` - `generateThumbnail` method (if using lockFocus)
- **Location:** `ITBMainWindowController.m` - batch processing with dispatch_async
- **Evidence:** lockFocus called within dispatch_async blocks
- **Risk Level:** HIGH - Can cause crashes

## Proposed Solutions

### Option A: Use NSGraphicsContext (Recommended)
```objc
- (NSImage *)generateThumbnailFromImage:(NSImage *)image {
    NSImage *thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(80, 80)];
    [thumbnail lockFocusFlipped:NO];

    // Must be called on main thread OR use:
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
        pixelsWide:80
        pixelsHigh:80
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace
        bytesPerRow:0
        bitsPerPixel:0];

    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:ctx];
    // Draw image
    [NSGraphicsContext restoreGraphicsState];

    thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(80, 80)];
    [thumbnail addRepresentation:rep];
    return thumbnail;
}
```

**Pros:** Thread-safe, modern API
**Cons:** Slightly more verbose
**Effort:** Medium
**Risk:** Low

### Option B: Dispatch to Main Thread
Perform all thumbnail generation on main thread.

**Pros:** Simple fix
**Cons:** Slower for batch operations
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBSourceItem.m`
- `ITBMainWindowController.m`

**Components:**
- Thumbnail generation
- Batch processing

## Acceptance Criteria

- [ ] No lockFocus calls on background threads
- [ ] Thumbnail generation works correctly in batch mode
- [ ] No crashes when processing 50+ images

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Performance-oracle and security agents flagged threading issue |

## Resources

- [Apple Thread Safety Summary](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/ThreadSafetySummary/ThreadSafetySummary.html)
