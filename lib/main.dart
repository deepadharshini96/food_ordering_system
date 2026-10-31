import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'order_status_notifier.dart';
import 'admin_page.dart';
import 'custom_appbar.dart';
import 'hero_section.dart';
import 'food_category.dart';
import 'top_restaurant_chains.dart';
import 'restaurant_list_section.dart';
import 'cuisines_section.dart';
import 'footer.dart';

// Saves the current device's FCM token under this signed-in user's
// record, e.g. users/<uid>/fcmToken — so a Cloud Function later knows
// which device to notify. Safe to call anytime; does nothing if no
// one is signed in yet (token gets saved next time this runs, e.g.
// after sign-in or on next token refresh).
Future<void> _saveTokenForCurrentUser(String? token) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || token == null) return;

  final ref = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL:
        'https://food-ordering-app-5c822-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('users/${user.uid}/fcmToken');

  await ref.set(token);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Firebase Cloud Messaging setup ---
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  final token = await messaging.getToken();
  // ignore: avoid_print
  print('FCM TOKEN: $token');

  // Save the token now (works if a session is already restored) and
  // again any time sign-in state changes or the token itself refreshes.
  await _saveTokenForCurrentUser(token);
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    final currentToken = await FirebaseMessaging.instance.getToken();
    await _saveTokenForCurrentUser(currentToken);
    if (user != null) {
      OrderStatusNotifier.instance.start();
    }
  });
  FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenForCurrentUser);

  // If a session is already restored at launch, start listening right away.
  if (FirebaseAuth.instance.currentUser != null) {
    OrderStatusNotifier.instance.start();
  }

  // NOTE: without a local-notifications package, messages that arrive
  // while the app is OPEN (foreground) won't show a visible banner —
  // they'll just print here. Messages that arrive while the app is
  // backgrounded or fully closed WILL still show automatically in the
  // system notification tray — that part is handled natively by FCM,
  // no code needed.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // ignore: avoid_print
    print(
      'Foreground FCM message received: '
      '${message.notification?.title} — ${message.notification?.body}',
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          // Admin account signed in -> show the admin panel instead
          // of the normal customer-facing home screen.
          if (user != null && user.email == 'admin@gmail.com') {
            return const AdminHomePage();
          }

          return const _CustomerHome();
        },
      ),
    ); // MaterialApp
  }
}

class _CustomerHome extends StatelessWidget {
  const _CustomerHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroSection(),
            FoodCategoryWidget(),
            TopRestaurantChains(),
            RestaurantsSection(),
            CuisinesSection(),
            Footer(),
          ],
        ), // Column
      ), // SingleChildScrollView
    ); // Scaffold
  }
}