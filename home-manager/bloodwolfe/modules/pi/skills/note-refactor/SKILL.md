---
name: note-refactor
description: Refactor an existing Norg notebook page in explicit soft, hard, or structural mode while following the notebook's structure, semantic-tag, and agentic-tag registries. Use when asked to clean up, reorganize, normalize, fact-check, or comprehensively rewrite a .norg note.
---

# Note Refactor

Refactor the requested page without changing its subject, flattening useful nuance, or laundering uncertainty into confident prose

## Establish Context

1. Resolve the target `.norg` file
2. Find its notebook root by walking upward for `STRUCTURE.md`, `TAGS.md`, and `AGENTIC-TAGS.md`
3. For Gabs's main notebook, default to `~/notebook` when the request omits the root
4. Read `STRUCTURE.md`, `TAGS.md`, `AGENTIC-TAGS.md`, the complete target file, and any directly linked local notes needed for context
5. Read a start-of-file `:cmd` preamble before interpreting the note body
6. Select exactly one refactor mode: use an explicit `::refactor` mode when present, otherwise follow the user's requested mode, otherwise default a general cleanup request to soft
7. Treat sibling commands as additive; for example, `::factcheck file` plus `::refactor soft` means soft mode with a file fact-check
8. Follow the target repository's version-control preflight before editing

Do not rely on remembered notebook rules because these files are authoritative and may change

## Preserve Intent

- Preserve the user's claims, distinctions, examples, commands, links, and useful technical detail even when a claim appears wrong until its correction is approved or directly requested
- Preserve canonical casing and exact spelling inside code, commands, paths, identifiers, URLs, quotations, and other technical literals
- Do not grammar-correct quoted material or executable content
- Merge duplicate canonical headers within the file
- Do not merge same-named headers from different files because cross-file duplicates may represent different perspectives
- Check links and references before renaming a header
- Preserve every existing header as a header unless the user explicitly requests demotion
- Preserve existing inline `<target>` names exactly and do not replace headers with inline targets
- Treat every denied `:0` correction as a lock on its target text and do not re-propose the denied semantic change
- Treat unclear meaning as a question or `:todo`, not an invitation to invent the missing thought
- Treat `:tmp loose` children as writer-owned content: do not rewrite, complete, grammar-correct, style-correct, fact-check, or discard them
- During structural mode only, move loose content unchanged beneath `:tmp loose` for its nearest safe semantic parent; ask rather than guessing when no safe parent exists

## Resolve Agent Interventions

Resolve intervention directives according to the active soft, hard, or structural mode

- Recognize compact `::request` and explicit `:agent request` forms
- Recognize a standalone compact form only when `::` is the first non-whitespace text and no space follows it
- Never interpret `::` inside technical or ranged blocks as an intervention
- Treat standalone `::name` as a request for the matching registered colon tag beneath the nearest semantic parent
- Merge generated content into an existing requested tag rather than creating a duplicate
- Recognize either form when it temporarily replaces another tag's value
- Treat `:1` as acceptance and `:0` as denial when they prefix correction blocks or individual proposals
- Treat bare `::` as an accept-all compatibility value only on `:corrections`
- Interpret the request from its nearest semantic parent, ancestor headers, and surrounding assertions
- Research factual requests with authoritative sources where available
- Replace the directive with the resolved value or requested relevant content
- Add useful source links beneath factual results according to `TAGS.md`
- Preserve passive `::refactor soft` in its start-of-file `:cmd` block
- Consume `::refactor hard`, `::refactor structural`, `::grammarcheck`, `::stylecheck`, `::factcheck file`, and `::restructure` only after their operations succeed
- Remove `:cmd` if consuming transient commands leaves it empty
- Ask the user when a consequential request is ambiguous
- Replace an unresolved minor request with a specific `:todo` rather than guessing

For example, resolve standalone `::history` to a sourced `:history` subtree, or resolve `:y ::year` and `:y :agent year` to the verified contextual year while preserving the `:y` tag

## Allocate Misplaced Content

Resolve `::allocate` during every refactor

- Accept an inline payload after `::allocate ` or the complete child subtree beneath `::allocate`
- Treat angle brackets in `::allocate <note>` as documentation metavariables, not literal syntax, because Norg parses them as inline link targets
- Search the notebook for the most relevant existing file, header, and semantic parent
- Prefer an existing destination over creating a file or header
- Move the smallest complete subtree that preserves the payload and its children
- Preserve wording, tags, headers, technical blocks, inline targets, and links except for required indentation and link-location updates
- Inspect references to moved inline targets and update resolvable links for the destination file without renaming targets
- Merge into matching destination headers or tags when notebook uniqueness rules require it
- Verify the complete payload exists at the destination before removing it and the directive from the source
- Ask the user and leave the directive unchanged when destinations compete or references cannot be updated safely
- Do not fact-check, rewrite, or otherwise refactor payload content merely because it is being allocated

## Review Corrections

Prefer proposing factual or meaning-changing corrections over directly editing the user's assertions

- State the exact existing text and proposed replacement in each correction
- Attach authoritative sources beneath factual proposals where available
- Put a singular `:corrections` block as the final child of the line it targets
- For multiple sibling targets, put one shared correction block as the final child of their semantic parent
- Keep every correction block after all non-correction children in its containing block
- Leave unmarked proposals pending and their targets unchanged
- Treat `:1 corrections` as acceptance of a complete block
- Treat `:1 Proposal text` beneath `:corrections` as acceptance of that proposal only
- Verify accepted proposals, apply them, and remove their consumed entries
- Treat `:0 corrections` as denial of a complete block
- Treat `:0 Proposal text` beneath `:corrections` as denial of that proposal only
- Preserve denied proposals as local metadata and preserve their target text exactly
- Never apply or re-propose a denied semantic change while its `:0` record exists
- Permit repeated `:0` and `:1` markers because each scopes a separate proposal
- Treat `:corrections ::` as an accept-all compatibility form
- Ask the user rather than applying an accepted proposal when verification reveals consequential ambiguity
- Apply spelling, punctuation, and grammar fixes directly only when they preserve meaning and no denial locks the target
- Apply semantic corrections directly only when the user explicitly requests direct correction

## Fact-Check

Run this section only in hard or structural mode, or when the start-of-file `:cmd` block contains the exact command `::factcheck file`
Do not fact-check loose notes
`::factcheck file` is invalid anywhere except as a direct child of the start-of-file `:cmd` block and must be removed after a successful check

1. Identify externally verifiable claims before rewriting them
2. Verify them with current authoritative or primary sources where available
3. Use credible secondary sources when primary sources do not answer the question
4. Compare publication dates and distinguish historical truth from current behavior
5. Propose a supported correction through `:corrections` unless direct correction was explicitly requested or approved
6. For consequential ambiguity or conflicting sources, ask the user before choosing an interpretation
7. For unresolved minor claims, preserve the uncertainty and add a specific `:todo` when useful
8. Retain existing source links and add links beneath corrected or non-obvious claims when they provide useful provenance

Use `web_search` to locate current sources and follow the `web-fetch` skill when full page content is needed
Do not cite search snippets as evidence
Do not silently reduce fact-checking to spelling correction on a large page

## Refactor

- Apply only the operations permitted by the active mode and explicit commands
- Bring touched content into compliance with the current structure and both tag registries
- Use indentation to express semantic parent-child relationships without moving content outside structural mode, except when an explicit `::allocate` directive authorizes that move
- Keep each prose line to one assertion
- Prefer familiar compact terms as semantic parents and place their expanded forms beneath `:a`
- Keep expanded terms canonical when their compact forms are obscure or ambiguous
- Correct spelling, grammar, capitalization, and malformed phrasing without making fragments unnecessarily verbose
- Use only registered tags in their permitted positions
- Keep root and child header names unique within the file
- Prefer deletion of repetition over new explanatory scaffolding
- Preserve technical blocks byte-for-byte unless the user requests a change or a verified technical correction requires one
- Keep block delimiters aligned, code at its relative baseline, and post-block explanatory notes indented as children of the block

## Refactor Modes

### Soft

- Correct grammar, spelling, punctuation, and style only when meaning remains unchanged
- Fulfil applicable agentic directives
- Apply `::grammarcheck` and `::stylecheck` behavior
- Do not fact-check or restructure
- Preserve passive `::refactor soft`

### Hard

- Perform every soft operation
- Fact-check the complete file except loose notes
- Apply `::factcheck file`, `::grammarcheck`, and `::stylecheck` behavior
- Do not restructure except to repair a hard structural violation
- Consume `::refactor hard` after success

### Structural

- Perform every hard operation
- Apply `::restructure`, `::factcheck file`, `::grammarcheck`, and `::stylecheck` behavior
- Identify the broadest coherent concepts that can serve as root headers
- Rebuild the header tree only where placement is materially improved
- Move the smallest complete line, block, or subtree needed and avoid moving coherent content
- Keep independently aggregatable or renderable groups as indented single-`*` child headers
- Re-indent existing headers when needed but do not demote them into ordinary semantic parents
- Preserve canonical header names where possible so links and cross-file aggregation remain stable
- Move loose notes byte-for-byte beneath `:tmp loose` for their nearest safe semantic parent
- Ask the writer when a loose note has no safe parent
- Consume `::refactor structural` after success

## Verify

After editing, reread the complete result and check:

- Every non-blank line belongs to a root header, except the single legal start-of-file `:cmd` preamble
- `:cmd` occurs only once at the start, contains only registered commands, and remains only when it has passive `::refactor soft`
- Exactly one refactor mode governed the edit
- Every header uses one `*` and hierarchy follows indentation
- Canonical header names are unique within the file
- Existing headers remain headers unless demotion was explicitly requested
- Inline `<target>` names and links remain unchanged
- Indentation advances in two-space semantic levels outside technical blocks
- Tags exist in `TAGS.md` or `AGENTIC-TAGS.md` and are legal in their positions
- No tag or semantic parent is empty
- Blank lines occur only where allowed
- Prose begins with a capital letter and does not end with a period outside `:pgph` and `@pgph` values
- Corrected factual claims match the sources consulted
- Singular correction blocks are final children of their targets
- Shared correction blocks are final children of their common semantic parent
- Pending and denied corrections leave their target lines unchanged
- Denied `:0` records remain intact and accepted `:1` entries are consumed
- No approved `:corrections ::` block remains after its proposals are applied
- No transient `::request` or `:agent request` directive remains unresolved
- No successful transient check or refactor command remains
- `::factcheck file` was honored only beneath start-of-file `:cmd` and loose notes were excluded
- Content beneath `:tmp loose` is unchanged except for an allowed structural move
- Every completed allocation exists intact at its destination and no longer remains at its source
- Every unresolved allocation remains untouched and has been presented to the user for a destination decision
- Code, commands, URLs, quotations, and identifiers retain required spelling
- Technical block contents retain their original relative indentation
- `:pgph` and `@pgph` values remain single physical lines with soft wrapping left to the editor
- Structural `:pgph` and `:demo` annotations remain nested beneath their values
- Ranged `@pgph` and `@demo` annotations remain two spaces deeper than their delimiters after `@end`
- Notes describing a technical block remain two spaces deeper than its delimiters after `@end`

Inspect the final diff and report factual corrections, unresolved claims, and the sources used
