import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_sender.dart';

// ============================================================
// ORDER STATUS NOTIFIER
//
// Watches orders/<uid>/ for status changes (e.g. "Placed" ->
// "Preparing" -> "Out for Delivery" -> "Delivered") and fires a
// push notification each time a status actually changes.
//
// IMPORTANT: this only works while the app is open — there's no
// Cloud Function here, so nothing runs if the app is fully closed.
// For real background delivery, this logic would need to move to a
// server-side Cloud Function instead (requires the Blaze plan).
//
// To test: place an order, then manually edit that order's "status"
// field in Firebase Console (Realtime Database > orders > <uid> >
// <orderId> > status) while the app is open — a notification should
// fire within a couple seconds.
// ============================================================

class OrderStatusNotifier {
  OrderStatusNotifier._internal();
  static final OrderStatusNotifier instance = OrderStatusNotifier._internal();

  // Remembers the last-seen status per order, so we only notify on
  // an actual CHANGE — not every time Firebase re-sends the same data.
  final Map<String, String> _lastKnownStatus = {};

  DatabaseReference? _ordersRef;

  void start() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _ordersRef = FirebaseDatabase.instanceFor(
      app: FirebaseAuth.instance.app,
      databaseURL:
          'https://food-ordering-app-5c822-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('orders/${user.uid}');

    // Fires whenever any field inside any order under this user
    // changes — we only care about "status".
    _ordersRef!.onChildChanged.listen((event) {
      final orderId = event.snapshot.key;
      final data = event.snapshot.value;
      if (orderId == null || data is! Map) return;

      final newStatus = data['status']?.toString();
      if (newStatus == null) return;

      final previousStatus = _lastKnownStatus[orderId];
      _lastKnownStatus[orderId] = newStatus;

      // Skip the very first read (previousStatus == null) so we
      // don't notify just from the listener attaching — only real
      // changes after that should notify.
      if (previousStatus != null && previousStatus != newStatus) {
        _notify(newStatus);
      }
    });

    // Also record initial statuses (without notifying) so the first
    // real change afterwards is detected correctly.
    _ordersRef!.once().then((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        data.forEach((orderId, orderData) {
          if (orderData is Map && orderData['status'] != null) {
            _lastKnownStatus[orderId.toString()] =
                orderData['status'].toString();
          }
        });
      }
    });
  }

  Future<void> _notify(String newStatus) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FcmSender.instance.sendNotification(
      token: token,
      title: 'Order update 📦',
      body: 'Your order status is now: $newStatus',
    );
  }
}