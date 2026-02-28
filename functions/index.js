const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * Scheduled function to handle overdue reservations (borrowed books).
 * Runs every day at 00:00 (midnight).
 */
exports.handleOverdueReservations = onSchedule("every day 00:00", async (event) => {
  const now = admin.firestore.Timestamp.now();

  try {
    const overdueSnapshot = await db.collection("reservations")
      .where("status", "==", "borrowed")
      .where("dueAt", "<", now)
      .get();

    if (overdueSnapshot.empty) {
      console.log("No overdue borrowings found.");
    } else {
      let processedCount = 0;
      for (const doc of overdueSnapshot.docs) {
        await db.runTransaction(async (transaction) => {
          const reservationRef = doc.ref;
          const reservation = doc.data();

          const userId = reservation.userId;
          const dueAtStr = reservation.dueAt.toDate();
          const nowStr = now.toDate();

          // Calculate late days
          let lateDays = Math.ceil((nowStr - dueAtStr) / (1000 * 60 * 60 * 24));
          if (lateDays < 1) lateDays = 1;

          const finePerDay = reservation.finePerDay || 0;
          const totalFine = lateDays * finePerDay;

          const walletRef = db.collection("users").doc(userId).collection("wallet").doc("default");
          const walletDoc = await transaction.get(walletRef);

          if (!walletDoc.exists) {
            console.error(`Wallet not found for user ${userId}`);
            return;
          }

          const walletData = walletDoc.data();
          let lockedDeposit = walletData.lockedDeposit || 0;
          let availableBalance = walletData.availableBalance || 0;

          // Deduct from deposit first
          let fineToDeductFromDeposit = Math.min(lockedDeposit, totalFine);
          let remainingFine = totalFine - fineToDeductFromDeposit;

          let newLockedDeposit = lockedDeposit - fineToDeductFromDeposit;
          let newAvailableBalance = availableBalance - remainingFine; // May go negative to represent debt

          transaction.update(reservationRef, {
            status: "overdue",
            fineAmount: totalFine
          });

          transaction.update(walletRef, {
            lockedDeposit: newLockedDeposit,
            availableBalance: newAvailableBalance,
            totalFinesPaid: admin.firestore.FieldValue.increment(totalFine),
            updatedAt: now
          });

          processedCount++;
        });
      }
      console.log(`Successfully processed ${processedCount} overdue borrowings.`);
    }
  } catch (error) {
    console.error("Error processing overdue borrowings:", error);
  }
});

/**
 * Scheduled function to expire unconfirmed reservations.
 * Runs every hour.
 */
exports.autoExpireReservations = onSchedule("every hour", async (event) => {
  const now = admin.firestore.Timestamp.now();

  try {
    const expiredSnapshot = await db.collection("reservations")
      .where("status", "==", "reserved")
      .where("expiresAt", "<", now)
      .get();

    if (expiredSnapshot.empty) {
      console.log("No expired reservations found.");
    } else {
      let expiredCount = 0;
      for (const doc of expiredSnapshot.docs) {
        await db.runTransaction(async (transaction) => {
          const reservationRef = doc.ref;
          const reservation = doc.data();
          const userId = reservation.userId;
          const bookId = reservation.bookId;
          const depositAmount = reservation.depositAmount || 0;

          const walletRef = db.collection("users").doc(userId).collection("wallet").doc("default");
          const bookRef = db.collection("books").doc(bookId);

          // Refund deposit
          transaction.update(walletRef, {
            availableBalance: admin.firestore.FieldValue.increment(depositAmount),
            lockedDeposit: admin.firestore.FieldValue.increment(-depositAmount),
            updatedAt: now
          });

          // Return book copy
          transaction.update(bookRef, {
            availableCopies: admin.firestore.FieldValue.increment(1)
          });

          // Mark as expired
          transaction.update(reservationRef, {
            status: "expired",
            returnedAt: now
          });

          expiredCount++;
        });
      }
      console.log(`Successfully expired ${expiredCount} reservations.`);
    }
  } catch (error) {
    console.error("Error expiring reservations:", error);
  }
});
