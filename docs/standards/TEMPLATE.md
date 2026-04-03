---
status: "{draft | accepted | deprecated}"
date: "{YYYY-MM-DD}"
decision: "{ADR-NNNN or none}"
scope: "{what files, resources, or components this standard applies to}"
enforcement: "{tool/hook that checks compliance, or 'manual'}"
---

# {Standard title}

## Rule

{State the standard as one or more unambiguous, testable rules. Each rule should be either compliant or not — no "should consider" or "where possible".}

## Rationale

{Brief explanation of why this standard exists. Link to the parent decision for full context if applicable.}

## Scope

{Describe what this standard applies to: file types, resource types, services, environments, etc.}

## Examples

### Compliant

```text
{Example of correct usage}
```

### Non-compliant

```text
{Example of incorrect usage}
```

## Enforcement

{How this standard is checked: linter config, CI check, pre-commit hook, agent instruction, or manual review. Include tool names and configuration references where applicable.}

## Exceptions

{Any known exceptions to this standard, and the conditions under which they apply. If none, state "None."}
