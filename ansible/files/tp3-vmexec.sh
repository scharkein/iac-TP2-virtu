#!/bin/bash
# Execute (via qemu-guest-agent) le script lu sur STDIN dans la VM <vmid>, rejoue sa sortie.
# Usage : tp3-vmexec <vmid> <<'EOS' ... EOS      (code retour = code du script invite)
set -u
VMID="${1:?vmid}"
RAW=$(qm guest exec "$VMID" --pass-stdin 1 --timeout "${TIMEOUT:-90}" -- /bin/bash -s) || exit 255
python3 -c '
import json, sys
d = json.loads(sys.argv[1])
sys.stdout.write(d.get("out-data", ""))
sys.stderr.write(d.get("err-data", ""))
sys.exit(int(d.get("exitcode", 255)))
' "$RAW"
