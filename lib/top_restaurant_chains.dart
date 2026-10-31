import 'package:flutter/material.dart';
import 'restaurant_data.dart';
import 'restaurant_repository.dart';
import 'food_item_restaurants_page.dart';

class TopRestaurantChains extends StatelessWidget {
  const TopRestaurantChains({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Restaurant>>(
      stream: RestaurantRepository.instance.watchRestaurants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final chains = snapshot.data ?? const <Restaurant>[];
        return _buildSection(context, chains);
      },
    );
  }

  Widget _buildSection(BuildContext context, List<Restaurant> chains) {
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
              'Top restaurant chains in Chennai',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (chains.isEmpty)
            const SizedBox(
              height: 210,
              child: Center(child: Text('No restaurant chains found.')),
            )
          else
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: chains.length,
                itemBuilder: (context, index) {
                  final chain = chains[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RestaurantDetailPage(restaurant: chain),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 210,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Image + offer badge ──────────────────
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildCoverImage(chain),
                                ),
                                // Dark gradient + offer tag at bottom
                                if (chain.offerTag.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          bottom: Radius.circular(10),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0),
                                            Colors.black.withOpacity(0.75),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        chain.offerTag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ── Restaurant name ──────────────────────
                            Text(
                              chain.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // ── Rating + delivery time ───────────────
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.green, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${chain.rating}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                                Text(
                                  chain.deliveryTime,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // ── Location ─────────────────────────────
                            Text(
                              chain.location,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
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

  // ── Cover image builder ─────────────────────────────────────────────────────
  // Uses buildFoodImage() from restaurant_data.dart which already handles
  // both asset paths and http(s) URLs with loading + error states.
  // Falls back to a coloured placeholder with a restaurant icon if
  // no menu item has a photo yet.

  Widget _buildCoverImage(Restaurant chain) {
    final cover = chain.coverImage; // first menu item imagePath or null

    if (cover != null && cover.isNotEmpty) {
      // Use the shared helper — handles URL vs asset automatically
      return buildFoodImage(
        cover,
        width: 210,
        height: 120,
        fallbackIcon: Icons.restaurant,
        borderRadius: BorderRadius.circular(10),
      );
    }

    // No image at all — show branded placeholder using restaurant bgColor
    return Container(
      width: 210,
      height: 120,
      decoration: BoxDecoration(
        color: chain.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant, size: 40, color: Colors.white70),
          const SizedBox(height: 6),
          Text(
            chain.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
