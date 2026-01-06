---
status: pending
priority: p2
issue_id: "007"
tags: [code-review, security, validation]
dependencies: []
---

# Path Traversal Vulnerability

## Problem Statement

Output filenames are derived from input filenames without sanitization. An attacker could craft a filename with path traversal sequences (e.g., `../../../etc/file`) to write files outside the intended output directory.

**Why it matters:** Could overwrite system files or write to unintended locations.

## Findings

- **Location:** `ITBMainWindowController.m` - `exportItem:toURL:`
- **Evidence:** `item.filename` used directly in path construction
- **Risk Level:** MEDIUM - Requires malicious input file

## Proposed Solutions

### Option A: Sanitize Filename (Recommended)
```objc
- (NSString *)sanitizedFilename:(NSString *)filename {
    // Remove path components
    NSString *name = [filename lastPathComponent];
    // Remove dangerous characters
    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/:"];
    name = [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
    return name;
}
```

**Pros:** Simple, effective
**Cons:** May alter some filenames
**Effort:** Small
**Risk:** None

### Option B: Validate Output Path
Verify final path is within intended directory.

**Pros:** Defense in depth
**Cons:** Requires canonicalization
**Effort:** Medium
**Risk:** None

## Recommended Action

_To be filled during triage_

## Technical Details

**Affected Files:**
- `ITBMainWindowController.m`

## Acceptance Criteria

- [ ] Filenames sanitized before use
- [ ] Path traversal sequences rejected/removed
- [ ] Valid filenames unchanged

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-06 | Created from code review | Security-sentinel flagged path traversal |

## Resources

- [OWASP Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal)
