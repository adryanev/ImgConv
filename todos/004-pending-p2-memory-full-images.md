---
status: pending
priority: p2
issue_id: "004"
tags: [code-review, performance, memory]
dependencies: []
---

# Full Images Retained in Memory

## Problem Statement

ITBSourceItem stores full-resolution images in memory alongside thumbnails. With many large images, this can exhaust available RAM and cause the app to be terminated by the system.

**Why it matters:** Processing 50+ high-resolution images could consume gigabytes of RAM, leading to crashes or system slowdown.

## Findings

- **Location:** `ITBSourceItem.h/m` - `image` property
- **Evidence:** Full NSImage stored permanently in sourceItems array
- **Risk Level:** MEDIUM - Memory pressure with large batches

## Proposed Solutions

### Option A: Lazy Loading with Weak Reference
```objc
@interface ITBSourceItem ()
@property (weak, nonatomic) NSImage *cachedImage;
@end

- (NSImage *)image {
    if (!_cachedImage) {
        _cachedImage = [[NSImage alloc] initWithContentsOfURL:self.url];
    }
    return _cachedImage;
}
```

**Pros:** Memory efficient, automatic cleanup
**Cons:** Re-loads on each access
**Effort:** Medium
**Risk:** Low

### Option B: NSCache for Images
Use NSCache to automatically evict under memory pressure.

**Pros:** System-managed eviction
**Cons:** More infrastructure
**Effort:** Medium
**Risk:** Low

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBSourceItem.h`
- `ITBSourceItem.m`

## Acceptance Criteria

- [ ] Memory usage stays reasonable with 100+ images
- [ ] Images reload correctly when needed
- [ ] No visible performance degradation

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Performance-oracle flagged memory concern |

## Resources

- [Memory Usage Performance Guidelines](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
