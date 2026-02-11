---
description: Application architecture and separation of concerns
---

# Application Architecture

## Core Principles
* **Separation of Concerns:** Aim for defined roles: properties (Model), presentation (View), and logic (ViewModel/Controller).
* **Logical Layers:**
    * **Presentation:** Widgets, screens, handling user input.
    * **Domain:** Business logic, entities, use cases.
    * **Data:** Model classes, API clients, repositories.
    * **Core:** Shared classes, utilities, extensions.

## Organization
* **Feature-based:** Organize code by feature (e.g., `lib/features/login/`), containing its own presentation, domain, and data subfolders.
* **Scalability:** This structure improves navigability and scalability for larger projects.

## State Management
* **Separation:** Separate ephemeral state (UI) from app state (Business Logic).
* **Built-in:** Prefer built-in solutions (`ValueNotifier`, `ChangeNotifier`) unless a specific package (like BLoC or Provider) is requested/established.
* **Dependency Injection:** Use manual constructor injection to make dependencies explicit. Use `provider` if DI beyond constructor injection is needed.

## Data Flow
* **Data Structures:** Define classes to represent data.
* **Abstraction:** Abstract data sources behind Repositories/Services to promote testability.
