#!/usr/bin/env bash
# Runs the screens audit on macOS against the local vocabo-api Docker stack.
# Reuses the flashcards e2e user (run run_flashcards_e2e.sh first so it has
# words) and recreates an unverified user for the verification screen.
set -euo pipefail

EMAIL=${E2E_EMAIL:-e2e-flashcards@vocabo.test}
PASSWORD=${E2E_PASSWORD:-e2epass01}
UNVERIFIED=${AUDIT_UNVERIFIED_EMAIL:-audit-unverified@vocabo.test}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
APP_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
PSQL=(docker exec -i vocabo-postgres psql -U postgres -d vocabo -v ON_ERROR_STOP=1 -tA)

HASH=$(docker exec vocabo-api bun -e "console.log(await Bun.password.hash('$PASSWORD', { algorithm: 'bcrypt', cost: 10 }))")
"${PSQL[@]}" -c "delete from users where email = '$UNVERIFIED';" >/dev/null
"${PSQL[@]}" -c "insert into users (name, email, password) values ('Audit Unverified', '$UNVERIFIED', '$HASH');" >/dev/null

cd "$APP_DIR"
FLUTTER_XCODE_CODE_SIGN_IDENTITY=- \
FLUTTER_XCODE_CODE_SIGN_STYLE=Manual \
FLUTTER_XCODE_DEVELOPMENT_TEAM= \
FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER= \
FLUTTER_XCODE_CODE_SIGN_ENTITLEMENTS="$SCRIPT_DIR/adhoc.entitlements" \
  flutter test integration_test/screens_audit_test.dart -d macos \
  --dart-define-from-file=.env \
  --dart-define=E2E_EMAIL="$EMAIL" \
  --dart-define=E2E_PASSWORD="$PASSWORD" \
  --dart-define=AUDIT_UNVERIFIED_EMAIL="$UNVERIFIED"

echo "Screenshots: $HOME/Library/Containers/com.vocabo.vocaboDesktop/Data/tmp/vocabo_audit"
