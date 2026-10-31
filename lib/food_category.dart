import 'package:flutter/material.dart';
import 'food_item_restaurants_page.dart';

class FoodCategory {
  final String name;
  final String imagePath;

  const FoodCategory(this.name, this.imagePath);
}

class FoodCategoryWidget extends StatelessWidget {
  const FoodCategoryWidget({super.key});

  static const List<FoodCategory> categories = [
    FoodCategory('Idli', 'assets/images/idli.jpg'),
    FoodCategory('Dosa', 'assets/images/Dosa.jpg'),
    FoodCategory('Pongal', 'assets/images/pongal.jpg'),
    FoodCategory('Vada', 'assets/images/vada.jpg'),
    FoodCategory('Coffee', 'assets/images/coffee.jpg'),
    FoodCategory('Poori', 'assets/images/poori.jpg'),
    FoodCategory('Biryani', 'assets/images/Briyani.jpg'),
    FoodCategory('Pizza', 'assets/images/Pizza.jpg'),
    FoodCategory('Burger', 'assets/images/Burger.jpg'),
    FoodCategory('Noodles', 'assets/images/Noodles.jpg'),
    FoodCategory('Rolls', 'assets/images/Rolls.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "What's on your mind?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodItemRestaurantsPage(
                            categoryName: category.name,
                            categoryImage: category.imagePath,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F1EC),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Image.asset(
                              category.imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}