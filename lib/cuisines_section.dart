import 'package:flutter/material.dart';
import 'restaurant_data.dart';
import 'food_item_restaurants_page.dart';

class CuisinesSection extends StatefulWidget {
  const CuisinesSection({super.key});

  @override
  State<CuisinesSection> createState() => _CuisinesSectionState();
}

class _CuisinesSectionState extends State<CuisinesSection> {
  // Static sample data — replace with your own list, or pass it in
  // via the widget constructor if you want this to be reusable.
  final List<String> _cuisineNames = const [
    'North Indian',
    'South Indian',
    'Chinese',
    'Italian',
    'Continental',
    'Desserts',
    'Fast Food',
    'Biryani',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Cuisines Near Me',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          if (_cuisineNames.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No cuisines found.'),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cuisineNames.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (context, index) {
                return _CuisineButton(cuisineName: _cuisineNames[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _CuisineButton extends StatelessWidget {
  final String cuisineName;

  const _CuisineButton({required this.cuisineName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodItemRestaurantsPage(
              categoryName: cuisineName,
              select: (all) => restaurantsForCuisine(all, cuisineName),
            ),
          ),
        );
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400, width: 1),
          color: Colors.white,
        ),
        child: Text(
          '$cuisineName Restaurant Near Me',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}