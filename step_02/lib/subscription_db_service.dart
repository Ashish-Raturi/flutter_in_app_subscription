import 'package:cloud_firestore/cloud_firestore.dart';
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
    });
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
}
