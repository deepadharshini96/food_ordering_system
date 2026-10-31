import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_sender.dart';

// ============================================================
// MENU ITEM MODEL
// ============================================================

class MenuItem {
  final String id;
  final String name;
  final String? imagePath; // nullable — null means "no photo yet"
  final double price;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.imagePath,
  });

  factory MenuItem.fromMap(String id, Map<dynamic, dynamic> map) {
    final path = map['imagePath']?.toString();
    return MenuItem(
      id: id,
      name: (map['name'] ?? '').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imagePath: (path == null || path.isEmpty) ? null : path,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        if (imagePath != null) 'imagePath': imagePath,
      };
}

// ============================================================
// RESTAURANT MODEL
// ============================================================

// `menuItems` holds lowercase menu item names (derived from `menu`)
// so category/cuisine/search filtering can keep working the same
// way it did with the old static tag lists.
class Restaurant {
  final String id;
  final String name;
  final Color bgColor;
  final String location;
  final double rating;
  final String deliveryTime;
  final String offerTag;
  final List<MenuItem> menu;

  const Restaurant({
    required this.id,
    required this.name,
    required this.bgColor,
    required this.location,
    required this.rating,
    required this.deliveryTime,
    required this.offerTag,
    required this.menu,
  });

  List<String> get menuItems =>
      menu.map((item) => item.name.toLowerCase()).toList();

  // Used as a fallback thumbnail for restaurant cards — the first
  // menu item that actually has a photo, or null if none do.
  String? get coverImage {
    for (final item in menu) {
      if (item.imagePath != null) return item.imagePath;
    }
    return null;
  }

  factory Restaurant.fromMap(String id, Map<dynamic, dynamic> map) {
    final menuRaw = map['menu'];
    final menu = <MenuItem>[];
    if (menuRaw is Map) {
      menuRaw.forEach((key, value) {
        if (value is Map) {
          menu.add(MenuItem.fromMap(key.toString(), value));
        }
      });
    }

    return Restaurant(
      id: id,
      name: (map['name'] ?? '').toString(),
      bgColor: _colorFromHex(map['bgColor']?.toString()),
      location: (map['location'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      deliveryTime: (map['deliveryTime'] ?? '').toString(),
      offerTag: (map['offerTag'] ?? '').toString(),
      menu: menu,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'bgColor': _colorToHex(bgColor),
        'location': location,
        'rating': rating,
        'deliveryTime': deliveryTime,
        'offerTag': offerTag,
        'menu': {for (final item in menu) item.id: item.toMap()},
      };
}

Color _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFFF5F5F5);
  final cleaned = hex.replaceFirst('#', '');
  final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.parse(full, radix: 16));
}

String _colorToHex(Color color) {
  return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
}

// ============================================================
// FILTER HELPERS
// ============================================================
// These all take a `source` list (the current live snapshot from
// RestaurantRepository) instead of a hardcoded global, so results
// stay correct as data changes in real time.

// Category tap (e.g. "Idli") — exact tag match.
List<Restaurant> restaurantsForCategory(
    List<Restaurant> source, String category) {
  final target = category.toLowerCase().trim();
  return source.where((r) => r.menuItems.contains(target)).toList();
}

// Cuisine tap (e.g. "South Indian") — matches any tag mapped to that cuisine.
const Map<String, List<String>> cuisineTagMap = {
  'North Indian': ['biryani', 'homely food', 'pongal'],
  'South Indian': ['idli', 'dosa', 'pongal', 'vada', 'poori', 'homely food'],
  'Chinese': ['noodles', 'rolls'],
  'Italian': ['pizza'],
  'Continental': ['pizza', 'burger'],
  'Desserts': ['coffee'],
  'Fast Food': ['burger', 'pizza', 'noodles', 'rolls'],
  'Biryani': ['biryani'],
};

List<Restaurant> restaurantsForCuisine(
    List<Restaurant> source, String cuisine) {
  final tags = cuisineTagMap[cuisine] ?? const <String>[];
  if (tags.isEmpty) return [];
  return source
      .where((r) => r.menuItems.any((item) => tags.contains(item)))
      .toList();
}

// Free-text search bar — partial match on restaurant name or menu items.
List<Restaurant> searchRestaurants(List<Restaurant> source, String query) {
  final target = query.toLowerCase().trim();
  if (target.isEmpty) return [];
  return source.where((r) {
    final nameMatches = r.name.toLowerCase().contains(target);
    final menuMatches = r.menuItems.any((item) => item.contains(target));
    return nameMatches || menuMatches;
  }).toList();
}

// ============================================================
// CART MODEL
// ============================================================

// `id` should be unique per restaurant+menu item (e.g.
// "Murugan Idli Shop|idli-01") so the same dish from two different
// restaurants never collides.
class CartItem {
  final String id;
  final String name;
  final String? imagePath;
  final double price;
  final String restaurantName;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.restaurantName,
    this.imagePath,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
}

// App-wide singleton cart. Simple ChangeNotifier — no extra packages
// needed. Call CartModel.instance from anywhere.
class CartModel extends ChangeNotifier {
  CartModel._internal();
  static final CartModel instance = CartModel._internal();

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  int quantityOf(String id) => _items[id]?.quantity ?? 0;

  // Most food-delivery apps only let you order from one restaurant at
  // a time. Check this before adding items from a different place.
  bool canAddFrom(String restaurantName) =>
      _items.isEmpty || _items.values.first.restaurantName == restaurantName;

  void addItem({
    required String id,
    required String name,
    required double price,
    required String restaurantName,
    String? imagePath,
  }) {
    final isNewItem = !_items.containsKey(id);

    if (!isNewItem) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        price: price,
        restaurantName: restaurantName,
        imagePath: imagePath,
      );
    }
    notifyListeners();

    // Only push to Firebase on the FIRST add of this item — the Cloud
    // Function triggers on new entries (onCreate), so re-writing on
    // every quantity bump would either do nothing (if using set(),
    // since the key already exists) or spam extra writes for no
    // benefit. One notification per distinct item added is the
    // expected behavior here.
    if (isNewItem) {
      _pushCartItemToFirebase(
        id: id,
        name: name,
        price: price,
        imagePath: imagePath,
      );
      _sendCartNotification(itemName: name);
    }
  }

  // Sends a push notification straight from the app to THIS device's
  // own FCM token — no server/Cloud Function involved. Fire-and-forget:
  // failures are logged but never interrupt the cart flow.
  void _sendCartNotification({required String itemName}) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FcmSender.instance.sendNotification(
      token: token,
      title: 'Added to cart 🛒',
      body: '$itemName was added to your cart.',
    );
  }

  // Writes to cart/<uid>/<itemId> — a Cloud Function watches this path
  // and sends a push notification to the signed-in user automatically.
  // Does nothing if no one is signed in (guest browsing shouldn't
  // trigger notifications, and there's nowhere to send them anyway).
  void _pushCartItemToFirebase({
    required String id,
    required String name,
    required double price,
    String? imagePath,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instanceFor(
      app: FirebaseAuth.instance.app,
      databaseURL:
          'https://food-ordering-app-5c822-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('cart/${user.uid}/$id');

    ref.set({
      'name': name,
      'price': price,
      if (imagePath != null) 'imagePath': imagePath,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  void removeOne(String id) {
    final item = _items[id];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(id);
    } else {
      item.quantity--;
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// ============================================================
// SHARED IMAGE WIDGET
// Displays a food/restaurant image whether it's a bundled asset
// path (assets/images/...) or a real http(s) URL pasted in the
// admin panel. URL images load and update live; asset images are
// baked into the app at build time.
//
// Pass either `size` (for a square thumbnail) or both `width` and
// `height` (for a rectangular banner, e.g. restaurant cover photos).
// ============================================================

Widget buildFoodImage(
  String? path, {
  double? size,
  double? width,
  double? height,
  IconData fallbackIcon = Icons.fastfood,
  BorderRadius? borderRadius,
}) {
  final w = width ?? size ?? 40;
  final h = height ?? size ?? 40;
  final radius = borderRadius ?? BorderRadius.circular(8);

  if (path == null || path.isEmpty) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: w,
        height: h,
        color: Colors.grey.shade200,
        child: Icon(fallbackIcon, color: Colors.grey, size: (w < h ? w : h) * 0.5),
      ),
    );
  }

  final isUrl = path.startsWith('http://') || path.startsWith('https://');

  return ClipRRect(
    borderRadius: radius,
    child: isUrl
        ? Image.network(
            path,
            width: w,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: w,
              height: h,
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image,
                  color: Colors.grey, size: (w < h ? w : h) * 0.5),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: w,
                height: h,
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          )
        : Image.asset(path, width: w, height: h, fit: BoxFit.cover),
  );
}