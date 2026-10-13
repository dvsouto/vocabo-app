#!/usr/bin/env bash
# Runs the screens audit on macOS against the local vocabo-api Docker stack.
# Reuses the flashcards e2e user (run run_flashcards_e2e.sh first so it has
# words) and recreates an unverified user for the verification screen.
set -euo pipefail

EMAIL=${E2E_EMAIL:-e2e-flashcards@vocabo.test}
PASSWORD=${E2E_PASSWORD:-e2epass01}
UNVERIFIED=${AUDIT_UNVERIFIED_EMAIL:-audit-unverified@vocabo.test}
FREE=${AUDIT_FREE_EMAIL:-audit-free@vocabo.test}
LOCALE=${AUDIT_LOCALE:-en}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
APP_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
PSQL=(docker exec -i vocabo-postgres psql -U postgres -d vocabo -v ON_ERROR_STOP=1 -tA)

HASH=$(docker exec vocabo-api bun -e "console.log(await Bun.password.hash('$PASSWORD', { algorithm: 'bcrypt', cost: 10 }))")
"${PSQL[@]}" -c "delete from users where email = '$UNVERIFIED';" >/dev/null
"${PSQL[@]}" -c "insert into users (name, email, password) values ('Audit Unverified', '$UNVERIFIED', '$HASH');" >/dev/null
"${PSQL[@]}" -c "delete from users where email = '$FREE';" >/dev/null
"${PSQL[@]}" -c "insert into users (name, email, password, email_verified_at) values ('Audit Free', '$FREE', '$HASH', now());" >/dev/null
"${PSQL[@]}" -c "update users set interface_language = '$LOCALE' where email in ('$EMAIL', '$UNVERIFIED', '$FREE');" >/dev/null

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
  --dart-define=AUDIT_UNVERIFIED_EMAIL="$UNVERIFIED" \
  --dart-define=AUDIT_FREE_EMAIL="$FREE" \
  --dart-define=AUDIT_LOCALE="$LOCALE"

echo "Screenshots: $HOME/Library/Containers/com.vocabo.vocaboDesktop/Data/Documents/vocabo_audit/$LOCALE"
