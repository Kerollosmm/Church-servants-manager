---
name: flutter-layouts
description: Best practices for building flexible, responsive, and overflow-safe layouts
license: Private
---

# Flutter Layouts

## Rows and Columns
* **Expanded:** Fill remaining space along main axis.
* **Flexible:** Shrink to fit, but don't force grow. Do NOT combine `Flexible` and `Expanded` in the same Flex widget.
* **Wrap:** Use when items might overflow the line.

## General Content
* **SingleChildScrollView:** For fixed-size content that exceeds viewport.
* **ListView/GridView:** ALWAYS use `.builder` for long/dynamic lists.
* **FittedBox:** Scale a single child to fit parent.
* **LayoutBuilder:** Decision making based on available space.

## Stack & Layering
* **Positioned:** Anchor to edges.
* **Align:** Position using coordinate alignment.
* **OverlayPortal:** Show UI elements (dropdowns, tooltips) on top of everything.

```dart
// OverlayPortal Example
OverlayPortal(
  controller: _controller,
  overlayChildBuilder: (context) => Positioned(child: MyTooltip()),
  child: MyButton(),
)
```
