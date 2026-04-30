# Code Simplifier Skill

Use this skill when you have functional code that needs refactoring to improve readability, reduce complexity, or eliminate redundancy.

## Cardinal Rule
**Preserve exact functionality.** You must never change *what* the code does, only *how* it does it. All original features, outputs, and behaviors must remain intact.

## Simplification Checklist
1. **Dead Code Removal:** Identify and delete unused variables, functions, imports, or unreachable code blocks.
2. **Flatten Nesting:** Reduce cognitive load by converting deeply nested conditionals (typically >3 levels) into early returns or guard clauses.
3. **Extract Duplication:** Identify repetitive logic (3+ occurrences) and consolidate it into reusable functions or constants.
4. **Normalize Naming:** Fix inconsistent variable or function names to align with project conventions and improve self-documentation.
5. **Reduce Complexity:** Break down "god functions" or overly complex expressions into smaller, more manageable pieces.
6. **Clean Diffs:** After long coding sessions, normalize the code to ensure the final diff is clean and easy for humans to review.

## Operational Constraints
- **No Logic Changes:** Do not modify business logic or fix bugs (unless the bug is a direct result of the simplification).
- **No New Features:** Do not add functionality or "just-in-case" abstractions.
- **Atomic Changes:** Focus on one type of simplification at a time to ensure safety and reviewability.
- **Test-Driven Verification:**
    1. Run existing tests to establish a baseline.
    2. Apply refactoring.
    3. Run tests again to verify no regressions.
    4. **Revert immediately** if any tests fail.
