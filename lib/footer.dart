import 'package:flutter/material.dart';
import 'static_pages.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.delivery_dining, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'FoodieGo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _FooterColumnGroup(),

          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade800),
          const SizedBox(height: 16),

          Row(
            children: const [
              Icon(Icons.copyright, color: Colors.grey, size: 14),
              SizedBox(width: 4),
              Text(
                '2026 FoodieGo Limited',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _SocialIcon(icon: Icons.facebook),
              _SocialIcon(icon: Icons.camera_alt), // Instagram placeholder
              _SocialIcon(icon: Icons.link), // LinkedIn placeholder
              _SocialIcon(icon: Icons.play_circle_fill), // YouTube placeholder
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterColumnGroup extends StatelessWidget {
  const _FooterColumnGroup();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 24,
      children: const [
        _FooterColumn(
          title: 'Company',
          items: ['About Us', 'Careers', 'Team', 'Blog'],
        ),
        _FooterColumn(
          title: 'Contact us',
          items: ['Help & Support', 'Partner with us', 'Ride with us'],
        ),
        _FooterColumn(
          title: 'Legal',
          items: ['Terms & Conditions', 'Cookie Policy', 'Privacy Policy'],
        ),
        _FooterColumn(
          title: 'Available in',
          items: ['Chennai', 'Bengaluru', 'Hyderabad', 'Coimbatore'],
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  final content = footerPageContent[item];
                  if (content == null) return; // no page defined yet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InfoPage(
                        title: content.title,
                        paragraphs: content.paragraphs,
                      ),
                    ),
                  );
                },
                child: Text(
                  item,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;

  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade800,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}