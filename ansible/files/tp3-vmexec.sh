#!/bin/bash
# Exécute un script court dans la VM via QEMU Guest Agent.
# Usage : tp3-vmexec <vmid> <<'EOS'
#          ...
#         EOS

set -u

VMID="${1:?Usage: tp3-vmexec <vmid>}"
TIMEOUT="${TIMEOUT:-15}"

RAW=$(qm guest exec "$VMID" \
    --pass-stdin 1 \
    --synchronous 1 \
    --timeout "$TIMEOUT" \
    -- /bin/bash -s) || {
        echo "Erreur QEMU Guest Agent pour la VM $VMID" >&2
        exit 255
    }

python3 -c '
import json, sys

try:
    d = json.loads(sys.argv[1])
except Exception as e:
    print("Réponse QEMU invalide:", e, file=sys.stderr)
    print(sys.argv[1], file=sys.stderr)
    sys.exit(255)

if "exitcode" not in d:
    print("Commande non terminée ou délai dépassé.", file=sys.stderr)
    print(json.dumps(d), file=sys.stderr)
    sys.exit(124)

sys.stdout.write(d.get("out-data", ""))
sys.stderr.write(d.get("err-data", ""))
sys.exit(int(d["exitcode"]))
' "$RAW"