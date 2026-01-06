---
status: pending
priority: p2
issue_id: "005"
tags: [code-review, performance, concurrency]
dependencies: ["003"]
---

# Serial Batch Processing

## Problem Statement

Batch export processes images serially, not utilizing available CPU cores. Modern Macs have 8+ cores that could process images in parallel, significantly reducing export time.

**Why it matters:** Exporting 100 images takes 10x longer than necessary on a multi-core machine.

## Findings

- **Location:** `ITBMainWindowController.m` - `batchExportToFolder:`
- **Evidence:** Images processed one at a time in loop
- **Risk Level:** MEDIUM - Slow batch operations

## Proposed Solutions

### Option A: Concurrent Dispatch Queue
```objc
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_apply(self.sourceItems.count, queue, ^(size_t index) {
    ITBSourceItem *item = self.sourceItems[index];
    [self exportItem:item toFolder:folderURL];
});
```

**Pros:** Automatic parallelization
**Cons:** Need thread-safe progress tracking
**Effort:** Small
**Risk:** Low

### Option B: NSOperationQueue with Concurrency Limit
```objc
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
queue.maxConcurrentOperationCount = 4; // Limit parallelism
```

**Pros:** Controllable parallelism
**Cons:** More code
**Effort:** Medium
**Risk:** Low

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBMainWindowController.m`

## Acceptance Criteria

- [ ] Batch export uses multiple cores
- [ ] Progress tracking remains accurate
- [ ] No race conditions in file writing

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Performance-oracle flagged serial processing |

## Resources

- [Concurrency Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/)
