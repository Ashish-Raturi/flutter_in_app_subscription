import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionDbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveSubcriptionsDetails(PurchaseDetails purchaseDetails) async {
    _firestore.collection('user data').doc('nAsN8vurc82wHUokvYxq').set({
      'Subscription Details': {
        'error': purchaseDetails.error,
        'pendingCompletePurchase': purchaseDetails.pendingCompletePurchase,
        'productID': purchaseDetails.productID,
        'purchaseID': purchaseDetails.purchaseID,
        'status': purchaseDetails.status.index,
        'transactionDate': purchaseDetails.transactionDate,
        'localVerificationData':
            purchaseDetails.verificationData.localVerificationData,
        'serverVerificationData':
            purchaseDetails.verificationData.serverVerificationData,
        'source': purchaseDetails.verificationData.source,
        'datetime': Timestamp.now()
      }
    }, SetOptions(merge: true));
  }

  Stream<PurchaseDetails?> get fetchOldSubscriptionDetails {
    return _firestore
        .collection('user data')
        .doc('nAsN8vurc82wHUokvYxq')
        .snapshots()
        .map((e) => pdFromSnapshot(e));
  }

  PurchaseDetails? pdFromSnapshot(DocumentSnapshot ds) {
    var pd = ds.get('Subscription Details');

    PurchaseDetails oldPD = PurchaseDetails(
      productID: pd['productID'],
      purchaseID: pd['purchaseID'],
      status: PurchaseStatus.purchased,
      transactionDate: pd['transactionDate'],
      verificationData: PurchaseVerificationData(
          localVerificationData: pd['localVerificationData'],
          serverVerificationData: pd['serverVerificationData'],
          source: pd['source']),
    );

    oldPD.pendingCompletePurchase = true;
    return oldPD;
  }

  Future<bool> queryUserSubscriptionStatus(
      String serverVerificationData, String productId) async {
    String userUid = 'nAsN8vurc82wHUokvYxq';

    // Create a reference to the Purchase Collection
    var purchaseRef = _firestore.collection("purchases");

    // Create a query against the username.
    Query<Map<String, dynamic>> query =
        purchaseRef.where("userId", isEqualTo: userUid);

    QuerySnapshot querySnapshot = await query.get();
    bool subStatus = false;

    for (QueryDocumentSnapshot ds in querySnapshot.docs) {
      String status = ds.get('status');
      // "ACTIVE", // Payment received
      // "ACTIVE", // Free trial
      // "EXPIRED", // Expired or cancelled

      if (status == "ACTIVE") {
        subStatus = true;
        return subStatus;
      } else {
        subStatus = false;
      }
    }

    if (!subStatus) {
      //checking renew subscription
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('verifyPurchase');

      //verifying purchase
      callable.call({
        'source': Platform.isAndroid ? 'google_play' : 'app_store',
        'productId': productId,
        'uid': userUid,
        'verificationData': serverVerificationData
      });
    }

    return subStatus;
  }
}
