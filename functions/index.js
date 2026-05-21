const crypto = require("node:crypto");

const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { HttpsError, onCall, onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const Razorpay = require("razorpay");

admin.initializeApp();
setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");
const razorpayWebhookSecret = defineSecret("RAZORPAY_WEBHOOK_SECRET");
const bootstrapAdminEmail = defineSecret("BOOTSTRAP_ADMIN_EMAIL");

const db = admin.firestore();

function assertAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before calling this function.");
  }
  return request.auth.uid;
}

function amountToPaise(amount) {
  const parsed = Number(amount);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new HttpsError("invalid-argument", "Amount must be a positive number.");
  }
  return Math.round(parsed * 100);
}

function safeCompareHex(left, right) {
  const leftBuffer = Buffer.from(left || "", "hex");
  const rightBuffer = Buffer.from(right || "", "hex");
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function razorpayClient() {
  return new Razorpay({
    key_id: razorpayKeyId.value(),
    key_secret: razorpayKeySecret.value(),
  });
}

exports.createRazorpayOrder = onCall(
  { secrets: [razorpayKeyId, razorpayKeySecret] },
  async (request) => {
    const uid = assertAuth(request);
    const data = request.data || {};
    const amountPaise = amountToPaise(data.amount);
    const currency = String(data.currency || "INR").toUpperCase();
    const bookingId = String(data.bookingId || "");
    const receipt = String(data.receipt || bookingId || `shootr_${Date.now()}`).slice(0, 40);

    const order = await razorpayClient().orders.create({
      amount: amountPaise,
      currency,
      receipt,
      notes: {
        bookingId,
        uid,
        source: "shootr_flutter",
      },
    });

    await db.doc(`payment_orders/${order.id}`).set({
      userId: uid,
      bookingId,
      amount: amountPaise,
      currency,
      receipt,
      gateway: "razorpay",
      razorpayOrderId: order.id,
      status: "created",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      keyId: razorpayKeyId.value(),
      orderId: order.id,
      amount: amountPaise,
      currency,
    };
  },
);

exports.bootstrapAdminAccount = onCall(
  { secrets: [bootstrapAdminEmail] },
  async (request) => {
    const uid = assertAuth(request);
    const requestedEmail = String(request.auth.token.email || "").toLowerCase();
    const allowedEmail = bootstrapAdminEmail.value().trim().toLowerCase();

    if (!requestedEmail || requestedEmail !== allowedEmail) {
      throw new HttpsError("permission-denied", "This email is not allowed to bootstrap admin access.");
    }

    const userRecord = await admin.auth().getUser(uid);
    const now = new Date().toISOString();
    const profile = {
      id: uid,
      role: "admin",
      name: userRecord.displayName || "Shootr Admin",
      phone: userRecord.phoneNumber || "",
      city: "Mumbai",
      state: "Maharashtra",
      country: "india",
      photoUrl:
        userRecord.photoURL ||
        "https://images.unsplash.com/photo-1560250097-0b93528c311a",
      activeSince: now,
      createdAt: now,
      updatedAt: now,
      accountStatus: "active",
      verified: true,
      backgroundVerified: true,
      identityStatus: "verified",
      deviceVerificationStatus: "verified",
      notificationPreferences: {
        bookingUpdates: true,
        promos: true,
        reminders: true,
        messages: true,
        safety: true,
        payouts: true,
      },
    };

    await admin.auth().setCustomUserClaims(uid, {
      role: "admin",
      admin: true,
    });
    await db.doc(`users/${uid}`).set(profile, { merge: true });

    return { profile };
  },
);

exports.verifyRazorpayPayment = onCall(
  { secrets: [razorpayKeySecret] },
  async (request) => {
    const uid = assertAuth(request);
    const data = request.data || {};
    const orderId = String(data.orderId || "");
    const paymentId = String(data.paymentId || "");
    const signature = String(data.signature || "");

    if (!orderId || !paymentId || !signature) {
      throw new HttpsError("invalid-argument", "orderId, paymentId, and signature are required.");
    }

    const orderRef = db.doc(`payment_orders/${orderId}`);
    const orderSnapshot = await orderRef.get();
    if (!orderSnapshot.exists) {
      throw new HttpsError("not-found", "Payment order was not found.");
    }
    const order = orderSnapshot.data();
    if (order.userId !== uid) {
      throw new HttpsError("permission-denied", "This payment order belongs to another user.");
    }

    const expected = crypto
      .createHmac("sha256", razorpayKeySecret.value())
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    if (!safeCompareHex(signature, expected)) {
      await orderRef.set({
        status: "signature_failed",
        razorpayPaymentId: paymentId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      throw new HttpsError("permission-denied", "Payment signature verification failed.");
    }

    await orderRef.set({
      status: "verified",
      razorpayPaymentId: paymentId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    if (order.bookingId) {
      await db.doc(`bookings/${order.bookingId}`).set({
        paymentStatus: "paid",
        updatedAt: new Date().toISOString(),
      }, { merge: true });
    }

    return { verified: true };
  },
);

exports.razorpayWebhook = onRequest(
  { secrets: [razorpayWebhookSecret] },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("Method not allowed");
      return;
    }

    const signature = request.get("x-razorpay-signature") || "";
    const expected = crypto
      .createHmac("sha256", razorpayWebhookSecret.value())
      .update(request.rawBody)
      .digest("hex");

    if (!safeCompareHex(signature, expected)) {
      response.status(401).send("Invalid signature");
      return;
    }

    const eventId =
      request.get("x-razorpay-event-id") ||
      `${request.body.event}_${request.body.created_at || Date.now()}`;
    const eventRef = db.doc(`razorpay_webhook_events/${eventId}`);

    try {
      await eventRef.create({
        event: request.body.event,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error.code === 6 || error.code === "already-exists") {
        response.status(200).send("Duplicate ignored");
        return;
      }
      throw error;
    }

    const payment = request.body.payload && request.body.payload.payment
      ? request.body.payload.payment.entity
      : null;

    if (payment && payment.order_id) {
      const orderSnapshot = await db
        .collection("payment_orders")
        .where("razorpayOrderId", "==", payment.order_id)
        .limit(1)
        .get();

      if (!orderSnapshot.empty) {
        const orderDoc = orderSnapshot.docs[0];
        const order = orderDoc.data();
        const status = payment.status === "captured" ? "captured" : payment.status;
        await orderDoc.ref.set({
          status,
          razorpayPaymentId: payment.id,
          webhookUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        if (status === "captured" && order.bookingId) {
          await db.doc(`bookings/${order.bookingId}`).set({
            paymentStatus: "paid",
            updatedAt: new Date().toISOString(),
          }, { merge: true });
        }
      }
    }

    response.status(200).send("ok");
  },
);

exports.syncUserRoleClaims = onDocumentWritten("users/{userId}", async (event) => {
  const after = event.data && event.data.after.exists ? event.data.after.data() : null;
  const userId = event.params.userId;

  if (!after) {
    await admin.auth().setCustomUserClaims(userId, null);
    return;
  }

  const role = after.role || "client";
  await admin.auth().setCustomUserClaims(userId, {
    role,
    admin: role === "admin",
  });
});

exports.onBookingCreated = onDocumentCreated("bookings/{bookingId}", async (event) => {
  const booking = event.data ? event.data.data() : null;
  if (!booking) {
    return;
  }

  const now = new Date().toISOString();
  const writes = [
    {
      id: `ntf_${event.params.bookingId}_client`,
      title: "Request sent",
      body: `Your ${booking.eventType || "shoot"} request is live. We'll update you when a Shootr accepts.`,
      targetRole: "client",
      targetUserId: booking.clientId,
    },
    {
      id: `ntf_${event.params.bookingId}_shootr`,
      title: "New shoot request",
      body: `${booking.clientName || "A client"} requested ${booking.eventType || "a shoot"}.`,
      targetRole: "shootr",
    },
    {
      id: `ntf_${event.params.bookingId}_admin`,
      title: "New booking created",
      body: `${booking.clientName || "Client"} booked ${booking.shootrName || "Shootr"}.`,
      targetRole: "admin",
    },
  ];

  const batch = db.batch();
  for (const item of writes) {
    batch.set(db.doc(`notifications/${item.id}`), {
      id: item.id,
      title: item.title,
      body: item.body,
      createdAt: now,
      targetRole: item.targetRole,
      targetUserId: item.targetUserId || null,
      read: false,
    }, { merge: true });
  }
  await batch.commit();
});

exports.onBookingAssigned = onDocumentWritten("bookings/{bookingId}", async (event) => {
  const before = event.data && event.data.before.exists ? event.data.before.data() : null;
  const after = event.data && event.data.after.exists ? event.data.after.data() : null;
  if (!before || !after) {
    return;
  }
  const wasOpen = before.status === "pending" && !before.shootrId;
  const isAssigned = after.shootrId && after.status === "confirmed";
  if (!wasOpen || !isAssigned) {
    return;
  }

  const now = new Date().toISOString();
  const batch = db.batch();
  batch.set(db.doc(`notifications/ntf_${event.params.bookingId}_assigned_client`), {
    id: `ntf_${event.params.bookingId}_assigned_client`,
    title: "Shootr assigned",
    body: `${after.shootrName || "A Shootr"} accepted your ${after.eventType || "shoot"} request.`,
    createdAt: now,
    targetRole: "client",
    targetUserId: after.clientId,
    read: false,
  }, { merge: true });
  batch.set(db.doc(`notifications/ntf_${event.params.bookingId}_assigned_shootr`), {
    id: `ntf_${event.params.bookingId}_assigned_shootr`,
    title: "Booking accepted",
    body: `You accepted ${after.clientName || "a client"}'s ${after.eventType || "shoot"} request.`,
    createdAt: now,
    targetRole: "shootr",
    targetUserId: after.shootrId,
    read: false,
  }, { merge: true });
  await batch.commit();
});

exports.fanoutNotification = onDocumentCreated("notifications/{notificationId}", async (event) => {
  const notification = event.data ? event.data.data() : null;
  if (!notification) {
    return;
  }

  const tokens = new Set();
  if (notification.targetUserId) {
    const userSnapshot = await db.doc(`users/${notification.targetUserId}`).get();
    const user = userSnapshot.data();
    for (const token of user && user.fcmTokens ? user.fcmTokens : []) {
      tokens.add(token);
    }
  } else if (notification.targetRole) {
    const usersSnapshot = await db
      .collection("users")
      .where("role", "==", notification.targetRole)
      .where("accountStatus", "==", "active")
      .limit(500)
      .get();
    for (const userDoc of usersSnapshot.docs) {
      for (const token of userDoc.data().fcmTokens || []) {
        tokens.add(token);
      }
    }
  }

  const tokenList = [...tokens].filter(Boolean);
  for (let index = 0; index < tokenList.length; index += 500) {
    await admin.messaging().sendEachForMulticast({
      tokens: tokenList.slice(index, index + 500),
      notification: {
        title: notification.title || "Shootr",
        body: notification.body || "",
      },
      data: {
        notificationId: event.params.notificationId,
        targetRole: notification.targetRole || "",
      },
    });
  }
});
