---
status: pending
priority: p2
issue_id: "009"
tags: [code-review, architecture, maintainability]
dependencies: []
---

# Controller Bloat (1000+ Lines)

## Problem Statement

ITBMainWindowController has grown to over 1000 lines, handling UI setup, file management, conversion logic, progress tracking, and export operations. This violates single responsibility principle and makes the code difficult to maintain.

**Why it matters:** Large controllers are hard to test, modify, and understand.

## Findings

- **Location:** `ITBMainWindowController.m`
- **Evidence:** 1000+ lines, multiple responsibilities
- **Risk Level:** MEDIUM - Maintainability concern

## Proposed Solutions

### Option A: Extract Coordinator Classes
```objc
@interface ITBBatchExportCoordinator : NSObject
- (void)exportItems:(NSArray<ITBSourceItem *> *)items
           toFolder:(NSURL *)folder
         completion:(void(^)(NSInteger success, NSInteger failed))completion;
@end

@interface ITBFileDropCoordinator : NSObject <ITBDropZoneViewDelegate>
// Handle all file drop logic
@end
```

**Pros:** Clear separation, testable
**Cons:** More files
**Effort:** Large
**Risk:** Medium

### Option B: Extract Helper Methods
Move related methods to categories.

**Pros:** Less restructuring
**Cons:** Still in same file
**Effort:** Medium
**Risk:** Low

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBMainWindowController.m`

**Potential New Files:**
- `ITBBatchExportCoordinator.h/m`
- `ITBFileDropCoordinator.h/m`
- `ITBUISetupHelper.h/m`

## Acceptance Criteria

- [ ] Controller under 500 lines
- [ ] Clear responsibility boundaries
- [ ] All tests still pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Architecture-strategist flagged controller size |

## Resources

- [Massive View Controller Refactoring](https://www.objc.io/issues/1-view-controllers/)
