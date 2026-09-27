---
name: note-write
description: Create or edit Norg notes in Gabs's notebook using its indentation hierarchy, colon tags, header rules, and writing style. Use whenever asked to write, add, extend, or revise notebook content in a .norg file without performing a comprehensive fact-checking refactor.
---

# Note Write

Create or edit notes using the notebook's current conventions rather than generic Norg style

## Establish Context

1. Resolve the target notebook and file
2. Find the notebook root by walking upward for `STRUCTURE.md`, `TAGS.md`, and `AGENTIC-TAGS.md`
3. For Gabs's main notebook, default to `~/notebook` when no root is given
4. Read `STRUCTURE.md`, `TAGS.md`, and `AGENTIC-TAGS.md` completely before drafting
5. Read the complete target file when editing, including any start-of-file `:cmd` preamble
6. Inspect nearby notes and search for relevant canonical headers when choosing a path or extending an existing subject
7. Follow the target repository's version-control preflight before editing

Ask for a path only when the notebook taxonomy does not provide a reasonable default

## Write

- Follow `STRUCTURE.md` as hard invariants and both tag registries as the complete permitted vocabulary
- Use exactly one `*` for every header and derive child-header depth from indentation
- Keep canonical header names unique within each file
- Prefer familiar compact terms as semantic parents and put their expanded forms beneath `:a`
- Keep expanded terms canonical when their compact forms are obscure or ambiguous
- Allow same-named headers in different files because they may represent different perspectives
- Use registered colon tags only in their permitted positions
- Keep one assertion per prose line
- Preserve technical casing, literals, and relative indentation
- Preserve target text protected by denied `:0` correction metadata
- Preserve the start-of-file `:cmd` preamble unless the request explicitly runs its refactor workflow
- Do not rewrite, complete, grammar-correct, style-correct, fact-check, or discard content beneath `:tmp loose`
- Use `:todo` for explicit missing content rather than empty placeholders
- Reuse an existing relevant note or structure before creating another one
- Keep changes limited to the requested note and context
- Do not normalize unrelated legacy content unless the user asks for a refactor

When adding factual material, do not invent details
Verify facts when the user requests research, the claim is current or consequential, or uncertainty would make the note misleading
Use the `note-refactor` skill instead when the request includes comprehensive cleanup and fact-checking of an existing page

## Verify

Reread the affected structure and check:

- New content belongs to a root header, except the single legal start-of-file `:cmd` preamble
- Any `:cmd` preamble remains first, unique, and contains only registered commands
- Content beneath `:tmp loose` remains unchanged
- Header depth is represented by indentation, never repeated `*`
- No canonical header name is duplicated within the file
- Parent-child relationships are semantically clear
- Every tag and agentic decision marker is registered and correctly placed
- Denied `:0` correction metadata and its protected target remain unchanged
- Prose begins with a capital letter and does not end with a period outside `:pgph` and `@pgph` values
- Technical block delimiters align and baseline content begins two spaces deeper
- `:pgph` and `@pgph` values contain one unbroken physical line and rely on editor soft wrapping
- Structural `:pgph` and `:demo` annotations remain nested beneath their values
- Ranged `@pgph` and `@demo` annotations remain two spaces deeper than their delimiters after `@end`
- Notes describing a technical block remain two spaces deeper than its delimiters after `@end`

Inspect the final diff and summarize only the note content created or changed
