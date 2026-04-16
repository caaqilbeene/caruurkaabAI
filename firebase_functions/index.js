const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const ADMIN_EMAILS = (process.env.ADMIN_EMAILS || "admin@caruurkaab.so")
    .split(",")
    .map((v) => v.trim().toLowerCase())
    .filter(Boolean);

function getAdminEmails() {
  return ADMIN_EMAILS;
}

function ensureAdminCaller(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Fadlan marka hore login samee.");
  }

  const adminEmails = getAdminEmails();
  if (adminEmails.length === 0) {
    throw new HttpsError(
        "failed-precondition",
        "ADMIN_EMAILS lama helin. Fadlan ku qor index.js ama env.",
    );
  }

  const email = String(request.auth.token.email || "").toLowerCase().trim();
  if (!email || !adminEmails.includes(email)) {
    throw new HttpsError(
        "permission-denied",
        "Kaliya admin ayaa tirtiri kara user.",
    );
  }
}

async function firebaseDeleteUser(userId, email) {
  let uid = null;

  try {
    if (email) {
      const user = await admin.auth().getUserByEmail(email);
      uid = user.uid;
    } else if (String(userId).includes("@")) {
      const user = await admin.auth().getUserByEmail(String(userId));
      uid = user.uid;
    } else {
      uid = String(userId);
    }
  } catch (e) {
    const code = e?.errorInfo?.code || "";
    if (code.includes("user-not-found")) {
      return {deleted: false, reason: "firebase-user-not-found"};
    }
    throw e;
  }

  if (!uid) return {deleted: false, reason: "uid-not-found"};

  try {
    await admin.auth().deleteUser(uid);
    return {deleted: true, uid};
  } catch (e) {
    const code = e?.errorInfo?.code || "";
    if (code.includes("user-not-found")) {
      return {deleted: false, reason: "firebase-user-not-found"};
    }
    throw e;
  }
}

exports.deleteUserEverywhere = onCall({
  region: "us-central1",
}, async (request) => {
  ensureAdminCaller(request);

  const payload = request.data || {};
  const userId = String(payload.userId || "").trim();
  const emailRaw = String(payload.email || "").trim().toLowerCase();
  const email = emailRaw || null;

  if (!userId) {
    throw new HttpsError("invalid-argument", "userId waa qasab.");
  }

  const firebaseResult = await firebaseDeleteUser(userId, email);

  return {
    ok: true,
    userId,
    firebase: firebaseResult,
    deletedFrom: ["firebase_auth"],
  };
});
