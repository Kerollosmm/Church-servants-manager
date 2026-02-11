---
description: Code quality, naming, and Dart language standards
---

# Code Quality & Standards

## Code Structure
* **Separation of Concerns:** Adhere to maintainable code structure (e.g., UI logic separate from business logic).
* **Conciseness:** Write code that is as short as it can be while remaining clear.
* **Simplicity:** Write straightforward code. Code that is clever or obscure is difficult to maintain.
* **Error Handling:** Anticipate and handle potential errors. Don't let your code fail silently.

## Naming Conventions
* **General:** Avoid abbreviations and use meaningful, consistent, descriptive names.
* **Casing:**
    * Use `PascalCase` for classes.
    * Use `camelCase` for members, variables, functions, and enums.
    * Use `snake_case` for files.

## Functions
* **Size:** Keep functions short and with a single purpose (strive for less than 20 lines).
* **Arrow Functions:** Use arrow syntax for simple one-line functions.

## Logging
* **Package:** Use the `logging` package instead of `print` for general logging, or `dart:developer` for structured logging.

## Styling
* **Line Length:** Lines should be 80 characters or fewer.

# Dart Best Practices

* **Effective Dart:** Follow the official [Effective Dart guidelines](https://dart.dev/effective-dart).
* **Async/Await:**
    * Use `Future`, `async`, and `await` for asynchronous operations.
    * Use `Stream` for sequences of asynchronous events.
    * Ensure robust error handling.
* **Null Safety:** Write soundly null-safe code. Avoid `!` unless the value is guaranteed to be non-null.
* **Pattern Matching:** Use pattern matching features where they simplify the code.
* **Records:** Use records to return multiple types when defining a class is cumbersome.
* **Switch Statements:** Prefer exhaustive `switch` statements or expressions (no `break` needed).
* **Exception Handling:** Use `try-catch` blocks with specific exceptions. Use custom exceptions for domain-specific errors.
* **Comments:**
    * Write clear comments for complex code.
    * Avoid over-commenting or trailing comments.
    * Documentation should precede metadata annotations.

## Class & Library Organization
* **Classes:** Define related classes within the same library file.
* **Exports:** For large libraries, export smaller, private libraries from a single top-level library.
* **Folders:** Group related libraries in the same folder.
