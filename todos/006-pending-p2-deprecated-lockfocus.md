---
status: pending
priority: p2
issue_id: "006"
tags: [code-review, deprecation, api]
dependencies: ["002"]
---

# Deprecated lockFocus API Usage

## Problem Statement

The code uses NSImage's `lockFocus`/`unlockFocus` API which is deprecated in macOS 10.14+. Apple recommends using `imageWithSize:flipped:drawingHandler:` or CGContext-based drawing instead.

**Why it matters:** Deprecated APIs may be removed in future macOS versions, causing app breakage.

## Findings

- **Location:** `ITBSourceItem.m`, `ITBMainWindowController.m`
- **Evidence:** Calls to `lockFocus` and `unlockFocus`
- **Risk Level:** MEDIUM - Future compatibility

## Proposed Solutions

### Option A: Use Block-Based Drawing (Recommended)
```objc
NSImage *thumbnail = [NSImage imageWithSize:NSMakeSize(80, 80)
                                    flipped:NO
                             drawingHandler:^BOOL(NSRect dstRect) {
    [sourceImage drawInRect:dstRect];
    return YES;
}];
```

**Pros:** Modern API, cleaner code, thread-safe
**Cons:** Requires macOS 10.8+
**Effort:** Small
**Risk:** None

### Option B: CGContext Direct Drawing
Use Core Graphics directly for full control.

**Pros:** Maximum compatibility
**Cons:** More verbose
**Effort:** Medium
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBSourceItem.m`
- `ITBMainWindowController.m`

## Acceptance Criteria

- [ ] No lockFocus/unlockFocus calls remain
- [ ] Images render correctly
- [ ] No deprecation warnings

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Architecture-strategist flagged deprecated API |

## Resources

- [NSImage Class Reference](https://developer.apple.com/documentation/appkit/nsimage)
