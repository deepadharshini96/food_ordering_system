import 'package:flutter/material.dart';
import 'restaurant_data.dart';
import 'food_item_restaurants_page.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodItemRestaurantsPage(
          categoryName: query,
          select: (all) => searchRestaurants(all, query),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline with "Delivered" highlighted in orange
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E), // dark navy
                height: 1.2,
              ),
              children: [
                TextSpan(text: 'Order food & groceries. '),
                TextSpan(
                  text: 'Delivered',
                  style: TextStyle(color: Colors.deepOrange),
                ),
                TextSpan(text: ' to your door.'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          const Text(
            'Fast delivery • 500+ restaurants • Best prices',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // Search bar
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              hintText: 'Search for restaurants and food',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: _runSearch,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.deepOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}