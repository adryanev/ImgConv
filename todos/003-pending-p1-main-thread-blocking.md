---
status: pending
priority: p1
issue_id: "003"
tags: [code-review, performance, threading, ux]
dependencies: []
---

# Main Thread Blocking During Batch Export

## Problem Statement

The batch export process blocks the main thread with `dispatch_group_wait`, causing the UI to freeze during export operations. This provides poor user experience and can trigger macOS "app not responding" warnings.

**Why it matters:** Users can't cancel, see progress, or interact with the app during export. Long exports may cause the system to force-quit the app.

## Findings

- **Location:** `ITBMainWindowController.m` - `batchExportToFolder:` method
- **Evidence:** `dispatch_group_wait(group, DISPATCH_TIME_FOREVER)` blocks main thread
- **Risk Level:** HIGH - Poor UX, potential force-quit

## Proposed Solutions

### Option A: Use dispatch_group_notify (Recommended)
```objc
- (void)batchExportToFolder:(NSURL *)folderURL {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    __block NSInteger completed = 0;
    __block NSInteger failed = 0;

    for (ITBSourceItem *item in self.sourceItems) {
        dispatch_group_enter(group);
        dispatch_async(queue, ^{
            // Process item
            dispatch_async(dispatch_get_main_queue(), ^{
                completed++;
                [self updateBatchProgress:completed total:self.sourceItems.count];
            });
            dispatch_group_leave(group);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self batchExportCompleted:completed failed:failed];
    });
}
```

**Pros:** Non-blocking, responsive UI, allows cancel
**Cons:** Slightly more complex
**Effort:** Medium
**Risk:** Low

### Option B: NSOperationQueue with Progress
Use NSOperationQueue for better cancellation and progress tracking.

**Pros:** Built-in cancellation, dependencies support
**Cons:** More refactoring needed
**Effort:** Large
**Risk:** Medium

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBMainWindowController.m`

**Components:**
- Batch export
- Progress UI

## Acceptance Criteria

- [ ] UI remains responsive during export
- [ ] Progress updates smoothly
- [ ] Cancel button works if implemented
- [ ] No "app not responding" warnings

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Performance-oracle flagged main thread blocking |

## Resources

- [GCD Best Practices](https://developer.apple.com/documentation/dispatch)
