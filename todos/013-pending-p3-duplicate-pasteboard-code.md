---
status: pending
priority: p3
issue_id: "013"
tags: [code-review, cleanup, duplication]
dependencies: []
---

# Duplicate Pasteboard Extraction Code

## Problem Statement

The code to extract URLs from NSDraggingInfo/NSPasteboard is duplicated in multiple places within ITBDropZoneView.

**Why it matters:** Code duplication increases maintenance burden and bug risk.

## Findings

- **Location:** `ITBDropZoneView.m`
- **Evidence:** URL extraction logic repeated
- **Risk Level:** LOW - Code quality

## Proposed Solutions

### Option A: Extract Helper Method
```objc
- (NSArray<NSURL *> *)imageURLsFromDraggingInfo:(id<NSDraggingInfo>)info {
    NSPasteboard *pb = info.draggingPasteboard;
    NSArray *urls = [pb readObjectsForClasses:@[[NSURL class]]
                                      options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    return [self filterValidImageURLs:urls];
}
```

**Pros:** DRY, single source of truth
**Cons:** None
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBDropZoneView.m`

## Acceptance Criteria

- [ ] URL extraction in single method
- [ ] All callers use shared method

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Pattern-recognition-specialist flagged duplication |

## Resources

- None
