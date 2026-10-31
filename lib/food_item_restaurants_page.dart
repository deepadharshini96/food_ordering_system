import 'package:flutter/material.dart';
import 'restaurant_data.dart';
import 'restaurant_repository.dart';
import 'cart_page.dart';

// ============================================================
// RESULTS PAGE — restaurants serving a tapped food category
// (or a cuisine / search query, via the `select` override)
// ============================================================

class FoodItemRestaurantsPage extends StatelessWidget {
  final String categoryName; // e.g. "Idli", "South Indian", or a search term
  final String? categoryImage; // e.g. "assets/images/idli.jpg" — optional

  // Optional custom selector over the live restaurant list — used by
  // CuisinesSection (cuisine match) and the search bar (text match).
  // When omitted, defaults to an exact category/menu-tag match.
  final List<Restaurant> Function(List<Restaurant> all)? select;

  const FoodItemRestaurantsPage({
    super.key,
    required this.categoryName,
    this.categoryImage,
    this.select,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (categoryImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  categoryImage!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(categoryName),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<List<Restaurant>>(
        stream: RestaurantRepository.instance.watchRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Could not load restaurants: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            );
          }

          final all = snapshot.data ?? const <Restaurant>[];
          final results = select != null
              ? select!(all)
              : restaurantsForCategory(all, categoryName);

          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No restaurants currently serving $categoryName.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _RestaurantTile(restaurant: results[index]);
            },
          );
        },
      ),
    );
  }
}

// Small shared helper: shows a real photo when available, otherwise a
// plain fallback icon — used by the tile, detail header, and menu list.
Widget _thumbnail(String? imagePath, {required double size, required IconData fallbackIcon}) {
  return buildFoodImage(
    imagePath,
    size: size,
    fallbackIcon: fallbackIcon,
    borderRadius: BorderRadius.circular(10),
  );
}

class _RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantTile({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailPage(restaurant: restaurant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: restaurant.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: _thumbnail(
                  restaurant.coverImage,
                  size: 64,
                  fallbackIcon: Icons.restaurant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.location,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.green.shade700, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          restaurant.rating.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(' • ',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                          restaurant.deliveryTime,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (restaurant.offerTag.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        restaurant.offerTag,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RESTAURANT DETAIL PAGE — menu + add to cart
// ============================================================

class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final CartModel _cart = CartModel.instance;
  late final List<MenuItem> _menu;

  @override
  void initState() {
    super.initState();
    _menu = widget.restaurant.menu;
  }

  // Composite id so the same dish from two different restaurants
  // never collides in the shared cart.
  String _cartId(MenuItem item) => '${widget.restaurant.name}|${item.id}';

  void _addToCart(MenuItem item) {
    if (!_cart.canAddFrom(widget.restaurant.name)) {
      // Switching restaurants — clear the old cart and add this item
      // straight away, no confirmation popup.
      setState(() {
        _cart.clear();
        _cart.addItem(
          id: _cartId(item),
          name: item.name,
          price: item.price,
          restaurantName: widget.restaurant.name,
          imagePath: item.imagePath,
        );
      });
      return;
    }

    setState(() {
      _cart.addItem(
        id: _cartId(item),
        name: item.name,
        price: item.price,
        restaurantName: widget.restaurant.name,
        imagePath: item.imagePath,
      );
    });
  }

  void _removeFromCart(MenuItem item) {
    setState(() => _cart.removeOne(_cartId(item)));
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: restaurant.bgColor,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: restaurant.bgColor,
                alignment: Alignment.center,
                child: restaurant.coverImage != null
                    ? buildFoodImage(
                        restaurant.coverImage,
                        width: double.infinity,
                        height: 180,
                        fallbackIcon: Icons.restaurant,
                        borderRadius: BorderRadius.zero,
                      )
                    : const Icon(Icons.restaurant, size: 72, color: Colors.grey),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.rating}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text('  •  '),
                      Text(
                        restaurant.deliveryTime,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const Text('  •  '),
                      Expanded(
                        child: Text(
                          restaurant.location,
                          style: TextStyle(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (restaurant.offerTag.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        restaurant.offerTag,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _menu[index];
                final qty = _cart.quantityOf(_cartId(item));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _thumbnail(
                        item.imagePath,
                        size: 56,
                        fallbackIcon: Icons.fastfood,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      qty == 0
                          ? OutlinedButton(
                              onPressed: () => _addToCart(item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepOrange,
                                side: const BorderSide(color: Colors.deepOrange),
                              ),
                              child: const Text('ADD'),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.deepOrange),
                                  onPressed: () => _removeFromCart(item),
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: Colors.deepOrange),
                                  onPressed: () => _addToCart(item),
                                ),
                              ],
                            ),
                    ],
                  ),
                );
              },
              childCount: _menu.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      bottomNavigationBar: _cart.totalItems == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                    setState(() {}); // refresh quantities after returning
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_cart.totalItems} item${_cart.totalItems > 1 ? 's' : ''}'
                        '  •  ₹${_cart.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'View Cart  ›',
                        style:
                            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}