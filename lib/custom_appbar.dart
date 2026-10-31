import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_page.dart';
import 'cart_page.dart';
import 'location_picker.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String locationName = 'Nandambakkam';
  String locationSubtitle = 'Chennai, Tamil Nadu';

  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<LocationItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPicker(),
    );

    if (result != null) {
      setState(() {
        locationName = result.name;
        locationSubtitle = result.subtitle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F1EC),
      child: SafeArea(
        bottom: false, // only pad the top (status bar), not bottom
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: GestureDetector(
                  onTap: _openLocationPicker,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            locationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                      Text(
                        locationSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;

                  if (user == null) {
                    return TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black54,
                          builder: (context) => const SignInPage(),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  // Signed in — show a round avatar. Tapping it opens the
                  // same dialog, which now displays account info + Log Out
                  // since SignInPage detects there's already a signed-in user.
                  final displayName = user.displayName?.trim();
                  final initials = (displayName != null && displayName.isNotEmpty)
                      ? displayName[0].toUpperCase()
                      : (user.email?.isNotEmpty == true
                          ? user.email![0].toUpperCase()
                          : '?');

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (context) => const SignInPage(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.deepOrange.shade100,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}