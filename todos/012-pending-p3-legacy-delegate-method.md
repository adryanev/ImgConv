---
status: pending
priority: p3
issue_id: "012"
tags: [code-review, cleanup, api]
dependencies: []
---

# Legacy Single-URL Delegate Method

## Problem Statement

ITBDropZoneViewDelegate still has the old single-URL method `dropZoneView:didReceiveImageAtURL:` alongside the new multi-URL method. This creates confusion and maintenance burden.

**Why it matters:** Code clarity and maintenance.

## Findings

- **Location:** `ITBDropZoneView.h`
- **Evidence:** Both old and new delegate methods exist
- **Risk Level:** LOW - Cleanup

## Proposed Solutions

### Option A: Remove Legacy Method
Delete the old single-URL method if no longer used.

**Pros:** Clean API
**Cons:** Breaking change if used
**Effort:** Small
**Risk:** Low

### Option B: Mark Deprecated
```objc
- (void)dropZoneView:(ITBDropZoneView *)view
 didReceiveImageAtURL:(NSURL *)url
 __attribute__((deprecated("Use didReceiveImageURLs: instead")));
```

**Pros:** Gradual migration
**Cons:** Still in codebase
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBDropZoneView.h`
- `ITBDropZoneView.m`

## Acceptance Criteria

- [ ] Legacy method removed or deprecated
- [ ] All callers updated

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Code-simplicity-reviewer flagged legacy API |

## Resources

- None
