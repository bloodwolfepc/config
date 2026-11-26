# Disabled local Pi boundary candidate

`pi-coordinator.nix` is imported by Angel but defaults disabled. Importing it
installs/starts nothing and creates no identity. There is no default live launcher,
credential provisioner, disk allocator, boot target or automatic restart. The
wolfe-pi companion is documented in `doc/fixed-batch-local.md` in that repository.
This source slice does not complete CFG-2's host qualification.

The separately selected build-only `angel-pi-h1` profile, dedicated worker pin,
synthetic probe entrypoint and retained partial-H1 receipts are documented in
[pi-coordinator-install.md](pi-coordinator-install.md). Ordinary Angel,
Angelstuck and Navi still do not enable the coordinator; no live trial is implied.

## Declared boundary

A prospective unit requires a separately reviewed entrypoint, explicit provider
and resolver **host** CIDRs (`/32` or `/128`) and one/two admitted task IDs mapped to
private dedicated workspace mounts. No default network wildcard is provided.
Only the trusted coordinator has this network policy; tools always request their
own network namespace without host networking or a fallback.

The unit declares a separate system identity, 2 CPU quota, 4 GiB memory, no swap,
128 tasks, control-group stop/kill, private devices/tmp/home, a root skeleton,
read-only store/certificate/resolver bindings and explicit persistent state/workspace
bindings. Stop grace is operational cleanup, not a run allowance or suspend-clock
qualification. The coordinator needs the store for its trusted runtime; each tool
worker instead sees only individually selected toolchain closure members.

Every Bash/check/read/write/edit operation goes through the immutable helper.
The trusted parent validates policy/metadata and starts bubblewrap; model-controlled
I/O runs only in `--worker`. Required user/PID/network/IPC/UTS/cgroup namespaces,
no further user namespaces, dropped capabilities, read-only root, 256 MiB scratch,
sterile environment and one `/workspace` are explicit. Unsupported flags/errors
stop; there is no host-shell fallback. Do not substitute `--*-try` flags.

The outer coordinator uses `ProcSubset=all`: Bubblewrap needs kernel proc APIs
such as `/proc/sys/kernel/overflowuid` and `overflowgid` before tool execution.
`ProcSubset=pid` hid those APIs and produced the observed startup failure.
This explicitly restores non-PID kernel metadata visibility (not just those two
files); it is a reviewed boundary expansion, not a transparent security no-op.
`ProtectProc=invisible` still hides other users' processes.
`systemd.exec(5)` offers only `all`/`pid`, not a per-file subset exception; file
binds need an existing/creatable target, which pid-only procfs does not supply
under hidden `/proc/sys`.

### Proc-mount compatibility candidate (source-only)

Continuation0001 subsequently failed before worker execution with
`bwrap: Can't mount proc on /proc: Operation not permitted`. The deliberately
shared120-byte diagnostic matched the retained hash; the continuation, closed-label
inspection and separate local disclosure remain consumed. No retry is implied.
`ProtectKernelTunables=true` overmounts parts of the parent procfs. Linux's
fully-visible-proc check can then reject a fresh proc mount in an unprivileged
user namespace. This is reproduced in
[Nixpkgs477428](https://github.com/NixOS/nixpkgs/issues/477428) and
[sandbox-runtime743](https://github.com/anthropics/sandbox-runtime/issues/743).
It is a high-confidence explanation, NOT a local live A/B or kernel-trace proof.

The candidate removes ONLY the outer unit's `ProtectKernelTunables` proc masks
and explicitly remounts the worker's freshly created `/proc` read-only immediately
after `--proc /proc`. `--unshare-pid` remains mandatory; no host-proc bind, reused
PID namespace, alternate proc, patched Bubblewrap or `--*-try` fallback is added.
Bubblewrap0.12 also protects accessible sensitive proc subpaths during `--proc`;
our explicit whole-proc remount does not rely solely on that conditional behavior.
Remount/setup failure remains a hard refusal, never a host-shell retry.

This is a security trade-off, not equivalent enforcement at the same layer:
- The trusted coordinator loses its mount-level kernel-tunable backstop. Dedicated
  non-root identity, empty capabilities, no-new-privileges, strict root/system/home,
  module/cgroup/device/network/resource controls and ordinary kernel/DAC protection
  remain. Model-controlled code must still execute ONLY inside the immutable tool
  worker; this is not permission to run application hooks/code in the coordinator.
- The worker retains fresh PID/user/net/IPC/UTS/cgroup namespaces, no further user
  namespaces and dropped capabilities, and now requests read-only private procfs
  explicitly. No parent proc tree/tunable bind exposes outer PID/network views.
- Writes to the worker's own proc control files also become unavailable. Programs
  needing writable proc controls need separate review, never a writable fallback.
  Read-only proc is not a claim that following an FD symlink cannot write its
  already-open target; inherited-FD closure/denial remains separately mandatory.

Before activation/use, separately qualify the actual worker proc mount/submount
flags, PID privacy, unchanged FD/network/credential isolation and tunable-write
refusal on both sides. Do not mutate host tunables or sysrq to test denial. Inspect
mounts/identity/capabilities and use separately approved non-destructive checks.
No native isolation/resource/cancellation/collector/crash/reboot proof is waived.
All previous owners/holds/partial workspaces remain; do not replay continuation0001
or its diagnostic/disclosure helpers. Source review, promotion, activation and any
new qualification authority/reconciliation remain separate human decisions.

Workspace validation requires canonical private controller-owned directories,
actual ext4 mounts of at most 1 GiB and distinct device IDs across the configured
map. No allocation, formatting, copying old data or quota adjustment is performed.
Text file routes use dirfds/no-follow, reject links/special/oversized reads and
fsync atomic replacements. Bash returns bounded capture; malformed/truncated or
unknown outcomes must retain ownership. These code paths are not kernel proof.

## Trusted capture helper (source-only)

`pi-batch-management.py` is wrapped as the immutable `pi-batch-management` binary
and exposed only to the trusted coordinator through `PI_FIXED_BATCH_MANAGER` and
`system.build.pi-batch-management`. It is never registered as a model tool and
is not mounted in a worker. The policy binds the worker, admitted workspace map,
fixed `/var/lib/pi-coordinator/journal`, provider CIDRs and module-source digest.
The source-only wolfe-pi launcher package can bind these exact paths/digests;
this module still selects no entrypoint and provisions no launch/admission files.

`inventory`/`preflight` are read-only. `before`/`after` require matching existing
owner/run/approval IDs, create exclusive private bundles beneath that run, fsync
content-addressed blobs and write hash-bound manifests last. There is no Git,
workspace code/hook/config execution, replacement, retry or lock release.
Collection allows only owned regular files (including binary), bounded to
1024 files/2048 entries/depth32/131072 total path bytes,1MiB each/16MiB per tree.
It refuses `.git`, links, cross-device/special/oversized/unstable files and
privileged modes. Fresh filesystems need plain approved export contents and no
unowned `lost+found`; the helper never removes/prepares those entries itself.
Empty-directory metadata, timestamps, ACLs/xattrs are not filesystem-image evidence.
Double scans/identity checks are optimistic race detection, not an atomic snapshot
or proof that worker descendants stopped. These remain real H1 requirements.

A model failure leaves the before bundle and owner for manual reconciliation;
after/report failures likewise never manufacture a completed delivery. Capture
limits are separate from model-output allowances; neither is a disk/spend guarantee.
The fixed launcher keeps its minimal native store in private `profile/auth.json`,
outside tool roots; its external read-only `admission.json`/`h1.json` bindings do
not attest their own human provenance or host enforcement. No such real files
are created by this source change. See the companion delivery protocol for the
private report and seal marker; final model text is not acceptance/check proof.

## Separate operator prerequisites

Before any activation, independently qualify:

- Fresh persistent coordinator state and one/two distinct workspace filesystems;
  ownership, mount identity/capacity and approved starting contents/base. No
  existing application/Podman/NAS/libvirt data is authorized for this purpose.
- A reviewed launcher that binds exact manual approval, account/model/helper,
  fixed journal root, task/spec/base and all counters. The companion source
  retains a durable owner even on completion; no automated reconciliation exists.
- A separately provisioned minimal native credential store under private
  controller state, outside every tool mount. Never put credentials in Nix,
  environment arguments, tool workspaces or logs, and never copy the operator's
  whole Pi profile. The read-only SDK adapter does not enroll or refresh it.
- A reviewed, pre-realized task toolchain and usable offline checks. Networkless
  tools cannot fetch dependencies or contact a Nix daemon. An oversized closure
  or task that needs new access requires another decision, not broader mounts.
- Durable exact workspace/patch artifact collection and a truthful report. Final
  model text alone is not proof that a requested change/check happened.

No-model host trials need separate approval: positive confined operations plus
host/home/credential/store/device/proc/FD/socket/network denial, CPU/memory/PID/disk
limits, namespace/descendant teardown, unit stop/cancellation, persistence/reboot
and unknown-owner refusal. Verify actual processes, mounts and controls; metadata
and exit messages do not establish enforcement. Failure means hold and reassess
the local candidate/VM fallback, never weaken isolation automatically.

Only after reviewed source/promotion/loading, provisioning/installation, concrete
credential binding and host qualification may Jan separately admit a tiny live
canary/batch. No first run, schedule, service enable/start or reboot is authorized
by these files or by accepted source reports. Dedicated-VM/OpenSandbox/Navi tasks
and PI-30/PI-3 holds remain separate and unchanged.

## Offline source checks

The `pi-coordinator` flake check evaluates a disabled and an inert prospective unit
(`pkgs.hello` is metadata only, never a real entrypoint), checks refusal assertions
and runs Python parser/file-operation/Bash and collector fixtures in temporary directories.
It inspects bubblewrap arguments and `--help`; **it never launches a namespace or
service, provisions a disk, uses a credential or makes a provider call**. Device
alias and collector privileged-mode checks use synthetic metadata, not live
mount/privilege/denial trials. Collector fixtures test content/mode hashes,
exclusive owner-bound capture, binary/Unicode blobs and file/race refusals.

Angel, Angelstuck and Navi toplevel derivation evaluations are compatibility checks,
not deployment or host qualification. No configuration outside this disabled
candidate should be changed to make those checks pass.
