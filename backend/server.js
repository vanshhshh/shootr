const crypto = require("node:crypto");

const cors = require("cors");
const express = require("express");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");

const app = express();
const port = process.env.PORT || 8080;
const projectId = process.env.FIREBASE_PROJECT_ID || "shootr-app";

let firebaseReady = false;

function initializeFirebase() {
  if (firebaseReady) {
    return admin;
  }

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, "\n");
    }
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
    });
  } else {
    admin.initializeApp({ projectId });
  }

  firebaseReady = true;
  return admin;
}

function firestore() {
  return initializeFirebase().firestore();
}

function amountToPaise(amount) {
  const parsed = Number(amount);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    const error = new Error("Amount must be a positive number.");
    error.statusCode = 400;
    throw error;
  }
  return Math.round(parsed * 100);
}

function safeCompareHex(left, right) {
  const leftBuffer = Buffer.from(left || "", "hex");
  const rightBuffer = Buffer.from(right || "", "hex");
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    const error = new Error(`${name} is not configured.`);
    error.statusCode = 500;
    throw error;
  }
  return value;
}

function razorpayClient() {
  return new Razorpay({
    key_id: requireEnv("RAZORPAY_KEY_ID"),
    key_secret: requireEnv("RAZORPAY_KEY_SECRET"),
  });
}

function asyncHandler(handler) {
  return async (request, response, next) => {
    try {
      await handler(request, response, next);
    } catch (error) {
      next(error);
    }
  };
}

async function requireAuth(request, response, next) {
  const header = request.get("authorization") || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  if (!token) {
    response.status(401).json({ error: "Sign in before calling this endpoint." });
    return;
  }

  try {
    request.auth = await initializeFirebase().auth().verifyIdToken(token);
    next();
  } catch (error) {
    response.status(401).json({ error: "Firebase token verification failed." });
  }
}

function userIsAdmin(decodedToken) {
  return decodedToken.admin === true || decodedToken.role === "admin";
}

async function readBookingForUser(bookingId, decodedToken, allowedRole) {
  const bookingRef = firestore().doc(`bookings/${bookingId}`);
  const bookingSnapshot = await bookingRef.get();
  if (!bookingSnapshot.exists) {
    const error = new Error("Booking was not found.");
    error.statusCode = 404;
    throw error;
  }

  const booking = bookingSnapshot.data();
  const uid = decodedToken.uid;
  const allowed =
    userIsAdmin(decodedToken) ||
    (allowedRole === "client" && booking.clientId === uid) ||
    (allowedRole === "shootr" && booking.shootrId === uid);

  if (!allowed) {
    const error = new Error("You do not have access to this booking.");
    error.statusCode = 403;
    throw error;
  }

  return { bookingRef, booking };
}

async function writeNotification(id, notification) {
  const payload = {
    id,
    title: notification.title,
    body: notification.body,
    createdAt: new Date().toISOString(),
    targetRole: notification.targetRole || null,
    targetUserId: notification.targetUserId || null,
    read: false,
  };
  await firestore().doc(`notifications/${id}`).set(payload, { merge: true });
  await fanoutNotification(id, payload);
}

async function fanoutNotification(notificationId, notification) {
  const tokens = new Set();
  if (notification.targetUserId) {
    const userSnapshot = await firestore().doc(`users/${notification.targetUserId}`).get();
    const user = userSnapshot.data();
    for (const token of user && user.fcmTokens ? user.fcmTokens : []) {
      tokens.add(token);
    }
  } else if (notification.targetRole) {
    const usersSnapshot = await firestore()
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
    await initializeFirebase().messaging().sendEachForMulticast({
      tokens: tokenList.slice(index, index + 500),
      notification: {
        title: notification.title || "Shootr",
        body: notification.body || "",
      },
      data: {
        notificationId,
        targetRole: notification.targetRole || "",
      },
    });
  }
}

function configureCors() {
  const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

  if (allowedOrigins.length === 0) {
    return cors();
  }

  return cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error("Origin is not allowed."));
    },
  });
}

app.use(configureCors());

app.get("/health", (_request, response) => {
  response.json({ ok: true, service: "shootr-render-backend" });
});

app.post(
  "/api/razorpay-webhook",
  express.raw({ type: "application/json" }),
  asyncHandler(async (request, response) => {
    const signature = request.get("x-razorpay-signature") || "";
    const expected = crypto
      .createHmac("sha256", requireEnv("RAZORPAY_WEBHOOK_SECRET"))
      .update(request.body)
      .digest("hex");

    if (!safeCompareHex(signature, expected)) {
      response.status(401).send("Invalid signature");
      return;
    }

    const event = JSON.parse(request.body.toString("utf8"));
    const eventId =
      request.get("x-razorpay-event-id") ||
      `${event.event}_${event.created_at || Date.now()}`;
    const eventRef = firestore().doc(`razorpay_webhook_events/${eventId}`);

    try {
      await eventRef.create({
        event: event.event,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error.code === 6 || error.code === "already-exists") {
        response.status(200).send("Duplicate ignored");
        return;
      }
      throw error;
    }

    const payment = event.payload && event.payload.payment
      ? event.payload.payment.entity
      : null;

    if (payment && payment.order_id) {
      const orderSnapshot = await firestore()
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
          await firestore().doc(`bookings/${order.bookingId}`).set({
            paymentStatus: "paid",
            updatedAt: new Date().toISOString(),
          }, { merge: true });
        }
      }
    }

    response.status(200).send("ok");
  }),
);

app.use(express.json({ limit: "1mb" }));

app.post(
  "/api/create-razorpay-order",
  requireAuth,
  asyncHandler(async (request, response) => {
    const amountPaise = amountToPaise(request.body.amount);
    const currency = String(request.body.currency || "INR").toUpperCase();
    const bookingId = String(request.body.bookingId || "");
    const receipt = String(request.body.receipt || bookingId || `shootr_${Date.now()}`).slice(0, 40);

    if (bookingId) {
      await readBookingForUser(bookingId, request.auth, "client");
    }

    const order = await razorpayClient().orders.create({
      amount: amountPaise,
      currency,
      receipt,
      notes: {
        bookingId,
        uid: request.auth.uid,
        source: "shootr_flutter_render",
      },
    });

    await firestore().doc(`payment_orders/${order.id}`).set({
      userId: request.auth.uid,
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

    response.json({
      keyId: requireEnv("RAZORPAY_KEY_ID"),
      orderId: order.id,
      amount: amountPaise,
      currency,
    });
  }),
);

app.post(
  "/api/verify-razorpay-payment",
  requireAuth,
  asyncHandler(async (request, response) => {
    const orderId = String(request.body.orderId || "");
    const paymentId = String(request.body.paymentId || "");
    const signature = String(request.body.signature || "");

    if (!orderId || !paymentId || !signature) {
      response.status(400).json({ error: "orderId, paymentId, and signature are required." });
      return;
    }

    const orderRef = firestore().doc(`payment_orders/${orderId}`);
    const orderSnapshot = await orderRef.get();
    if (!orderSnapshot.exists) {
      response.status(404).json({ error: "Payment order was not found." });
      return;
    }
    const order = orderSnapshot.data();
    if (order.userId !== request.auth.uid) {
      response.status(403).json({ error: "This payment order belongs to another user." });
      return;
    }

    const expected = crypto
      .createHmac("sha256", requireEnv("RAZORPAY_KEY_SECRET"))
      .update(`${orderId}|${paymentId}`)
      .digest("hex");

    if (!safeCompareHex(signature, expected)) {
      await orderRef.set({
        status: "signature_failed",
        razorpayPaymentId: paymentId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      response.status(403).json({ error: "Payment signature verification failed." });
      return;
    }

    await orderRef.set({
      status: "verified",
      razorpayPaymentId: paymentId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    if (order.bookingId) {
      await firestore().doc(`bookings/${order.bookingId}`).set({
        paymentStatus: "paid",
        updatedAt: new Date().toISOString(),
      }, { merge: true });
    }

    response.json({ verified: true });
  }),
);

app.post(
  "/api/bootstrap-admin-account",
  requireAuth,
  asyncHandler(async (request, response) => {
    const requestedEmail = String(request.auth.email || "").toLowerCase();
    const allowedEmail = requireEnv("BOOTSTRAP_ADMIN_EMAIL").trim().toLowerCase();

    if (!requestedEmail || requestedEmail !== allowedEmail) {
      response.status(403).json({ error: "This email is not allowed to bootstrap admin access." });
      return;
    }

    const userRecord = await initializeFirebase().auth().getUser(request.auth.uid);
    const now = new Date().toISOString();
    const profile = {
      id: request.auth.uid,
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

    await initializeFirebase().auth().setCustomUserClaims(request.auth.uid, {
      role: "admin",
      admin: true,
    });
    await firestore().doc(`users/${request.auth.uid}`).set(profile, { merge: true });

    response.json({ profile });
  }),
);

app.post(
  "/api/booking-created",
  requireAuth,
  asyncHandler(async (request, response) => {
    const bookingId = String(request.body.bookingId || "");
    const { booking } = await readBookingForUser(bookingId, request.auth, "client");

    await Promise.all([
      writeNotification(`ntf_${bookingId}_client`, {
        title: "Request sent",
        body: `Your ${booking.eventType || "shoot"} request is live. We'll update you when a Shootr accepts.`,
        targetRole: "client",
        targetUserId: booking.clientId,
      }),
      writeNotification(`ntf_${bookingId}_shootr`, {
        title: "New shoot request",
        body: `${booking.clientName || "A client"} requested ${booking.eventType || "a shoot"}.`,
        targetRole: "shootr",
      }),
      writeNotification(`ntf_${bookingId}_admin`, {
        title: "New booking created",
        body: `${booking.clientName || "Client"} requested ${booking.eventType || "a shoot"}.`,
        targetRole: "admin",
      }),
    ]);

    response.json({ notified: true });
  }),
);

app.post(
  "/api/booking-assigned",
  requireAuth,
  asyncHandler(async (request, response) => {
    const bookingId = String(request.body.bookingId || "");
    const { booking } = await readBookingForUser(bookingId, request.auth, "shootr");

    if (!booking.shootrId || booking.status !== "confirmed") {
      response.status(409).json({ error: "Booking is not assigned yet." });
      return;
    }

    await Promise.all([
      writeNotification(`ntf_${bookingId}_assigned_client`, {
        title: "Shootr assigned",
        body: `${booking.shootrName || "A Shootr"} accepted your ${booking.eventType || "shoot"} request.`,
        targetRole: "client",
        targetUserId: booking.clientId,
      }),
      writeNotification(`ntf_${bookingId}_assigned_shootr`, {
        title: "Booking accepted",
        body: `You accepted ${booking.clientName || "a client"}'s ${booking.eventType || "shoot"} request.`,
        targetRole: "shootr",
        targetUserId: booking.shootrId,
      }),
    ]);

    response.json({ notified: true });
  }),
);

app.use((error, _request, response, _next) => {
  const statusCode = error.statusCode || 500;
  const message = statusCode >= 500 ? "Backend request failed." : error.message;
  console.error(error.message);
  response.status(statusCode).json({ error: message });
});

app.listen(port, () => {
  console.log(`Shootr backend listening on ${port}`);
});
