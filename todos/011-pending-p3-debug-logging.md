---
status: pending
priority: p3
issue_id: "011"
tags: [code-review, cleanup, logging]
dependencies: []
---

# Debug Logging in Production

## Problem Statement

DBG macros and NSLog statements are scattered throughout the codebase. These should be removed or converted to proper os_log for production builds.

**Why it matters:** Debug output can leak sensitive info and impact performance.

## Findings

- **Location:** Multiple files
- **Evidence:** DBG(), NSLog() calls
- **Risk Level:** LOW - Cleanup item

## Proposed Solutions

### Option A: Convert to os_log
```objc
#import <os/log.h>
os_log_debug(OS_LOG_DEFAULT, "Processing file: %{public}@", filename);
```

**Pros:** Proper logging, controllable
**Cons:** Requires #import
**Effort:** Small
**Risk:** None

### Option B: Remove Debug Statements
Simply remove all DBG/NSLog calls.

**Pros:** Clean code
**Cons:** Lose debugging ability
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- Various

## Acceptance Criteria

- [ ] No DBG/NSLog in release builds
- [ ] Logging uses os_log if needed

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Code-simplicity-reviewer flagged debug logging |

## Resources

- [Unified Logging](https://developer.apple.com/documentation/os/logging)
