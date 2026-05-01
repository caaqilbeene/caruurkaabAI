# Cloud Functions: Admin Utilities

Functions:
- `deleteUserEverywhere`

## Waxa ay qabato
- Firebase Auth: user delete
  - Supabase delete waxaa sameeya app-ka (fallback/cleanup).

## Setup (hal mar)
1. Terminal fur:
```bash
cd /Users/macbook/Desktop/CaruurKaabAI/firebase_functions
npm install
```

2. Admin email hadda code-ka ayuu ku jiraa:
```js
const ADMIN_EMAILS = (process.env.ADMIN_EMAILS || "admin@caruurkaab.so")
```

3. Deploy:
```bash
firebase deploy --only functions
```

## Flutter app
App-ku wuxuu wacayaa callable function:
- `deleteUserEverywhere`

File:
- `/Users/macbook/Desktop/CaruurKaabAI/caruurkaab_ai/lib/services/admin_user_delete_service.dart`

## Fiiro gaar ah
- Haddii function aan la deploy-gareyn, app-ku wuxuu soo saarayaa fariin qalad oo kuu sheegeysa.
- User la tirtiray hadduu dib isu diiwaan-geliyo, `student_registry` wuxuu siinayaa ID cusub (next sequence).
