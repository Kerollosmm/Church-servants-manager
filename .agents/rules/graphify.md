---
trigger: always_on
description: Consult the graphify knowledge graph at graphify-out/ for codebase and architecture questions.
---

## graphify

Project has graphify knowledge graph at graphify-out/.

Rules:
- For codebase/architecture questions, when `graphify-out/graph.json` exists, first run `graphify query "<question>"` (CLI) or `query_graph` (MCP). Use `graphify path "<A>" "<B>"` / `shortest_path` for relations, `graphify explain "<concept>"` / `get_node` for focused concepts. Return scoped subgraph, smaller than `GRAPH_REPORT.md` or raw grep.
- If graphify-out/wiki/index.md exists, navigate instead of reading raw files.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain lack context.
- After modifying code files, run `graphify update .` to keep graph current (AST-only, no API cost).
