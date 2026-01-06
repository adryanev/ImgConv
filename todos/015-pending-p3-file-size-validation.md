---
status: pending
priority: p3
issue_id: "015"
tags: [code-review, validation, security]
dependencies: []
---

# Missing File Size Validation

## Problem Statement

No maximum file size check before loading images into memory. Extremely large files could exhaust memory.

**Why it matters:** Defense against resource exhaustion.

## Findings

- **Location:** `ITBSourceItem.m` - file loading
- **Evidence:** No size check before loading
- **Risk Level:** LOW - Edge case

## Proposed Solutions

### Option A: Add Size Limit
```objc
static const NSUInteger kMaxFileSizeBytes = 100 * 1024 * 1024; // 100MB

- (BOOL)loadWithError:(NSError **)error {
    NSDictionary *attrs = [[NSFileManager defaultManager]
        attributesOfItemAtPath:self.url.path error:nil];
    NSNumber *fileSize = attrs[NSFileSize];

    if (fileSize.unsignedIntegerValue > kMaxFileSizeBytes) {
        if (error) {
            *error = [NSError errorWithDomain:@"ITBErrorDomain"
                                        code:101
                                    userInfo:@{NSLocalizedDescriptionKey: @"File too large"}];
        }
        return NO;
    }
    // Continue loading...
}
```

**Pros:** Prevents memory exhaustion
**Cons:** May reject legitimate large files
**Effort:** Small
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBSourceItem.m`

## Acceptance Criteria

- [ ] Files over limit rejected with clear error
- [ ] Reasonable limit (100MB suggested)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Security-sentinel flagged missing validation |

## Resources

- None
