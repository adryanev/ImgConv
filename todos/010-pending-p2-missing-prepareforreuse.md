---
status: pending
priority: p2
issue_id: "010"
tags: [code-review, ui, collection-view]
dependencies: []
---

# Missing prepareForReuse in Collection View Cells

## Problem Statement

ITBThumbnailCell and ITBAddButtonCell don't implement `prepareForReuse`. When cells are recycled, stale data (images, handlers) may persist, causing visual glitches or incorrect behavior.

**Why it matters:** Can show wrong thumbnails or trigger wrong remove handlers when scrolling.

## Findings

- **Location:** `ITBThumbnailGridView.m` - ITBThumbnailCell, ITBAddButtonCell
- **Evidence:** No `prepareForReuse` implementation
- **Risk Level:** MEDIUM - Visual/behavioral bugs

## Proposed Solutions

### Option A: Implement prepareForReuse (Recommended)
```objc
- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumbnailImageView.image = nil;
    self.filenameLabel.stringValue = @"";
    self.sourceItem = nil;
    self.removeHandler = nil;
}
```

**Pros:** Prevents stale data
**Cons:** None
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBThumbnailGridView.m`

## Acceptance Criteria

- [ ] prepareForReuse implemented for both cell types
- [ ] No stale images when scrolling
- [ ] Handlers cleared on reuse

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Pattern-recognition-specialist flagged missing method |

## Resources

- [NSCollectionViewItem prepareForReuse](https://developer.apple.com/documentation/appkit/nscollectionviewitem/1528229-prepareforreuse)
