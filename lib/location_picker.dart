import 'package:flutter/material.dart';

class LocationItem {
  final String name;
  final String subtitle;

  const LocationItem(this.name, this.subtitle);
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController searchController = TextEditingController();

  // Sample location list — replace with real data / API results
  final List<LocationItem> allLocations = const [
    LocationItem('Nandambakkam', 'Chennai, Tamil Nadu'),
    LocationItem('T Nagar', 'Chennai, Tamil Nadu'),
    LocationItem('Adyar', 'Chennai, Tamil Nadu'),
    LocationItem('Anna Nagar', 'Chennai, Tamil Nadu'),
  ];

  List<LocationItem> filteredLocations = [];

  @override
  void initState() {
    super.initState();
    filteredLocations = allLocations;
    searchController.addListener(_filterLocations);
  }

  void _filterLocations() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredLocations = allLocations
          .where((loc) => loc.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7EDE3), // light beige
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Search field
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search for area, locality...',
              prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
              filled: true,
              fillColor: const Color(0xFFF7EDE3),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.deepOrange),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.deepOrange),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Use current location button
          OutlinedButton.icon(
            onPressed: () {
              // TODO: hook up geolocation and return the detected location
              Navigator.pop(context, const LocationItem('Current Location', ''));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.my_location, color: Colors.deepOrange),
            label: const Text(
              'Use my current location',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // Location list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filteredLocations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = filteredLocations[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, color: Colors.black54),
                  title: Text(
                    location.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    location.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => Navigator.pop(context, location),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}