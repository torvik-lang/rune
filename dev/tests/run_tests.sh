#!/bin/sh
# rune test suite.
#
# Usage: sh run_tests.sh [path-to-rune] [path-to-torvc]
#   Defaults to `rune` / `torvc` on PATH.
#
# rune ships from its own repository with its own version line, so it is tested
# here rather than inside Torvik's suite - a rune regression should be catchable
# without building the compiler.
set -u

RUNE="${1:-rune}"
TORVC="${2:-torvc}"

WORK="$(pwd)/rune-test-work"
LOG="$WORK/results.log"
rm -rf "$WORK"; mkdir -p "$WORK"
: > "$LOG"

PASS=0; FAIL=0; FAILED_NAMES=""
note() { echo "$1"; echo "$1" >> "$LOG"; }

command -v "$RUNE"  >/dev/null 2>&1 || { echo "rune not found ($RUNE)";   exit 1; }
command -v "$TORVC" >/dev/null 2>&1 || { echo "torvc not found ($TORVC)"; exit 1; }

note "== rune:  $($RUNE --version 2>&1 | head -1) =="
note "== torvc: $($TORVC --version 2>&1 | head -1) =="
note ""
note "== PROJECT CASES =="

rune_case() { # $1 name, $2 expected(0/nonzero), rest: description; body via stdin executed in fresh dir
    name="$1"; d="$WORK/rune_$name"; mkdir -p "$d"
    ( cd "$d" && sh -s ) > "$WORK/rune_$name.log" 2>&1
    rc=$?
    if [ "$rc" = "0" ]; then PASS=$((PASS+1)); note "ok    rune/$name"
    else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/$name"
        note "FAIL  rune/$name"; sed 's/^/      /' "$WORK/rune_$name.log" | tail -15 >> "$LOG"; fi
}

rune_case new_build_run <<EOF
set -e
"$RUNE" new myapp
[ -f myapp/torvik.rune ] && [ -f myapp/src/main.tv ]
cd myapp
"$RUNE" build
[ -x build/myapp ]
out=\$("$RUNE" run)
echo "\$out" | grep -qi "hello"
EOF

rune_case incremental <<EOF
set -e
"$RUNE" new capp && cd capp
"$RUNE" run > first.log 2>&1
"$RUNE" run > second.log 2>&1
grep -qi "cache\|up.to.date\|unchanged" second.log || ! grep -qi "compil" second.log
EOF

rune_case exit_propagation <<EOF
set -e
"$RUNE" new eapp && cd eapp
cat > src/main.tv <<'TV'
df main() -> void {
    exit(4);
}
TV
rc=0
"$RUNE" run || rc=\$?
[ "\$rc" = "4" ]
EOF

rune_case clean_list_version <<EOF
set -e
"$RUNE" new lapp && cd lapp
"$RUNE" build
"$RUNE" list | grep -qi "lapp"
"$RUNE" clean
[ ! -d build ]
"$RUNE" version | grep -q "1\."
EOF

rune_case min_version_gate <<EOF
set -e
"$RUNE" new vapp && cd vapp
# require an impossibly new toolchain; build must refuse and mention update
sed -i 's/^torvik *=.*/torvik = "99.0.0"/' torvik.rune || echo 'torvik = "99.0.0"' >> torvik.rune
if "$RUNE" build > b.log 2>&1; then exit 1; fi
grep -qi "update\|version" b.log
EOF

rune_case missing_entry <<EOF
set -e
mkdir p1 && cd p1
printf '[project]\nname = "p1"\n' > torvik.rune
if "$RUNE" build > b.log 2>&1; then exit 1; fi
grep -qi "main.tv" b.log
EOF

rune_case bad_name <<EOF
set -e
if "$RUNE" new "bad/name" > n.log 2>&1; then exit 1; fi
if "$RUNE" new "" > n2.log 2>&1; then exit 1; fi
exit 0
EOF

rune_case final_build <<EOF
set -e
"$RUNE" new fapp && cd fapp
"$RUNE" build --final
[ -x build/fapp ]
./build/fapp | grep -qi "hello"
EOF

# std version gate
d="$WORK/rune_std_gate"; mkdir -p "$d"; cd "$d"
"$RUNE" new gproj > /dev/null 2>&1
cd gproj
printf 'std         = "9.0.0"\n' >> torvik.rune
"$RUNE" build > g1.log 2>&1
r1=$?
sed 's/std         = "9.0.0"/std         = "0.1.0"/' torvik.rune > t.rune && mv t.rune torvik.rune
"$RUNE" build > g2.log 2>&1
r2=$?
if [ $r1 = 1 ] && grep -q "requires standard library" g1.log && [ $r2 = 0 ]; then
    PASS=$((PASS+1)); note "ok    rune/std_version_gate"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/std_version_gate"; note "FAIL  rune/std_version_gate"; fi
cd "$WORK"

# ---------- v1.5.0: individual-file run ----------
note ""
note "== v1.5.0 CASES =="
d="$WORK/runfile"; mkdir -p "$d"; cd "$d"
printf 'df main() -> void {\n    fixed n: i64 = args();\n    check n >= 2 { echo!(args_get(1)); } fallback { echo!("noargs"); }\n}\n' > prog.tv
if [ "$("$RUNE" run prog.tv 2>/dev/null)" = "noargs" ]; then
    PASS=$((PASS+1)); note "ok    rune/run_single_file"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/run_single_file"; note "FAIL  rune/run_single_file"; fi

if [ "$("$RUNE" run prog.tv HELLO 2>/dev/null)" = "HELLO" ]; then
    PASS=$((PASS+1)); note "ok    rune/run_file_args"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/run_file_args"; note "FAIL  rune/run_file_args"; fi

# A file run leaves no binary behind.
if [ ! -e prog ]; then
    PASS=$((PASS+1)); note "ok    rune/run_file_no_binary"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/run_file_no_binary"; note "FAIL  rune/run_file_no_binary"; fi

if "$RUNE" run /nonexistent-file.tv 2>&1 | grep -q "no such file"; then
    PASS=$((PASS+1)); note "ok    rune/run_missing_file"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/run_missing_file"; note "FAIL  rune/run_missing_file"; fi
cd "$WORK"

# ---------- v1.5.0: [build] manifest section ----------
d="$WORK/buildsec"; mkdir -p "$d"; cd "$d"
"$RUNE" new bproj > /dev/null 2>&1
cd bproj
# A bare project builds to .elf and is not run by the host.
cat >> torvik.rune <<'MANIFEST'

[build]
target = bare
MANIFEST
printf 'df main() -> void {\n    unsafe set v: varda<u16> = from_addr(753664);\n    unsafe store_vol(v, 65);\n    whilst true { unsafe hlt(); }\n}\n' > src/main.tv
if "$RUNE" build > b.log 2>&1 && [ -f build/bproj.elf ]; then
    PASS=$((PASS+1)); note "ok    rune/build_bare_elf"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/build_bare_elf"; note "FAIL  rune/build_bare_elf"; sed 's/^/      /' b.log | tail -8 >> "$LOG"; fi

# With no runner configured, `rune run` explains rather than trying to exec it.
if "$RUNE" run 2>&1 | grep -q "nothing on this machine to run it"; then
    PASS=$((PASS+1)); note "ok    rune/bare_run_no_runner"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/bare_run_no_runner"; note "FAIL  rune/bare_run_no_runner"; fi

# A link-script named in the manifest but absent is rune's error, not clang's.
printf 'link-script = nope.ld\n' >> torvik.rune
if "$RUNE" build 2>&1 | grep -q "doesn't exist"; then
    PASS=$((PASS+1)); note "ok    rune/build_missing_linkscript"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/build_missing_linkscript"; note "FAIL  rune/build_missing_linkscript"; fi
cd "$WORK"

# ---------- v1.5.0: version-policy flags ----------
d="$WORK/policy"; mkdir -p "$d"; cd "$d"
# Silencing with no new major must refuse rather than quietly record nothing.
if "$RUNE" update --silence-major 2>&1 | grep -qE "no new Torvik major to silence|couldn't reach"; then
    PASS=$((PASS+1)); note "ok    rune/silence_major_nothing_to_silence"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/silence_major_nothing_to_silence"; note "FAIL  rune/silence_major_nothing_to_silence"; fi

if "$RUNE" update --silence-std-major 2>&1 | grep -qE "no new standard-library major|couldn't reach"; then
    PASS=$((PASS+1)); note "ok    rune/silence_std_nothing_to_silence"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/silence_std_nothing_to_silence"; note "FAIL  rune/silence_std_nothing_to_silence"; fi

if "$RUNE" update vABC 2>&1 | grep -q "not a valid version"; then
    PASS=$((PASS+1)); note "ok    rune/update_bad_version"
else FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES rune/update_bad_version"; note "FAIL  rune/update_bad_version"; fi
cd "$WORK"

note ""
note "== SUMMARY: $PASS passed, $FAIL failed =="
if [ "$FAIL" != "0" ]; then note "failed:$FAILED_NAMES"; exit 1; fi
exit 0
