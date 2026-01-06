---
status: pending
priority: p2
issue_id: "008"
tags: [code-review, error-handling, debugging]
dependencies: []
---

# Silent Error Suppression

## Problem Statement

Errors during file loading and conversion are silently suppressed with empty catch blocks or nil error pointers. This makes debugging difficult and hides potential issues from users.

**Why it matters:** Users don't know why operations fail; developers can't diagnose issues.

## Findings

- **Location:** Multiple files - error handling code
- **Evidence:** `NSError **error` passed as nil, errors not logged
- **Risk Level:** MEDIUM - Difficult debugging

## Proposed Solutions

### Option A: Comprehensive Error Handling
```objc
- (BOOL)loadWithError:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:self.url options:0 error:error];
    if (!data) {
        if (error && *error == nil) {
            *error = [NSError errorWithDomain:@"ITBErrorDomain"
                                        code:100
                                    userInfo:@{NSLocalizedDescriptionKey: @"Failed to read file"}];
        }
        return NO;
    }
    return YES;
}
```

**Pros:** Proper error propagation
**Cons:** More code
**Effort:** Medium
**Risk:** Low

### Option B: Logging Layer
Add OSLog for all operations.

**Pros:** Visible in Console.app
**Cons:** Doesn't fix user feedback
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBSourceItem.m`
- `ITBMainWindowController.m`
- `ITBImageConverter.m`

## Acceptance Criteria

- [ ] All errors logged with context
- [ ] User sees meaningful error messages
- [ ] Batch operations report which files failed

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Pattern-recognition-specialist flagged error handling |

## Resources

- [Error Handling Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/)
