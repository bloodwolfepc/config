# Build-only Pi worker/H1 installation wiring

This source declares `nixosConfigurations.angel-pi-h1`; this candidate is
**source/build-only**. Existing human-installed host state does not authorize
applying this revision or starting another trial. Ordinary Angel, Angelstuck and
Navi do not import its installation module.
It selects a no-model synthetic probe entrypoint, never `pi-fixed-batch --run`.
No new automatic Kaneo adapter, schedule, credential flow or source licensing
change is included. Existing PI-3/PI-30 and H1/H2 holds remain.

## Pin and package

`pi-fixed-batch-src` is a separate exact Git input at
`1ae19b0a1f698a8b36f941fde4cf469ea6ee051b`, NAR hash
`sha256-Y4ebHPTrcmhFVrR3JR5+wDlv1V5uIgbXrxREeibZX+E=`.
It selects only `packages.x86_64-linux.pi-fixed-batch`; the shared `wolfe-pi`,
interactive `pi`, Kaneo/srv and other existing locks are unchanged. Its follows
reuse already locked dependency nodes. The canonical tree was exported locally
from the previously human-published commit and every Git blob/path/mode verified
before hashing; no new private fetch or signing authentication was performed.
An offline Nix build validates the composed input, not fresh remote provenance.
The worker uses immutable packaged source, not the dirty mutable Pi checkout.

## Prospective host effects, not performed

Selecting/activating the H1 profile would declare the dedicated system identity,
unit, two loop-backed ext4 mounts and its package closure. There is no allocator,
formatter, credential provisioner or unit start here. Both filesystem entries
are `noauto`, nodev/nosuid/noexec; explicit unit mount requirements become relevant
only after separately approved activation/start. No unit WantedBy/timer/restart,
start-on-config-change or stop-on-config-change is selected. Never update a
running batch's configuration: require a reviewed inactive/empty-cgroup precondition.

The immutable service root must pre-create `/dev`, `/proc`, `/sys`, `/run`,
`/tmp` and `/var/tmp`: `MountAPIVFS` supplies the API mounts (including an empty
`/run` tmpfs), while `PrivateTmp` needs both temporary-directory mount targets.
This adds empty mountpoints, not new host bind paths or weaker sandbox settings.
The artifact regression checks these actual built directories and existing bind
placeholders; it does not certify successful systemd namespace setup. Even a
pre-exec setup failure consumes its host-side trial attempt: preserve its evidence
and require explicit reconciliation plus review of the changed generation before
another trial. Never replay the consumed installation/trial helper to test a fix.

A future reviewed human provisioning helper must exclusively create new
`/persist/pi-coordinator-images/state.ext4` and `slot-1.ext4`, proposed256MiB each,
then prepare the controller-owned0700 ext4 roots at `/var/lib/pi-coordinator`
and `/var/lib/pi-tool-workspaces/slot-1`. The source does not enforce allocation
size by creating an image: that remains an explicit provisioning precondition.
The actual workspace helper checks <=1GiB ext4; state capacity needs host review.
No existing image/device/volume may be formatted or replaced. Prepare any fresh
`lost+found` ownership/mode explicitly and retain it empty. Real credentials,
admission and qualification records must be absent for these synthetic probes.

The profile permits only the inert documentation CIDR203.0.113.1/32, **not real
provider access**. Its inventory-only launch JSON contains synthetic task/base/
account identifiers and zero provisional tree/policy hashes. It is never a Kaneo
task grant, valid production spec or H1 decision. A real launch must separately
bind its actual task map/toolchain/runtime/network/storage and reviewed evidence;
requalify affected changes rather than reusing this fixture's inventory digest.

An active-to-proposed generation/activation diff is mandatory before a switch:
installing from canonical config can include previously unactivated changes even
though this new input does not upgrade shared interactive Pi policy. Preserve
all dirty native checkouts and the immutable Angelstuck fallback.

## Probe entrypoint and retained evidence

The service calls `pi-coordinator-h1` with one immutable settings JSON, using the
same coordinator module/helpers as the candidate. The library uses the actual
workspace validator; offline tests inject an inert validator/transport instead.
Its original fresh-run mode refuses nonprivate state, a nonempty workspace/journal,
any real credential/admission/H1 pathname (including broken symlinks), or an earlier
probe attempt. It creates an exclusive/fsynced `h1-probe/owner.json` before any tool
dispatch. Those fresh/replay rules remain unchanged. The declared H1 profile now
selects only the separately gated continuation below; there is no fallback to fresh.

Later, when explicitly started for H1, finite probes exercise Bash/read/write/edit,
controller-state marker denial, excluded-store denial, selected sterile environment
variables, all seven namespace identities and inherited-FD denial. The packaged
CLI is used only for `--inventory`, an existing-owner `--preflight` refusal, and
an incomplete `--report`. No `--run`, provider request, real auth file or default
profile discovery is performed. The only marker is synthetic and nonsecret.
Transport has bounded input/output and a15-second **operational probe timeout**;
this is not a model/run elapsed allowance and does not change the no-elapsed contract.

The owner-refusal probe intentionally leaves a synthetic `journal/owner.json`.
Success writes read-only `h1-probe/RESULT.json` with source/settings digests,
namespace inode observations, state/workspace device IDs and inventory bindings,
`status: partial-h1` and `qualification: not-granted`; failure attempts `HELD.json` and preserves partial
state. Exit zero means these probes completed, **not H1 accepted**. A failed
receipt/full disk still means hold. Probe cases are named before dispatch so a
transport exception can be identified in the attempted `HELD.json`. Unexpected
child exits retain only the existing output digest, bounded byte count and a
closed vocabulary of **untrusted** diagnostic hints (for example bubblewrap,
namespace, permission or missing-path markers). In fresh-run mode child output is
never retained or decoded into error text; unrecognized output yields no hints. Transport
failures retain only a fixed category and bounded numeric OS errno, never raw
exception values, argv, environment or credentials. A hint can be forged by
child output: it is not a diagnosis, test result or isolation proof. The normal
15-second operational deadline remains unchanged and is categorized as timeout.
This cannot recover discarded output from an earlier consumed trial; source
promotion, runtime changes and any further diagnostic execution need separate
review/approval, never replay or a new worker/journal root.
No cleanup, unlock, retry or owner transfer exists. Synthetic ownership must be
reconciled by a separately authorized human before real admission; never bypass
it using a new journal root. Save all evidence.

### One append-only synthetic continuation, not an unlock

The profile's immutable `pi-h1-continuation-0001.json` names exactly the original
failed first-write owner/HELD/output digests, task and two ext4 UUIDs. It is a
**descriptor, not execution authority**. The separate, source-only
`pi-h1-continuation-controller.py` below prepares an exact historical host handoff;
it is not installed, activated or authorized merely by being present. No generic
force/reset/resume CLI or owner release exists. An unchanged direct restart cannot
validly replay the old trial.

Before a later, separately approved start, the trusted root supervisor must:

1. Independently verify inactive unit/empty cgroup, exclusive writer, current
   generation and loaded unit, unchanged original records and partial workspace,
   actual loop images/UUIDs/options/capacity, no credentials/real admission/H1,
   and retained H1/v1/v2 failure evidence. ResetFailed is not reconciliation.
2. Obtain/record scoped human reconciliation, without changing historical
   owner/HELD/diagnostic receipts, then a **separate** default-No trial decision.
3. Durably consume its sole issuer attempt **before** issuing a nonsecret
   `h1-probe/continuation-0001.grant.json` (root:coordinator-group0440, regular,
   single-link, private parent), and its distinct start/dispatch attempts before
   starting the existing coordinator once.
   Grant/start uncertainty consumes that admission; never replay or substitute
   another name/root. Issuance is an approved mutation of the existing state
   volume, not cleanup or a credential/bootstrap operation.

The exact grant schema is checked by `prepare_continuation`:
- `version: pi-h1-continuation/v1`, `id: 0001`,
  `authority: one-synthetic-continuation-only`, `retainPrivateFailure: true`;
- `descriptorSha256`: raw immutable descriptor bytes;
- `runtime`: exact `runtime_binding(settings)` result: current harness bytes,
  SHA256 of `json.dumps(settings, sort_keys=True).encode()` (not raw settings
  serialization), and paths/raw hashes for helper, launcher, launch, validator,
  Python, excluded canary, policy and descriptor. Compute after building the
  final target; no self-referential generation hash in the Nix descriptor;
- `host`: generation, immutable coordinator unit SHA256, reconciliation receipt
  SHA256, bootId, stateDevice/workspaceDevice (integer `st_dev`), stateUUID and
  workspaceUUID. The consumer checks current boot/devices, distinct devices,
  descriptor UUIDs and the unit bytes in the named immutable generation.
  **Current loaded generation/unit, physical UUIDs and reconciliation are root
  supervisor attestations**, not independently observable facts in this chroot.
  A syntactically valid attestation alone is not host verification;
- `limits`: exactly13dispatches,15s/operation,8192input bytes,131072capture bytes,
  131072private failure bytes,240configured runtime seconds and10stop-grace
  seconds (field names/integers in `LIMITS`, no floats or extra keys).

The consumer requires exactly the old owner, HELD, canonical synthetic marker and
root grant in the same existing0700 probe directory; original RESULT, journal
owner, unknown entries, links, metadata/content drift or missing retained journal
refuse. The native workspace validator still requires the original slot empty
apart from empty lost+found. Root preflight must validate marker/partial state
before issuing the grant; it must not reconstruct missing state to pass freshness.
It exclusively fsyncs `continuation-0001.attempt.json` before dispatch and one
`continuation-0001.case-NN.attempt.json` before each call. Original files remain
byte-identical, including absent original RESULT. A fixed no-write Bash marker
comes first, then the existing12cases, using the same four sandbox operations and
CLI inventory/refusal/report only. There is no model, provider or real batch grant.
The shared owner-refusal case may create the previously absent synthetic journal
owner exactly once; retain it, along with the workspace's new synthetic probe file.

Only continuation-specific RESULT/HELD files are appended. Failure attempts one
operator-private0400 `continuation-0001.failure.bin` of at most128KiB **combined
helper output**, not a stderr-only claim. Closed metadata/digests only go into
receipts; partial transport prefixes are marked incomplete. Metadata names the
last captured case and explicitly disclaims cause proof: a later local persistence
or validation failure can leave that case's successful output as context, not its error. Failure to persist
output/receipt remains held and non-replayable; a durable attempt is not success.
No raw output enters the system journal, model messages or ledger. Future execution
consent must expressly include this capture; source approval is not capture consent.

H1-specific RuntimeMaxSec240, existing control-group kill and10sstop grace are
configured limits, not guaranteed elapsed/spend budgets. Host monitoring and exact
allowed deadline/cancellation actions must be frozen/tested in the separately
reviewed execution helper. Client termination is not descendant teardown proof.
Success remains partial-H1/not-granted; original HELD is not replaced, h1.json is
never manufactured, and no post-success cleanup or ownership transfer is allowed.

Host-side process/cgroup/mount/socket/device observations, controlled network/DNS
denials, actual resource exhaustion, descendant cleanup/cancellation, collector
failure/tamper tests, crash/reboot durability and final-environment review remain
explicit pending items. In-unit namespace observations cannot certify host-side
teardown. The inventory environment digest is not a hash/proof of the entire OS;
external evidence must bind the exact system generation, unit and backing mounts.
Do not manufacture `h1.json` from the result or turn missing tests green.

### Trusted continuation controller: source candidate only

`pi-h1-continuation-controller.py` is a manual, historical-host-specific controller,
not a new daemon/module/model entrypoint. It leaves current host definitions and
all original evidence/workspace/journal roots unchanged. Its new fixed private
`/persist/pi-h1-continuation-controller-20261125-v1` is **observer/authority
checkpoint storage only**, never a replacement worker owner or journal. No path,
unit, account, continuation ID or budget override is accepted. A prepared immutable
packet/wrapper needs separate review before any privileged phase is offered.

Five independent default-No decisions are required: private evidence audit;
scoped reconciliation without owner release or H1 qualification; private combined
failure retention/hash-reading (128KiB, no raw export); root grant installation;
and one synthetic start with a narrowly disclosed single-stop contingency.
Root also requires the operator's actual existing sudo terminal and immutable
reviewed source. Packet hashes are rechecked after each decision. Every phase has
exclusive fsynced attempts/done receipts; partial/unknown checkpoints block later
phases and replay. The issuer and dispatch are separate one-shot authorities.
Original H1/v1/v2 holds stay consumed. No ResetFailed, restart, mount/format,
credential, boot/default, model/provider, acceptance or cleanup operation exists.

The audit reuses only verifier/import functions from the pinned previous activation
helper, not any consumed audit/activation/main phase. It independently rereads all
old private receipt domains, both activation generations' evidence, controller
state and physical mounts/loop identities against hash-bound historical exports.
Those exports are expected values, not proof of a fresh private read. Such proof
exists only after the separately approved privileged audit succeeds. Root computes
the same runtime binding as the coordinator without reusing its UID-relative
immutable/grant convenience guards; root grant checks explicitly require UID0,
GID977,0440/single-link. The packaged schema fixture checks this interoperability
with the actual consumer but stubs host attestation/file authority, not OS isolation.

Before start the controller rechecks fixed roots, complete issuer checkpoints,
original receipts/markers, runtime/loaded generation/unit/storage, absence of
native authority, no dedicated UID processes/cgroup and existing stop definitions.
A durable dispatch checkpoint precedes the systemctl request. Polling has a250s
operational window and501/3MiB sample caps; individual bounded metadata queries
can overrun polling windows, so these are NOT hard elapsed/spend promises. Normal
terminal observations require exact invocation/start-time continuity, successful
main exit, no dedicated processes/fixed cgroup and all13case/attempt bindings.
A dispatch failure/interruption/unknown outcome permits only the separately
approved **one fixed-unit stop** (no kill fallback/reset/retry), followed by a15s
teardown polling window. Failure before dispatch never stops another operation.
Stop failure/unknown outcome remains held; supervisor SIGKILL cannot promise a
finally block, and kernel/systemd teardown still needs actual qualification.

The controller retains bounded metadata samples and RESULT/HELD privately, with
hash-only failure-file metadata; raw combined helper bytes remain solely in the
original volume's private failure.bin. Root artifacts/JSON are bounded (5MiB per
receipt,3MiB combined samples,1MiB new consumer-artifact reads; current activation
receipts262KiB each/1MiB combined). Allow14MiB for new observer checkpoints;
this is a bounded synthetic evidence allowance, not a model work allowance.
No grant/start helper packet has been executed by adding this source. Even a
successful synthetic result stays `partial-h1-observed`/`not-granted`; all remaining
H1 process/resource/network/cancellation/collector/crash/reboot proofs and H2
remain mandatory before useful work. Never map this result to H1 acceptance,
canonical journal supersession or overnight admission.

### Separately gated private failure inspection

`pi-h1-private-failure-inspect.py` is a source-only diagnostic for the consumed
continuation's exact120-byte startup-marker failure, not a continuation issuer.
Its hash/owner/HELD/invocation/boot/generation are fixed. A new immutable review
packet and actual human sudo terminal/default-No content-inspection consent are
required; previous hash-only capture consent is NOT content-inspection authority.
It appends one exclusive inspection attempt/done-or-HELD under the EXISTING observer
directory, holding the original observer's lock and preserving its exact owner.
No new runtime/journal root, grant, unit start/stop/reset/retry, repair or owner
release exists. A partial or complete inspection is never replayed automatically.

Before any content open, it checks the failed/quiescent fixed unit/no UID987
processes/cgroup, original observer owner/HELD, file UID987/GID977/0400/single-link/
120-byte/device1792 identity, then fsyncs its attempt. Content hash must match before
classification. Only whole-line public Bubblewrap message templates map to fixed
stage/errno enums; generic helper failure is not a diagnosis. Unknown, partial,
ANSI/control, variable-path or other text is never emitted. Export only closed
labels, counts/digests and explicit untrusted/not-cause-proof flags, never raw
content or exceptions. A recognized creation/unshare message does not identify
which namespace/syscall/kernel policy denied it. Subsequent investigation/changes
still need their own scope; this diagnostic cannot authorize another trial.

### Separate terminal-only disclosure after an inconclusive classifier

`pi-h1-private-failure-display.py` prepares a DIFFERENT, separately approved privacy
operation, not a replay/extension of the consumed closed-label classifier or H1.
It requires the exact completed classifier receipt hash in addition to the prior
owner/HELD/failure bindings and failed/quiescent host. A human sudo terminal and
independent default-No consent authorize one escaped120-byte display solely to
`/dev/tty`. Never stdout/stderr, a saved file, chat or a model tool result. JSON
escaping with ensure_ascii handles control sequences, bidi and invalid UTF-8;
terminal control bytes from the payload are never written literally. A real
character TTY is required; no file/pipe destination or alternative input is accepted.

Hold the SAME observer owner lock and append `failure-local-disclosure-0001`
attempt/done-or-HELD metadata to that SAME directory, before any content open.
Preserve the earlier completed inspection and all runtime/owner/hold records.
A terminal write error may mean partial display; consume the disclosure and never
retry automatically. Only counts/digests/status leave on stdout or enter receipts.
The helper does not enable transcripts or save/send raw text; terminal/sudo I/O
logging and scrollback are external controls, not guarantees this code can make.
Jan reviews locally and deliberately shares only a nonsecret diagnostic if safe.
No grant/unit/repair/reset/retry/release/H1 qualification authority is added.

## Kaneo and first-run review

For the first pilot, trusted Pi uses the existing official CLI/profile to freeze
one approved task before dispatch and post actual blockers/evidence/Review after
independent morning checking. Workers receive frozen IDs/specs, never Kaneo or
forge credentials. No unattended board polling/live reporting is implemented;
PI-4 retains its existing automated-adapter scope/qualifications. Changed human
scope or uncertain writes require reconciliation, not overwrite or blind retry.

The first task must have offline checks which leave the final tree unchanged.
Morning checking is an independent, separately authorized confined invocation,
not a resumed model grant or unrestricted host execution. Verify sealed content
and before/after tree identity, retain actual check exit/output/toolchain evidence,
and post Review, never Accepted. Automatic check receipts are not claimed from
model text/result digests. OAuth expiry/no-refresh qualification remains H2.

## Source verification only

`checks.x86_64-linux.pi-coordinator-install` evaluates inert unit/mount/launcher
metadata, checks actual immutable paths, runs synthetic Python refusal/retention/
I/O fixtures and the packaged worker's `--help`. It never starts the H1 entrypoint,
unit, namespace, mount, provider request or resource trial. The existing coordinator
check remains separate. Evaluate ordinary Angel/Angelstuck/Navi plus the H1 profile
before source promotion; all live installation/qualification still needs approval.
