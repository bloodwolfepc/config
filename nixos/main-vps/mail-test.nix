{ pkgs, postfix }:
assert postfix.settings.main.relay_recipient_maps == [ "hash:/etc/postfix/relay_recipients" ];
assert postfix.settings.main.relay_domains == [ "tinywolfe.net" ];
pkgs.runCommand "main-vps-relay-recipients-test" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 -B - ${postfix.mapFiles.relay_recipients} <<'PY'
  import pathlib, sys
  rows = [line.split() for line in pathlib.Path(sys.argv[1]).read_text().splitlines() if line.strip()]
  expected = {name + '@tinywolfe.net' for name in (
      'abuse', 'admin', 'authentik', 'betawolfe1', 'betawolfe2', 'betawolfe3',
      'bloodwolfe', 'january', 'janvv', 'postmaster', 'tinywolfe')}
  assert len(rows) == len(expected)
  assert {row[0] for row in rows} == expected
  assert all(len(row) == 2 and row[1] == 'OK' for row in rows)
  assert 'unknown-recipient@tinywolfe.net' not in {row[0] for row in rows}
  PY
  touch "$out"
''
