#!/usr/bin/env bash
# Runs the flashcards end-to-end test on macOS against the local vocabo-api
# Docker stack. It recreates an isolated test user first so developer data is
# never touched, and signs the app ad hoc so no Apple Development certificate
# is required.
set -euo pipefail

EMAIL=${E2E_EMAIL:-e2e-flashcards@vocabo.test}
PASSWORD=${E2E_PASSWORD:-e2epass01}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
APP_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
PSQL=(docker exec -i vocabo-postgres psql -U postgres -d vocabo -v ON_ERROR_STOP=1 -tA)

OLD_ID=$("${PSQL[@]}" -c "select id from users where email = '$EMAIL';")
if [ -n "$OLD_ID" ]; then
  "${PSQL[@]}" -c "delete from user_vocabularies where user_id = '$OLD_ID'; delete from users where id = '$OLD_ID';" >/dev/null
  docker exec vocabo-mongodb mongosh --quiet -u mongoadmin -p mongoadmin --authenticationDatabase admin vocabo \
    --eval "db.customvocabularies.deleteMany({ user_id: '$OLD_ID' })" >/dev/null
fi

HASH=$(docker exec vocabo-api bun -e "console.log(await Bun.password.hash('$PASSWORD', { algorithm: 'bcrypt', cost: 10 }))")
"${PSQL[@]}" -c "insert into users (name, email, password) values ('E2E Flashcards', '$EMAIL', '$HASH');" >/dev/null
echo "e2e user ready: $EMAIL"

cd "$APP_DIR"
FLUTTER_XCODE_CODE_SIGN_IDENTITY=- \
FLUTTER_XCODE_CODE_SIGN_STYLE=Manual \
FLUTTER_XCODE_DEVELOPMENT_TEAM= \
FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER= \
FLUTTER_XCODE_CODE_SIGN_ENTITLEMENTS="$SCRIPT_DIR/adhoc.entitlements" \
  flutter test integration_test/flashcards_e2e_test.dart -d macos \
  --dart-define-from-file=.env \
  --dart-define=E2E_EMAIL="$EMAIL" \
  --dart-define=E2E_PASSWORD="$PASSWORD"

echo "Screenshots: $HOME/Library/Containers/com.vocabo.vocaboDesktop/Data/tmp/vocabo_e2e"
