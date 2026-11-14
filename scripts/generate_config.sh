#!/usr/bin/env bash
set -euo pipefail

: "${DISCORD_APP_ID:=1571251144280244225}"

cat > App/Config.generated.swift <<EOF
import Foundation

enum GeneratedConfig {
    static let discordApplicationID: UInt64 = ${DISCORD_APP_ID}
}
EOF

# Config.swift already contains the type in local source; remove it from that file
python3 - <<'PY'
from pathlib import Path
p=Path("App/Config.swift")
text=p.read_text()
marker="\nenum GeneratedConfig {"
i=text.find(marker)
if i != -1:
    text=text[:i].rstrip()+"\n"
p.write_text(text)
PY
