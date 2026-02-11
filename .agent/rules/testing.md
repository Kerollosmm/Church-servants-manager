---
description: Testing guidelines and strategies
---

# Testing Guidelines

## Tools & Packages
* **Unit Tests:** `package:test`
* **Widget Tests:** `package:flutter_test`
* **Integration Tests:** `package:integration_test` (add via `dev_dependencies` with `sdk: flutter`).
* **Assertions:** Prefer `package:checks` for expressive assertions.
* **Mocks:** Prefer fakes/stubs. If mocks are needed, use `mockito` or `mocktail`.

## Strategy
* **AAA Pattern:** Follow Arrange-Act-Assert (or Given-When-Then).
* **Coverage:** Aim for high test coverage.
    * **Unit:** Domain logic, data layer, state management.
    * **Widget:** UI components.
    * **Integration:** End-to-end user flows.
* **Injection:** Design code to be testable (dependency injection) so in-memory/fake versions can be used.
