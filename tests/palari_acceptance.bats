#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMP_ROOT="$(mktemp -d)"
  WORK="$TMP_ROOT/repo"
  mkdir -p "$WORK"
  (cd "$REPO_ROOT" && tar --exclude .git --exclude repomix-output.xml -cf - .) | (cd "$WORK" && tar -xf -)
  cd "$WORK"
  chmod +x bin/palari scripts/palari
  git init -b main >/dev/null
  git config user.email "bats@example.invalid"
  git config user.name "Bats Test"
  ./bin/palari init >/dev/null
  git add .
  git commit -m "initial" >/dev/null
}

teardown() {
  rm -rf "$TMP_ROOT"
}

@test "accept rejects forged evidence manifest" {
  ./bin/palari ticket create POS-0100 "Forged evidence" \
    --stream docs \
    --risk R1 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "manual forged evidence check" >/dev/null
  ./bin/palari ticket claim POS-0100 implementer >/dev/null
  mkdir -p reports/evidence/POS-0100
  printf 'forged log\n' > reports/evidence/POS-0100/verification.log
  printf '<testsuite tests="1" failures="0"></testsuite>\n' > reports/evidence/POS-0100/junit.xml
  printf '{"version":"2.1.0","runs":[]}\n' > reports/evidence/POS-0100/palari.sarif
  printf '{"ticket":"POS-0100","status":"passed","head_sha":"forged"}\n' > reports/evidence/POS-0100/manifest.json
  ./bin/palari ticket ready POS-0100 >/dev/null

  run ./bin/palari accept POS-0100 --by reviewer

  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid evidence manifest"* ]]
}

@test "palari ci writes an integrity manifest" {
  ./bin/palari ticket create POS-0101 "Integrity manifest" \
    --stream docs \
    --risk R1 \
    --allowed "tickets/**" \
    --allowed "reports/**" \
    --verify "manual integrity check" >/dev/null
  ./bin/palari ticket claim POS-0101 implementer >/dev/null

  run ./bin/palari ci POS-0101

  [ "$status" -eq 0 ]
  grep -Fq '"generator": "palari-ci"' reports/evidence/POS-0101/manifest.json
  grep -Fq '"sha256":' reports/evidence/POS-0101/manifest.json
}
