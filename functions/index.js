const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Add to wishlist
exports.addToWishlist = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in to add to wishlist",
    );
  }

  const {productId} = data;
  if (!productId || typeof productId !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "productId is required and must be a string",
    );
  }

  const userId = context.auth.uid;
  const wishlistRef = admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("wishlist")
      .doc(productId);

  await wishlistRef.set({productId});
  return {success: true, productId};
});

// Remove from wishlist
exports.removeFromWishlist = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in to remove from wishlist",
    );
  }

  const {productId} = data;
  if (!productId || typeof productId !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "productId is required and must be a string",
    );
  }

  const userId = context.auth.uid;
  await admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("wishlist")
      .doc(productId)
      .delete();

  return {success: true, productId};
});

// Toggle wishlist (add or remove)
exports.toggleWishlist = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in",
    );
  }

  const {productId} = data;
  if (!productId || typeof productId !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "productId is required",
    );
  }

  const userId = context.auth.uid;
  const wishlistRef = admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("wishlist")
      .doc(productId);

  const doc = await wishlistRef.get();
  if (doc.exists) {
    await wishlistRef.delete();
    return {success: true, inWishlist: false};
  } else {
    await wishlistRef.set({productId});
    return {success: true, inWishlist: true};
  }
});
