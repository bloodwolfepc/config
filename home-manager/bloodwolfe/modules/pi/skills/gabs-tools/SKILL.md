---
name: gabs-tools
description: Manage Gabs's todos (Taskwarrior), appointments (khal), contacts (khard), notes (~/Atelier/notes), and synchronized email
---

## Syncing vdir-backed data

After creating, editing, moving, or deleting a calendar event or contact backed by vdir, start vdirsyncer so the change propagates:

```bash
systemctl --user start vdirsyncer
```

## Todos (Taskwarrior)

Taskwarrior is the canonical task store. `task` is the CLI; `td` aliases it and
`todo` shows the next-task report. Its data lives in `~/.local/share/task/`.
Normal reports show pending work, so completed tasks stay out of sight.

### Reading

Use exports for reliable, non-interactive agent access. UUIDs are stable; the
numeric IDs shown in reports are not.

```bash
task status:pending export
task project:config status:pending export
task <uuid> export
```

### Projects

Every new task gets a project. Inside a repository, default to its root directory
name unless Gabs names another project:

```bash
root=$(jj root 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null)
project=$(basename "$root")
task add project:"$project" "Task text"
```

Use hierarchical names for established subprojects, such as `config.neovim` or
`learning.nix`. Outside a repository, infer the project from the request; use
`project:inbox` only when there is no honest inference. Do not interrupt a
low-risk task creation merely to ask for a project name.

For a task tied to source code, add `+code` and annotate its location:

```bash
task add project:"$project" +code "Handle empty input"
task rc.confirmation=off +LATEST annotate "src/parser.rs:42"
```

Keep code comments local to the implementation. Do not bulk-import every
`TODO`/`FIXME` comment or create a duplicate Taskwarrior item unless Gabs asks.

### Changing tasks

Inspect first, then target the stable UUID. Disable confirmation only on the
specific mutation so agent commands cannot block on a prompt.

```bash
task rc.confirmation=off <uuid> modify project:config.navi +blocked
task rc.confirmation=off <uuid> annotate "Waiting for replacement hardware"
task rc.confirmation=off <uuid> done
task rc.confirmation=off <uuid> delete
```

Use `+blocked` only for an external dependency, not merely pending work. Use
Taskwarrior priorities `H`, `M`, and `L`; do not invent urgency when Gabs did not
state it.

## Appointments (khal)

Calendar stored as vdir `.ics` files under `~/Calendars/personal/Personal/`. Use `khal`.

```bash
khal list today 2d             # today + next 2 days
khal list 12/06/2026 15/06/2026  # specific date range
khal new                        # create a new event interactively
khal at                         # what's happening right now
khal edit -d "12/06/2026" "Event Title"  # interactively edit/delete an event
khal search "keyword"           # search events
```

**Deleting an event non-interactively:** khal has no `delete` subcommand. Instead, find the `.ics` file and remove it:

```bash
grep -rl "Event Title" ~/Calendars/personal/Personal/
rm /path/to/uid.ics
```

**Deleting a recurring event:** same approach — find the `.ics` containing the `RRULE` and delete it. All instances will vanish.

The underlying sync is done by vdirsyncer. (DAVx5 handles sync on Android.) The vdir is at `~/Calendars/personal/`.

**Cache bust:** khal caches events in `~/.cache/khal/khal.db` and won't pick up manual `.ics` edits. Delete the cache after editing `.ics` files directly:

```bash
rm ~/.cache/khal/khal.db
```

## Notes (`~/Atelier/notes`)

Plain markdown files. Key locations:

| Path | Purpose |
|---|---|
| `~/Atelier/notes/TODO` | Main working todo (plain text, not a vdir todo) |
| `~/Atelier/notes/Elisa/` | Advisor meeting notes, dated `YYYY-MM-DD.md` |
| `~/Atelier/notes/old/` | Archived/older notes |
| `~/Atelier/notes/old/very-old/` | Ancient notes, GELOS, classes, etc. |

The Elisa notes typically have `# Pre` (agenda) and `# Post` (action items) sections.

The `~/Atelier/notes/old/todo.md` file has a dated task breakdown (work, masters, GELOS, personal).

The notes directory is a jj (Jujutsu) repo. Always run `jj new` before making any edits there — same workflow as any other jj repo. Use `jj` for all VCS operations, never `git`.

## Contacts (khard)

khard is a CardDAV address book client. Contacts are synced via vdirsyncer.

**To look up a contact, always use `khard show <name>` first.** It handles fuzzy matching and gives you everything (email, phone, notes, UID) in one shot. Only fall back to grep on `~/Contacts/Main/` for bulk operations or when khard misbehaves.

```bash
khard show <name>             # full contact details (phone, address, notes, etc.) — use this first
khard emails                  # list all contacts that have email addresses
khard list                    # list all contacts
```

### Editing contacts

`khard edit <name>` opens the contact in `$EDITOR`, but requires a TTY and may not work from within opencode. The fallback is to edit the vCard file directly:

```bash
# Find the vCard by UID (shown in khard show output under Miscellaneous > UID)
file=~/Contacts/Main/<UID>.vcf
```

Or grep for the name:

```bash
grep -rl "<name>" ~/Contacts/Main/
```

Then edit the `.vcf` file directly. `NOTE:` is the notes field.

## Email (`/persist/home/bloodwolfe/.mail`)

Mail lives in persistent Maildirs. Tinywolfe is the primary account; Google is secondary:

| Path | Account |
|---|---|
| `/persist/home/bloodwolfe/.mail/tinywolfe/` | bloodwolfe@tinywolfe.net |
| `/persist/home/bloodwolfe/.mail/bloodwolfe/` | bloodwolfepc@gmail.com |

### Maildir layout

Each mailbox contains `cur`, `new`, and `tmp`. Tinywolfe uses `inbox`, `Drafts`, `Junk Mail`, `Sent Items`, and `Deleted Items`; Gmail's special folders are under `[Gmail]`.

**Syncing:** each account has an independent mbsync timer and IMAP IDLE watcher. To force an immediate sync:
```bash
systemctl --user start mbsync-tinywolfe.service
systemctl --user start mbsync-google.service
```

`new/` contains newly delivered messages; `cur/` contains messages already handled by a mail client. Check both directories. Email files are named like:

```
<unix_ts>.<seq>_<host>,U=<uid>:2,<flags>
```

**Flags** (appended after `:2,`):
| Flag | Meaning |
|---|---|
| `S` | Seen (read) |
| `F` | Flagged (important/starred) |
| `R` | Replied |

Flags can combine, e.g. `,FRS` = Flagged + Replied + Seen.

**Moving files between mailboxes:** Always strip the `,U=<uid>` portion from the filename when moving a file to a different Maildir folder (e.g. Inbox to Archive). Otherwise the UID can clash with an existing file in the destination, causing mbsync to error out with "duplicate UID". mbsync will assign a fresh UID on the next sync.

```bash
# Strip UID before moving:
f="${src##*/}" && mv "$src" "$dest/${f//,U=[0-9]*:/:}"
```

### Reading email — workflow

1. **Get an overview first.** Use `grep` across `Inbox/cur/` for `^Subject:`, `^From:`, and `^Date:` to survey what's there before reading bodies.

2. **Check file size before reading.** Some emails contain huge base64-encoded attachments (especially .docx, PDFs, images). Use `read` on the directory to see file sizes (listed in the entries view), then use `limit` when reading to avoid dumping megabytes of base64. Emails with attachments often stretch to 500+ lines.

3. **Read with the Read tool, not cat.** Use `read` with `limit` — start with `limit=160` to grab headers + the beginning of the body. Expand if needed.

4. **Look for `text/plain` first.** Most emails are `multipart/alternative` with both `text/plain` and `text/html`. Read the `charset="UTF-8"` plaintext section — it contains the actual message without HTML soup. The boundary marker is like `--000000000000...`. Skip past the headers to find the `Content-Type: text/plain;` block.

5. **Decode base64 oneliners.** Some emails encode the entire body as base64 (no multipart). The `read` tool renders these as-is, but you can pipe through `base64 -d` in a pinch.

6. **Quoted-printable.** Most plaintext sections use `Content-Transfer-Encoding: quoted-printable`. The Read tool handles this natively — `=C3=A7` renders as `ç`, `=C2=A0` as NBSP, etc.

7. **Flagged emails are worth highlighting.** When summarizing, call out emails with `F` in the flags — Gabs intentionally marks these as important.

8. **Sort order.** Files sort by the Unix timestamp prefix in the filename, so `ls` order is chronological.

### Example: reading all inbox email

```bash
# Step 1: overview
grep '^Subject:' /persist/home/bloodwolfe/.mail/tinywolfe/inbox/{cur,new}/*
grep '^Subject:' /persist/home/bloodwolfe/.mail/bloodwolfe/inbox/{cur,new}/*

# Step 2: check sizes, then read
read /persist/home/bloodwolfe/.mail/tinywolfe/inbox/cur/ <-- check file sizes
read /persist/home/bloodwolfe/.mail/tinywolfe/inbox/cur/<file> limit=160  <-- read one

# Step 3: expand if needed
read /persist/home/bloodwolfe/.mail/tinywolfe/inbox/cur/<file> offset=161 limit=200
```

### Sending email

NeoMutt starts on Tinywolfe. `F2` selects Tinywolfe and `F3` selects Google. To open the configured composer with a recipient, use:

```bash
handlr open mailto:<address>
```

This opens the client's compose window pre-filled with the recipient. For a blank compose window, omit the address:

```bash
handlr open mailto:
```

### Drafts and Sent

- Tinywolfe: `Drafts/` and `Sent Items/`
- Google: `[Gmail]/Drafts/` and `[Gmail]/Sent Mail/`

These use the same Maildir layout. Read them the same way.
