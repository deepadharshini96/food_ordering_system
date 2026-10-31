import 'package:flutter/material.dart';

// ============================================================
// GENERIC STATIC INFO PAGE
// One reusable page layout for all the simple footer links —
// About Us, Careers, Terms & Conditions, etc. Just pass a title
// and a list of paragraphs.
// ============================================================

class InfoPage extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const InfoPage({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final p in paragraphs) ...[
            Text(
              p,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CONTENT — one entry per footer link label. Edit freely; this
// is placeholder text for a student/demo project.
// ============================================================

class FooterPageData {
  final String title;
  final List<String> paragraphs;
  const FooterPageData(this.title, this.paragraphs);
}

const Map<String, FooterPageData> footerPageContent = {
  'About Us': FooterPageData('About Us', [
    'FoodieGo is a food delivery platform connecting hungry customers with '
        'the best local restaurants across Chennai and beyond.',
    'Our mission is simple: make ordering food online fast, reliable, and '
        'enjoyable — from browsing menus to tracking your delivery in real time.',
    'This app was built as a learning project exploring Flutter, Firebase, '
        'and real-time systems, and continues to grow with new features.',
  ]),
  'Careers': FooterPageData('Careers', [
    'We\'re not currently hiring, but we love hearing from people who are '
        'passionate about food delivery, technology, and building great products.',
    'Interested in what we\'re building? Reach out through the Contact Us '
        'page and tell us a bit about yourself.',
  ]),
  'Team': FooterPageData('Our Team', [
    'FoodieGo is built and maintained by a small, focused team passionate '
        'about creating a smooth food ordering experience.',
    'From app development to restaurant partnerships, every part of '
        'FoodieGo is crafted with care.',
  ]),
  'Blog': FooterPageData('Blog', [
    'Our blog is coming soon! Check back for articles on food trends, '
        'restaurant spotlights, and behind-the-scenes updates from FoodieGo.',
  ]),
  'Help & Support': FooterPageData('Help & Support', [
    'Need help with an order, your account, or something else? We\'re here '
        'to help.',
    'Email us at support@foodiego.example.com and we\'ll get back to you as '
        'soon as possible.',
    'For urgent order issues, please use the order tracking screen for the '
        'fastest updates.',
  ]),
  'Partner with us': FooterPageData('Partner With Us', [
    'Own a restaurant and want to reach more customers? Partnering with '
        'FoodieGo lets you list your menu, receive orders, and grow your '
        'business online.',
    'Interested restaurant owners can reach out via the Help & Support page '
        'to start the conversation.',
  ]),
  'Ride with us': FooterPageData('Ride With Us', [
    'Want to deliver with FoodieGo? We\'re always looking for reliable '
        'delivery partners to join our growing network.',
    'Flexible hours, weekly payouts, and a simple sign-up process — '
        'delivery partner registration is coming soon.',
  ]),
  'Terms & Conditions': FooterPageData('Terms & Conditions', [
    'By using the FoodieGo app, you agree to use the service responsibly '
        'and provide accurate information when placing orders.',
    'Prices, availability, and delivery times shown in the app are '
        'estimates and may vary based on the restaurant and delivery partner.',
    'FoodieGo reserves the right to update these terms at any time. '
        'Continued use of the app after changes constitutes acceptance of '
        'the updated terms.',
  ]),
  'Cookie Policy': FooterPageData('Cookie Policy', [
    'FoodieGo may use local storage and similar technologies to remember '
        'your preferences, keep you signed in, and improve your experience '
        'within the app.',
    'We do not sell your data to third parties. Information collected is '
        'used solely to operate and improve the FoodieGo service.',
  ]),
  'Privacy Policy': FooterPageData('Privacy Policy', [
    'We collect basic account information (name, email, phone number) to '
        'create your account and process orders.',
    'Location data is used only to help you select a delivery address and '
        'show nearby restaurants — it is not shared with third parties '
        'beyond what\'s necessary to fulfill your order.',
    'Your order history and cart contents are stored securely and are only '
        'accessible to your own account.',
    'For any privacy-related questions, contact us via the Help & Support '
        'page.',
  ]),
};