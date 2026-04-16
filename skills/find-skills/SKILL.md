# Find Repo Skills

This skill helps you discover and apply existing guidelines from the `skills/` directory of this repository.

## When to Use

**ALWAYS** use this skill as your first step for EVERY task. You must proactively identify if specialized rules exist for the domain you are working on.

## Protocol for Discovery

### Step 1: List Available Skills
List the subdirectories in the `skills/` folder to see what specialized domains are covered.

### Step 2: Match Task to Domain
Identify the primary and secondary domains of your current task.
- Is it Flutter UI? -> `flutter-theming-apps`, `flutter-building-layouts`
- Is it Data/Persistence? -> `flutter-working-with-databases`, `flutter-caching-data`
- Is it Firebase? -> `flutter-firebase`
- Is it Architecture/State? -> `flutter-architecting-apps`, `flutter-managing-state`

### Step 3: Read and Apply
For every matched domain:
1. Read the `SKILL.md` file in the corresponding folder.
2. Explicitly acknowledge the skill: "Applying protocol from `skills/[skill-folder]/SKILL.md`".
3. Integrate the skill's instructions into your plan.

## Mandatory Skills for Flutter Tasks
If you are working on any Flutter code, you **MUST** review:
- `flutter-architecting-apps`
- `flutter-theming-apps` (if UI involved)
- `flutter-testing-apps` (for verification)
