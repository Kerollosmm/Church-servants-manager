---
description: Create new application command. Triggers App Builder skill and starts interactive dialogue with user.
---

# /create - Create Application

$ARGUMENTS

---

## Task

This command starts a new application creation process.

### Steps:

1. **Request Analysis**
   - Understand what the user wants
   - If information is missing, use `conversation-manager` agent to ask

2. **Project Planning**
   - Use `project-planner` agent for task breakdown
   - Determine tech stack
   - Plan file structure
   - Create plan file and proceed to building

3. **Approval**
   Present the plan to the user (or team lead) and get explicit sign-off before building:
   - **Who approves:** Project owner or requesting developer.
   - **How:** Confirm "Y" in the chat, merge the plan PR, or mark the ticket as "Approved".
   - **Criteria:** Plan includes tech stack, file structure, and estimated scope.
   - **When:** Approval must happen *before* any code is written.
   When approved, proceed to Application Building.

4. **Application Building (After Approval)**
   - Orchestrate with `app-builder` agent
   - Coordinate expert agents:
     - `database-architect` → Schema
     - `backend-specialist` → API
     - `frontend-specialist` → UI

4. **Preview**
   - Start with `auto_preview.py` when complete
   - Present URL to user

---

## Usage Examples

```
/create blog site
/create e-commerce app with product listing and cart
/create todo app
/create Instagram clone
/create crm system with customer management
```

---

## Before Starting

If request is unclear, ask these questions:
- What type of application?
- What are the basic features?
- Who will use it?

Use the following defaults when information is not provided:

| Setting | Default Value |
|---------|--------------|
| Branch | `main` |
| License | MIT |
| Visibility | private |
| CI | enabled (basic lint + test script) |
| Package manager | npm (web) / pub (Flutter) |

To update defaults after creation:
- Edit `package.json` (web) or `pubspec.yaml` (Flutter) for project metadata.
- Update `.github/workflows/` for CI/CD configuration.
- Run `/enhance` to add features iteratively.
- Open a PR to update settings reviewed by the team.
