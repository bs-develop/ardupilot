#!/bin/bash
# Usage: ./build_boards.sh <BOARD_NAME> [OUTPUT_APJ_NAME]

set -euo pipefail

REQUIRED_GCC="10.2.1"

# ─── ARGS ─────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo "Usage: $0 <BOARD_NAME> [OUTPUT_APJ_NAME]"
    exit 1
fi

BOARD="$1"
OUTPUT_NAME="${2:-$BOARD}"

# ─── COLORS ───────────────────────────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
DIM='\033[2m'

step()  { echo ""; echo -e "${BOLD}${BLUE}▶ [Step $1] $2${R}"; echo -e "${DIM}──────────────────────────────────────────${R}"; }
ok()    { echo -e "${GREEN}  ✔  $*${R}"; }
fail()  { echo -e "${RED}${BOLD}  ✘  ERROR: $*${R}"; echo ""; exit 1; }
elapsed() { echo $(( $(date +%s) - $1 )); }

# ─── HEADER ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${R}"
echo -e "${BOLD}${CYAN}  Building: $BOARD${R}"
echo -e "${BOLD}${CYAN}  Output:   ${OUTPUT_NAME}.apj${R}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${R}"

START=$(date +%s)

# ─── STEP 1 — GCC VERSION ─────────────────────────────────────────────────────
step 1 "Checking arm-none-eabi-gcc version"

if ! command -v arm-none-eabi-gcc &>/dev/null; then
    fail "arm-none-eabi-gcc not found in PATH"
fi

GCC_FULL=$(arm-none-eabi-gcc --version | head -1)
echo "  $GCC_FULL"

if echo "$GCC_FULL" | grep -q "$REQUIRED_GCC"; then
    ok "GCC $REQUIRED_GCC confirmed"
else
    fail "Expected GCC $REQUIRED_GCC — activate the correct toolchain before continuing"
fi

# ─── STEP 2 — BOOTLOADER ──────────────────────────────────────────────────────
step 2 "Building bootloader"
T=$(date +%s)
python3 Tools/scripts/build_bootloaders.py "$BOARD"
ok "Bootloader done  ($(elapsed $T)s)"

# ─── STEP 3 — WAF CONFIGURE ───────────────────────────────────────────────────
step 3 "waf configure --board $BOARD"
T=$(date +%s)
./waf configure --board "$BOARD"
ok "Configure done  ($(elapsed $T)s)"

# ─── STEP 4 — WAF COPTER ──────────────────────────────────────────────────────
step 4 "waf copter"
T=$(date +%s)
./waf copter
ok "Build done  ($(elapsed $T)s)"

# ─── STEP 5 — RENAME APJ ──────────────────────────────────────────────────────
step 5 "Renaming APJ"
SRC="build/${BOARD}/bin/arducopter.apj"
DST="build/${BOARD}/bin/${OUTPUT_NAME}.apj"

[ -f "$SRC" ] || fail "APJ not found at $SRC"

mv "$SRC" "$DST"
ok "arducopter.apj  →  ${OUTPUT_NAME}.apj"
echo -e "  ${DIM}${DST}${R}"

# ─── DONE ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${R}"
echo -e "${BOLD}${GREEN}  Done in $(elapsed $START)s${R}"
echo -e "${BOLD}${GREEN}  ${DST}${R}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${R}"
echo ""
