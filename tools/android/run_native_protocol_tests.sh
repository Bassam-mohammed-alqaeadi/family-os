#!/usr/bin/env bash
# Runs the plain-JVM unit tests of the Android native layer without Gradle, Flutter,
# the Android SDK or google-services.json - none of which CI has for this repository.
#
# Only Android-free sources are compiled (listed below). Anything that imports android.*
# cannot be tested here and must not be added to SOURCES.
#
# Needs: java (17+) and kotlinc on PATH. JUnit 4 and Hamcrest are fetched from Maven
# Central and verified against pinned SHA-256 digests before use.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MAIN="app/android/app/src/main/kotlin/com/familyos/family_os"
TEST="app/android/app/src/test/kotlin/com/familyos/family_os"
SOURCES=("$MAIN/LocationFixProtocol.kt" "$MAIN/LocationSessionCoordinator.kt" "$MAIN/ResilientFixQueue.kt" "$MAIN/ServerTimeOffset.kt" "$MAIN/ProtectionStateMachine.kt" "$MAIN/BootBackoff.kt" "$MAIN/BatteryOemMap.kt" "$MAIN/FixQueuePort.kt" "$MAIN/FixQueueCipher.kt" "$MAIN/EncryptedFixQueueStore.kt")
TESTS=("$TEST/LocationFixProtocolTest.kt" "$TEST/LocationSessionCoordinatorTest.kt" "$TEST/ResilientFixQueueTest.kt" "$TEST/ServerTimeOffsetTest.kt" "$TEST/ProtectionStateMachineTest.kt" "$TEST/BootBackoffTest.kt" "$TEST/BatteryOemMapTest.kt" "$TEST/EncryptedFixQueueStoreTest.kt" "$TEST/ResilienceCoordinatorTest.kt")
TEST_CLASSES=("com.familyos.family_os.LocationFixProtocolTest" "com.familyos.family_os.LocationSessionCoordinatorTest" "com.familyos.family_os.ResilientFixQueueTest" "com.familyos.family_os.ServerTimeOffsetTest" "com.familyos.family_os.ProtectionStateMachineTest" "com.familyos.family_os.BootBackoffTest" "com.familyos.family_os.BatteryOemMapTest" "com.familyos.family_os.EncryptedFixQueueStoreTest" "com.familyos.family_os.ResilienceCoordinatorTest")

for source in "${SOURCES[@]}"; do
  if grep -qE '^import android\.|^import androidx\.' "$source"; then
    echo "::error::$source imports Android; it cannot run on the plain JVM." >&2
    exit 1
  fi
done

WORK="${NATIVE_TEST_WORK_DIR:-$(mktemp -d)}"
mkdir -p "$WORK/lib" "$WORK/classes"

fetch() {
  local url="$1" sha="$2" out="$WORK/lib/$(basename "$1")"
  if [ ! -f "$out" ]; then
    curl -fsSL --retry 3 -o "$out" "$url"
  fi
  echo "$sha  $out" | sha256sum -c --quiet -
}
fetch https://repo1.maven.org/maven2/junit/junit/4.13.2/junit-4.13.2.jar \
  8e495b634469d64fb8acfa3495a065cbacc8a0fff55ce1e31007be4c16dc57d3
fetch https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar \
  66fdef91e9739348df7a096aa384a5685f4e875584cce89386a7a47251c4d8e9

CLASSPATH="$WORK/lib/junit-4.13.2.jar:$WORK/lib/hamcrest-core-1.3.jar"
# TEMP-DIAG (revert after reading): surface tool output as annotations.
set +e
kotlinc -nowarn -cp "$CLASSPATH" -d "$WORK/classes" "${SOURCES[@]}" "${TESTS[@]}" >"$WORK/kotlinc.log" 2>&1
KOTLIN_STATUS=$?
set -e
if [ "$KOTLIN_STATUS" -ne 0 ]; then
  echo "::error title=TEMP kotlinc failed::$KOTLIN_STATUS"
  head -n 30 "$WORK/kotlinc.log" | sed 's/^/::error title=TEMP kotlinc::/'
  exit 1
fi
set +e
java -cp "$WORK/classes:$CLASSPATH:$(dirname "$(command -v kotlinc)")/../lib/kotlin-stdlib.jar" \
  org.junit.runner.JUnitCore "${TEST_CLASSES[@]}" >"$WORK/junit.log" 2>&1
JUNIT_STATUS=$?
set -e
if [ "$JUNIT_STATUS" -ne 0 ]; then
  echo "::error title=TEMP junit failed::$JUNIT_STATUS"
  head -n 40 "$WORK/junit.log" | sed 's/^/::error title=TEMP junit::/'
  exit 1
fi
tail -n 4 "$WORK/junit.log"
