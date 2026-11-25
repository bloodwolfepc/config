# Build-only Pi worker/H1 installation wiring

This source adds `nixosConfigurations.angel-pi-h1`, **not an activated host**.
Ordinary Angel, Angelstuck and Navi do not import its installation module.
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
It refuses nonprivate state, a nonempty workspace/journal, any real credential/
admission/H1 pathname (including broken symlinks), or an earlier probe attempt.
It creates an exclusive/fsynced `h1-probe/owner.json` before any tool dispatch.

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
receipt/full disk still means hold. No cleanup, unlock, retry or owner transfer
exists. Synthetic ownership must be reconciled by a separately authorized human
before real admission; never bypass it using a new journal root. Save all evidence.

Host-side process/cgroup/mount/socket/device observations, controlled network/DNS
denials, actual resource exhaustion, descendant cleanup/cancellation, collector
failure/tamper tests, crash/reboot durability and final-environment review remain
explicit pending items. In-unit namespace observations cannot certify host-side
teardown. The inventory environment digest is not a hash/proof of the entire OS;
external evidence must bind the exact system generation, unit and backing mounts.
Do not manufacture `h1.json` from the result or turn missing tests green.

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
