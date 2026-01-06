---
status: pending
priority: p3
issue_id: "014"
tags: [code-review, validation, xml]
dependencies: []
---

# Unvalidated XML Path Data

## Problem Statement

SVG path data from XML parsing is used without validation. Malformed path data could cause parsing errors or unexpected behavior.

**Why it matters:** Robustness against malformed input.

## Findings

- **Location:** `ITBVectorDocument.m` - path parsing
- **Evidence:** Path 'd' attribute used directly
- **Risk Level:** LOW - May cause parse errors

## Proposed Solutions

### Option A: Add Path Validation
```objc
- (BOOL)isValidPathData:(NSString *)pathData {
    // Basic validation of path commands
    NSRegularExpression *regex = [NSRegularExpression
        regularExpressionWithPattern:@"^[MmZzLlHhVvCcSsQqTtAa0-9\\s.,+-]+$"
        options:0 error:nil];
    return [regex numberOfMatchesInString:pathData
                                  options:0
                                    range:NSMakeRange(0, pathData.length)] > 0;
}
```

**Pros:** Catches malformed data early
**Cons:** May reject edge cases
**Effort:** Small
**Risk:** Low

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBVectorDocument.m`

## Acceptance Criteria

- [ ] Invalid path data logged/rejected gracefully
- [ ] Valid paths still work

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Security-sentinel flagged input validation |

## Resources

- [SVG Path Specification](https://www.w3.org/TR/SVG/paths.html)
