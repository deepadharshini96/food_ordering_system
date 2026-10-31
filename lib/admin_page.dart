import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'restaurant_data.dart';
import 'restaurant_repository.dart';

const List<String> kAvailableImages = [
  'assets/images/idli.jpg',
  'assets/images/Dosa.jpg',
  'assets/images/pongal.jpg',
  'assets/images/vada.jpg',
  'assets/images/poori.jpg',
  'assets/images/coffee.jpg',
  'assets/images/Briyani.jpg',
  'assets/images/Noodles.jpg',
  'assets/images/Rolls.jpg',
  'assets/images/Pizza.jpg',
  'assets/images/Burger.jpg',
  'assets/images/Chocolate.jpg',
];


class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Manage Restaurants'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: RestaurantRepository.instance.watchRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final restaurants = snapshot.data ?? [];
          if (restaurants.isEmpty) {
            return const Center(child: Text('No restaurants yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final r = restaurants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: r.bgColor,
                  child: const Icon(Icons.storefront, color: Colors.black54),
                ),
                title: Text(r.name),
                subtitle: Text('${r.location} • ${r.menu.length} items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminRestaurantEditPage(restaurant: r),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminRestaurantEditPage(restaurant: null),
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


class AdminRestaurantEditPage extends StatefulWidget {
  final Restaurant? restaurant; // null = creating a new one

  const AdminRestaurantEditPage({super.key, required this.restaurant});

  @override
  State<AdminRestaurantEditPage> createState() =>
      _AdminRestaurantEditPageState();
}

class _AdminRestaurantEditPageState extends State<AdminRestaurantEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _ratingController;
  late TextEditingController _deliveryTimeController;
  late TextEditingController _offerTagController;

  late List<MenuItem> _menu;
  bool get _isNew => widget.restaurant == null;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _nameController = TextEditingController(text: r?.name ?? '');
    _locationController = TextEditingController(text: r?.location ?? '');
    _ratingController =
        TextEditingController(text: r?.rating.toString() ?? '4.0');
    _deliveryTimeController =
        TextEditingController(text: r?.deliveryTime ?? '20-25 min');
    _offerTagController = TextEditingController(text: r?.offerTag ?? '');
    _menu = List<MenuItem>.from(r?.menu ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _ratingController.dispose();
    _deliveryTimeController.dispose();
    _offerTagController.dispose();
    super.dispose();
  }

  String _slugify(String name) => name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  Future<void> _saveRestaurant() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant name is required')),
      );
      return;
    }

    final id = widget.restaurant?.id ?? _slugify(_nameController.text);

    final restaurant = Restaurant(
      id: id,
      name: _nameController.text.trim(),
      bgColor: widget.restaurant?.bgColor ?? const Color(0xFFF5F5F5),
      location: _locationController.text.trim(),
      rating: double.tryParse(_ratingController.text) ?? 0,
      deliveryTime: _deliveryTimeController.text.trim(),
      offerTag: _offerTagController.text.trim(),
      menu: _menu,
    );

    await RestaurantRepository.instance.saveRestaurant(restaurant);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restaurant saved')),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteRestaurant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete restaurant?'),
        content: Text('This will permanently remove "${widget.restaurant!.name}" '
            'and its entire menu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RestaurantRepository.instance.deleteRestaurant(widget.restaurant!.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _addOrEditMenuItem({MenuItem? existing}) async {
    final result = await showDialog<MenuItem>(
      context: context,
      builder: (context) => _MenuItemDialog(existing: existing),
    );
    if (result != null) {
      setState(() {
        _menu.removeWhere((m) => m.id == result.id);
        _menu.add(result);
      });
    }
  }

  void _deleteMenuItem(MenuItem item) {
    setState(() => _menu.removeWhere((m) => m.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add Restaurant' : 'Edit Restaurant'),
        backgroundColor: Colors.deepOrange,
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteRestaurant,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Restaurant name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ratingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rating (e.g. 4.3)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _deliveryTimeController,
                  decoration: const InputDecoration(labelText: 'Delivery time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offerTagController,
            decoration: const InputDecoration(labelText: 'Offer tag (optional)'),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Menu Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _addOrEditMenuItem(),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ],
          ),
          if (_menu.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No menu items yet.'),
            )
          else
            ..._menu.map((item) => Card(
                  child: ListTile(
                    leading: buildFoodImage(item.imagePath, size: 40),
                    title: Text(item.name),
                    subtitle: Text('₹${item.price.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _addOrEditMenuItem(existing: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteMenuItem(item),
                        ),
                      ],
                    ),
                  ),
                )),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveRestaurant,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _isNew ? 'Create Restaurant' : 'Save Changes',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Small dialog for adding/editing a single menu item.
// ============================================================

class _MenuItemDialog extends StatefulWidget {
  final MenuItem? existing;

  const _MenuItemDialog({this.existing});

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _priceController =
        TextEditingController(text: widget.existing?.price.toString() ?? '');
    // Pre-fill the URL field only if the existing image is a URL —
    // bundled asset paths aren't meant to be edited here.
    final existingPath = widget.existing?.imagePath ?? '';
    final isExistingUrl =
        existingPath.startsWith('http://') || existingPath.startsWith('https://');
    _imageUrlController =
        TextEditingController(text: isExistingUrl ? existingPath : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String _slugify(String name) => name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add menu item' : 'Edit menu item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (paste a link)',
                hintText: 'https://...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tip: upload a photo to imgur.com and paste the direct '
                'image link here — updates instantly, no app rebuild.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            if (_imageUrlController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              buildFoodImage(_imageUrlController.text.trim(), size: 64),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            final id = widget.existing?.id ?? _slugify(_nameController.text);
            final url = _imageUrlController.text.trim();
            Navigator.pop(
              context,
              MenuItem(
                id: id,
                name: _nameController.text.trim(),
                price: double.tryParse(_priceController.text) ?? 0,
                imagePath: url.isEmpty ? null : url,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}