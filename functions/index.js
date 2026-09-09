const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// Razorpay Initialization
const razorpay = new Razorpay({
    key_id: 'rzp_live_TUN2EGCy4mg6kn',
    key_secret: 'NgzygHKv7CLzLStEm697eu1u',
});

// Global options
setGlobalOptions({ region: "us-central1" });

/**
 * Trigger: Create Razorpay Order
 */
exports.createRazorpayOrder = onCall(async (request) => {
    const amount = request.data.amount; // In Paisa (e.g. 5000 for ₹50)
    const currency = request.data.currency || "INR";
    const appointmentId = request.data.appointmentId;
    const patientId = request.data.patientId;
    const receipt = `receipt_${Date.now()}`;

    if (!amount || !appointmentId || !patientId) {
        throw new HttpsError("invalid-argument", "Amount, appointmentId, and patientId are required");
    }

    try {
        const order = await razorpay.orders.create({
            amount: amount,
            currency: currency,
            receipt: receipt,
            notes: {
                appointmentId: appointmentId,
                patientId: patientId
            }
        });
        return order;
    } catch (error) {
        console.error("Razorpay Order Error:", error);
        throw new HttpsError("internal", "Failed to create Razorpay order");
    }
});

/**
 * Trigger: When an appointment status is updated
 */
exports.onappointmentstatusupdate = onDocumentUpdated("appointments/{appointmentId}", async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    if (newData.status !== oldData.status) {
        const status = newData.status;
        const patientId = newData.patientId;
        const doctorId = newData.doctorId;

        let doctorName = 'Doctor';
        const doctorUserSnap = await db.collection('users').where('doctorId', '==', doctorId).limit(1).get();
        if (!doctorUserSnap.empty) {
            doctorName = doctorUserSnap.docs[0].data().name;
        }

        const title = `Appointment ${status}`;
        const body = `Your appointment with Dr. ${doctorName} for ${newData.appointmentDate} is now ${status}.`;

        // 1. Notify Patient
        await sendPushNotification(patientId, 'patientId', title, body, {
            type: 'appointment_status',
            appointmentId: event.params.appointmentId
        });

        // 2. Notify Doctor if status becomes Confirmed (e.g. after payment)
        if (status === 'Confirmed') {
            const doctorUserSnap = await db.collection('users').where('doctorId', '==', doctorId).limit(1).get();
            if (!doctorUserSnap.empty && doctorUserSnap.docs[0].data().fcmToken) {
                await admin.messaging().send({
                    notification: {
                        title: 'New Booking Confirmed!',
                        body: `Appointment confirmed for ${newData.appointmentDate} at ${newData.timeSlot}.`,
                    },
                    token: doctorUserSnap.docs[0].data().fcmToken,
                    data: {
                        type: 'new_booking',
                        appointmentId: event.params.appointmentId,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                });
            }
        }
        return null;
    }
    return null;
});

const MSG91_AUTH_KEY = "566174ACoxByk72v6a955369P1";
const MSG91_TEMPLATE_ID = "6a95551467221b0f4e010bb2";
const WEBHOOK_SECRET = "AppointmentBooking_Secret_2025";

/**
 * Razorpay Webhook to verify and confirm payments
 */
exports.razorpayWebhook = onRequest(async (req, res) => {
    const signature = req.headers["x-razorpay-signature"];
    const body = JSON.stringify(req.body);

    const expectedSignature = crypto
        .createHmac("sha256", WEBHOOK_SECRET)
        .update(body)
        .digest("hex");

    if (signature !== expectedSignature) {
        console.error("Webhook Signature Mismatch!");
        return res.status(400).send("Invalid signature");
    }

    const event = req.body.event;
    console.log(`Received Razorpay Webhook Event: ${event}`);

    if (event === "payment.captured") {
        const paymentData = req.body.payload.payment.entity;
        const orderData = req.body.payload.order ? req.body.payload.order.entity : null;

        // Extract metadata from notes
        const notes = paymentData.notes || (orderData ? orderData.notes : {});
        const appointmentId = notes.appointmentId;
        const patientId = notes.patientId;

        if (appointmentId) {
            console.log(`Processing successful payment for Appointment: ${appointmentId}`);

            try {
                const batch = db.batch();

                // 1. Update Appointment
                const apptRef = db.collection('appointments').doc(appointmentId);
                batch.update(apptRef, {
                    status: 'Confirmed',
                    paymentStatus: 'Booking Charge Paid',
                    bookingCharge: paymentData.amount / 100, // Convert paisa to INR
                    transactionId: paymentData.id,
                    razorpayOrderId: paymentData.order_id,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // 2. Create Payment Record
                const paymentRef = db.collection('payments').doc();
                batch.set(paymentRef, {
                    appointmentId: appointmentId,
                    patientId: patientId || 'unknown',
                    amount: paymentData.amount / 100,
                    paymentMethod: paymentData.method,
                    transactionId: paymentData.id,
                    razorpayOrderId: paymentData.order_id,
                    paymentDate: new Date().toISOString(),
                    status: 'Success',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                await batch.commit();
                console.log(`Successfully verified and updated payment for ${appointmentId}`);
            } catch (err) {
                console.error("Error updating Firestore via Webhook:", err);
            }
        }
    }

    res.status(200).send("ok");
});

/**
 * Trigger: Send OTP via MSG91
 */
exports.sendMsg91Otp = onCall(async (request) => {
    let mobile = request.data.mobile;
    if (!mobile) {
        throw new HttpsError("invalid-argument", "Mobile number is required.");
    }
    mobile = mobile.toString().trim();

    const url = `https://control.msg91.com/api/v5/otp?template_id=${MSG91_TEMPLATE_ID}&mobile=${mobile}&authkey=${MSG91_AUTH_KEY}`;

    try {
        const response = await fetch(url, { method: 'POST' });
        const result = await response.json();
        console.log(`Sent OTP to ${mobile}. Result:`, result);
        if (result.type === "success") {
            return { success: true, message: "OTP sent successfully" };
        } else {
            console.error("MSG91 Error:", result);
            throw new HttpsError("internal", result.message || "Failed to send OTP.");
        }
    } catch (error) {
        console.error("Fetch Error:", error);
        throw new HttpsError("internal", "Failed to communicate with SMS service.");
    }
});

/**
 * Trigger: Verify OTP via MSG91 and return Firebase Custom Token
 */
exports.verifyMsg91Otp = onCall(async (request) => {
    let mobile = request.data.mobile;
    let otp = request.data.otp;

    if (!mobile || !otp) {
        throw new HttpsError("invalid-argument", "Mobile number and OTP are required.");
    }
    mobile = mobile.toString().trim();
    otp = otp.toString().trim();

    // Use URLSearchParams for safe encoding
    const params = new URLSearchParams({
        otp: otp,
        mobile: mobile,
        authkey: MSG91_AUTH_KEY
    });

    const url = `https://control.msg91.com/api/v5/otp/verify?${params.toString()}`;

    try {
        console.log(`Verifying OTP for ${mobile}.`);
        const response = await fetch(url, { method: 'GET' });

        if (!response.ok) {
            const errorText = await response.text();
            console.error("MSG91 API Error:", response.status, errorText);
            throw new HttpsError("internal", `SMS Gateway Error: ${response.status}`, errorText);
        }

        const result = await response.json();
        console.log(`MSG91 Response for ${mobile}:`, JSON.stringify(result));

        if (result.type === "success") {
            // OTP verified.
            let mobileForSearch = mobile;
            if (mobile.startsWith("91") && mobile.length === 12) {
                mobileForSearch = mobile.substring(2);
            }

            console.log(`Step 1: Searching for user with mobile: ${mobileForSearch}`);
            try {
                const userSnap = await db.collection('users').where('mobile', '==', mobileForSearch).limit(1).get();

                if (!userSnap.empty) {
                    const userId = userSnap.docs[0].id;
                    console.log(`Step 2: User found (ID: ${userId}). Creating custom token...`);
                    const customToken = await admin.auth().createCustomToken(userId);
                    console.log(`Step 3: Token created successfully.`);
                    return { success: true, customToken: customToken, isRegistered: true };
                } else {
                    console.log("Step 2: User not found in Firestore users collection.");
                    return { success: true, isRegistered: false };
                }
            } catch (dbError) {
                console.error("Firestore/Auth Error:", dbError);
                throw new HttpsError("internal", "Database error occurred after verification.", dbError.message);
            }
        } else {
            console.error("MSG91 Verify Logic Error:", result);
            const msg = result.message || "Invalid OTP. Please enter the correct code.";
            throw new HttpsError("unauthenticated", msg);
        }
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("Fetch/Process Error:", error);
        throw new HttpsError("internal", "Verification failed. Please try again later.", error.message);
    }
});

/**
 * Trigger: When a user document is deleted from Firestore,
 * cleanup their Firebase Auth account automatically.
 */
exports.cleanupauthonuserdelete = onDocumentDeleted("users/{userId}", async (event) => {
    const userId = event.params.userId;
    try {
        await admin.auth().deleteUser(userId);
        console.log(`Successfully deleted auth user: ${userId}`);
    } catch (error) {
        console.error(`Error deleting auth user: ${userId}`, error);
    }
    return null;
});

/**
 * Trigger: When a new appointment is booked
 */
exports.onnewappointmentbooked = onDocumentCreated("appointments/{appointmentId}", async (event) => {
    const appointment = event.data.data();
    const appointmentId = event.params.appointmentId;

    const [doctorSnap, patientSnap] = await Promise.all([
        db.collection('users').where('doctorId', '==', appointment.doctorId).limit(1).get(),
        db.collection('users').where('patientId', '==', appointment.patientId).limit(1).get()
    ]);

    const doctorData = !doctorSnap.empty ? doctorSnap.docs[0].data() : null;
    const patientData = !patientSnap.empty ? patientSnap.docs[0].data() : null;

    const doctorName = doctorData ? doctorData.name : 'Doctor';
    const patientName = patientData ? patientData.name : 'Patient';

    // ONLY notify if the appointment is already Confirmed (e.g. Walk-in by receptionist)
    // If it's Pending (awaiting payment), skip notification for now.
    if (appointment.status !== 'Confirmed') {
        console.log(`Skipping notification for ${appointmentId} as it is in ${appointment.status} status.`);
        return null;
    }

    // 1. Notify Doctor
    if (doctorData && doctorData.fcmToken) {
        await admin.messaging().send({
            notification: {
                title: 'New Booking!',
                body: `New appointment: ${patientName} on ${appointment.appointmentDate} at ${appointment.timeSlot}.`,
            },
            token: doctorData.fcmToken,
            data: {
                type: 'new_booking',
                appointmentId: appointmentId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        });
    }

    // 2. Notify Patient
    if (patientData && patientData.fcmToken) {
        const patientTitle = 'Booking Successful!';
        const patientBody = `Your appointment with Dr. ${doctorName} is booked for ${appointment.appointmentDate} at ${appointment.timeSlot}.`;

        await admin.messaging().send({
            notification: { title: patientTitle, body: patientBody },
            token: patientData.fcmToken,
            data: {
                type: 'booking_confirmation',
                appointmentId: appointmentId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        });
    }
    return null;
});

/**
 * Trigger: When a payment is successfully made
 */
exports.onpaymentcreated = onDocumentCreated("payments/{paymentId}", async (event) => {
    const payment = event.data.data();
    const title = 'Payment Successful';
    const body = `Payment of ₹${payment.amount} for your appointment has been received. Transaction ID: ${payment.transactionId}`;

    return sendPushNotification(payment.patientId, 'patientId', title, body, {
        type: 'payment_success',
        paymentId: event.params.paymentId
    });
});

/**
 * Scheduler: Reminder for Upcoming Follow-up Date
 */
exports.upcomingfollowupreminder = onSchedule("0 8 * * *", async (event) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];

    const prescriptionsSnap = await db.collection('prescriptions')
        .where('followUpDate', '==', tomorrowStr)
        .get();

    if (prescriptionsSnap.empty) return null;

    const promises = [];
    prescriptionsSnap.forEach(doc => {
        const prescription = doc.data();
        const title = 'Follow-up Reminder';
        const body = `Reminder: You have a follow-up visit tomorrow with Dr. ${prescription.doctorName}.`;

        promises.push(sendPushNotification(prescription.patientId, 'patientId', title, body, {
            type: 'follow_up_reminder',
            prescriptionId: doc.id
        }));
    });

    return Promise.all(promises);
});

/**
 * Helper function
 */
async function sendPushNotification(id, idType, title, body, extraData = {}) {
    const userSnap = await db.collection('users').where(idType, '==', id).limit(1).get();
    if (userSnap.empty) return null;

    const userData = userSnap.docs[0].data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return null;

    const message = {
        notification: { title, body },
        data: {
            ...extraData,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: fcmToken,
    };

    try {
        await admin.messaging().send(message);
    } catch (error) {
        console.error(`Error sending to ${id}:`, error);
    }
}
