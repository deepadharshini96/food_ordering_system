import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'restaurant_data.dart';

// ============================================================
// LIVE RESTAURANT DATA — reads/writes Firebase Realtime Database
// under the `restaurants/` node.
//
// Structure in the DB:
// restaurants/
//   <restaurantId>/
//     name, bgColor, location, rating, deliveryTime, offerTag
//     menu/
//       <menuItemId>/ { name, price, imagePath }
//
// Add, edit, or remove a restaurant or menu item straight in the
// Firebase console (Realtime Database tab) and every screen using
// watchRestaurants() updates automatically, no app rebuild needed.
// ============================================================

class RestaurantRepository {
  RestaurantRepository._internal();
  static final RestaurantRepository instance = RestaurantRepository._internal();

  // Same Realtime Database instance/URL your sign_in_page.dart already
  // uses for user records, so everything lives in one database.
  final DatabaseReference _ref = FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL:
        'https://food-ordering-app-5c822-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('restaurants');

  // Live stream of every restaurant. Emits a new list any time
  // anything under restaurants/ changes.
  Stream<List<Restaurant>> watchRestaurants() {
    return _ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <Restaurant>[];

      final map = Map<dynamic, dynamic>.from(raw as Map);
      return map.entries
          .where((e) => e.value is Map)
          .map((e) => Restaurant.fromMap(
              e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
    });
  }

  // One-time write of sample data, so you don't have to type
  // everything into the Firebase console by hand. Call this ONCE
  // (e.g. from a temporary debug button), then remove the call —
  // running it again just overwrites restaurants/ with the same data.
  Future<void> seedSampleData() async {
    final data = <String, dynamic>{
      for (final r in _sampleRestaurants) r.id: r.toMap(),
    };
    await _ref.set(data);
  }

  // ---- Admin-only write operations ----

  // Creates a new restaurant or overwrites an existing one (matched
  // by restaurant.id). Used by the admin panel's "Save" button.
  Future<void> saveRestaurant(Restaurant restaurant) async {
    await _ref.child(restaurant.id).set(restaurant.toMap());
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    await _ref.child(restaurantId).remove();
  }

  // Adds or overwrites a single menu item under a restaurant, without
  // touching the rest of that restaurant's data.
  Future<void> saveMenuItem(String restaurantId, MenuItem item) async {
    await _ref.child('$restaurantId/menu/${item.id}').set(item.toMap());
  }

  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    await _ref.child('$restaurantId/menu/$itemId').remove();
  }
}

// ============================================================
// SAMPLE DATA — used only by seedSampleData(). Feel free to add
// more restaurants/menu items here before seeding, or just edit
// them directly in the Firebase console afterwards.
//
// Image paths point at assets/images/<file> — matching what's
// currently in your assets/images folder. Items without a matching
// photo yet (e.g. Homely Food) are left with imagePath: null and
// will show a fallback icon in the UI instead of breaking.
// ============================================================

const List<Restaurant> _sampleRestaurants = [
  Restaurant(
    id: 'saravana-bhavan',
    name: 'Saravana Bhavan',
    bgColor: Color(0xFFFFE8D6),
    location: 'T. Nagar',
    rating: 4.3,
    deliveryTime: '25-30 min',
    offerTag: '50% OFF up to ₹100',
    menu: [
      MenuItem(id: 'homely-food', name: 'Homely Food', price: 120),
      MenuItem(id: 'idli', name: 'Idli', price: 40, imagePath: 'assets/images/idli.jpg'),
      MenuItem(id: 'dosa', name: 'Dosa', price: 60, imagePath: 'assets/images/Dosa.jpg'),
      MenuItem(id: 'pongal', name: 'Pongal', price: 50, imagePath: 'assets/images/pongal.jpg'),
      MenuItem(id: 'vada', name: 'Vada', price: 30, imagePath: 'assets/images/vada.jpg'),
      MenuItem(id: 'poori', name: 'Poori', price: 55, imagePath: 'assets/images/poori.jpg'),
    ],
  ),
  Restaurant(
    id: 'murugan-idli-shop',
    name: 'Murugan Idli Shop',
    bgColor: Color(0xFFFFF3CD),
    location: 'Adyar',
    rating: 4.5,
    deliveryTime: '20-25 min',
    offerTag: 'Free delivery',
    menu: [
      MenuItem(id: 'idli', name: 'Idli', price: 40, imagePath: 'assets/images/idli.jpg'),
      MenuItem(id: 'dosa', name: 'Dosa', price: 60, imagePath: 'assets/images/Dosa.jpg'),
      MenuItem(id: 'vada', name: 'Vada', price: 30, imagePath: 'assets/images/vada.jpg'),
      MenuItem(id: 'coffee', name: 'Coffee', price: 25, imagePath: 'assets/images/coffee.jpg'),
    ],
  ),
  Restaurant(
    id: 'cafe-coffee-day',
    name: 'Cafe Coffee Day',
    bgColor: Color(0xFFE0F7FA),
    location: 'Nungambakkam',
    rating: 4.0,
    deliveryTime: '15-20 min',
    offerTag: 'Buy 1 Get 1',
    menu: [
      MenuItem(id: 'coffee', name: 'Coffee', price: 25, imagePath: 'assets/images/coffee.jpg'),
    ],
  ),
  Restaurant(
    id: 'dosa-corner',
    name: 'Dosa Corner',
    bgColor: Color(0xFFF3E5F5),
    location: 'Velachery',
    rating: 4.2,
    deliveryTime: '30-35 min',
    offerTag: '',
    menu: [
      MenuItem(id: 'dosa', name: 'Dosa', price: 60, imagePath: 'assets/images/Dosa.jpg'),
      MenuItem(id: 'idli', name: 'Idli', price: 40, imagePath: 'assets/images/idli.jpg'),
      MenuItem(id: 'pongal', name: 'Pongal', price: 50, imagePath: 'assets/images/pongal.jpg'),
    ],
  ),
  Restaurant(
    id: 'curry-house',
    name: 'Curry House',
    bgColor: Color(0xFFE0F2E9),
    location: 'Anna Nagar',
    rating: 4.1,
    deliveryTime: '35-40 min',
    offerTag: 'Flat 20% OFF',
    menu: [
      MenuItem(id: 'pongal', name: 'Pongal', price: 50, imagePath: 'assets/images/pongal.jpg'),
      MenuItem(id: 'biryani', name: 'Biryani', price: 180, imagePath: 'assets/images/Briyani.jpg'),
      MenuItem(id: 'homely-food', name: 'Homely Food', price: 120),
    ],
  ),
  Restaurant(
    id: 'biryani-junction',
    name: 'Biryani Junction',
    bgColor: Color(0xFFFFE0E0),
    location: 'Besant Nagar',
    rating: 4.4,
    deliveryTime: '25-30 min',
    offerTag: 'Healthy picks',
    menu: [
      MenuItem(id: 'biryani', name: 'Biryani', price: 180, imagePath: 'assets/images/Briyani.jpg'),
      MenuItem(id: 'noodles', name: 'Noodles', price: 110, imagePath: 'assets/images/Noodles.jpg'),
      MenuItem(id: 'rolls', name: 'Rolls', price: 80, imagePath: 'assets/images/Rolls.jpg'),
    ],
  ),
  Restaurant(
    id: 'pizza-villa',
    name: 'Pizza Villa',
    bgColor: Color(0xFFFFE0E0),
    location: 'Anna Nagar',
    rating: 4.1,
    deliveryTime: '35-40 min',
    offerTag: 'Flat 20% OFF',
    menu: [
      MenuItem(id: 'pizza', name: 'Pizza', price: 220, imagePath: 'assets/images/Pizza.jpg'),
    ],
  ),
  Restaurant(
    id: 'burger-point',
    name: 'Burger Point',
    bgColor: Color(0xFFFFE8D6),
    location: 'T. Nagar',
    rating: 4.3,
    deliveryTime: '25-30 min',
    offerTag: '50% OFF up to ₹100',
    menu: [
      MenuItem(id: 'burger', name: 'Burger', price: 90, imagePath: 'assets/images/Burger.jpg'),
      MenuItem(id: 'noodles', name: 'Noodles', price: 110, imagePath: 'assets/images/Noodles.jpg'),
      MenuItem(id: 'rolls', name: 'Rolls', price: 80, imagePath: 'assets/images/Rolls.jpg'),
    ],
  ),
  Restaurant(
    id: 'noodle-house',
    name: 'Noodle House',
    bgColor: Color(0xFFE0F2E9),
    location: 'Velachery',
    rating: 4.0,
    deliveryTime: '20-25 min',
    offerTag: '',
    menu: [
      MenuItem(id: 'noodles', name: 'Noodles', price: 110, imagePath: 'assets/images/Noodles.jpg'),
      MenuItem(id: 'rolls', name: 'Rolls', price: 80, imagePath: 'assets/images/Rolls.jpg'),
    ],
  ),
  Restaurant(
    id: 'choco-house',
    name: 'Chocolate plaza',
    bgColor: Color(0xFFE0F2E9),
    location: 'Velachery',
    rating: 4.0,
    deliveryTime: '10-15 min',
    offerTag: '',
    menu: [
      MenuItem(id: 'choco', name: 'Chocolate', price: 100, imagePath: 'assets/images/Chocolate.jpg'),
      MenuItem(id: 'chocolates', name: 'Chocolates', price: 120, imagePath: 'assets/images/Chocolate.jpg'),
    ],
  ),
];