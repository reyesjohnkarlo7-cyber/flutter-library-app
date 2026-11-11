import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_books_page.dart';
import 'members_page.dart';
import 'settings_page.dart';
import 'borrow_book_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF003B7A);
    const accentBlue = Color(0xFFE6F0FA);
    final user = FirebaseAuth.instance.currentUser;
    final adminName = user?.displayName ?? user?.email?.split('@').first ?? 'Admin User';

    // Screen width helper for responsiveness across devices
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Modern Gradient Header Bar with Curved Transition
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: isTabletOrWeb ? 190 : 160,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00224D), primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isTabletOrWeb ? 32.0 : 20.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Library Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                            ),
                            icon: Icon(Icons.account_circle, color: Colors.white, size: isTabletOrWeb ? 32 : 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: HeaderWaveClipper(),
                    child: Container(
                      height: 25,
                      color: const Color(0xFFF4F7FB),
                    ),
                  ),
                ),
              ],
            ),

            // Main Content Area Container with Max Width Constraint for Tablets/Web
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: EdgeInsets.symmetric(horizontal: isTabletOrWeb ? 32.0 : 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Greeting Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: accentBlue,
                            child: const Icon(Icons.security, color: primaryBlue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back, Admin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  adminName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isTabletOrWeb ? 22 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title: Overview Statistics
                    const Text(
                      'System Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats Cards Row (Total Books & Total Borrowed)
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('books').snapshots(),
                            builder: (context, snapshot) {
                              int totalBooks = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              return _StatCard(
                                title: 'Total Books',
                                count: '$totalBooks',
                                icon: Icons.menu_book_rounded,
                                iconColor: primaryBlue,
                                bgColor: accentBlue,
                                isTabletOrWeb: isTabletOrWeb,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('borrowed_books').snapshots(),
                            builder: (context, snapshot) {
                              int totalBorrowed = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              return _StatCard(
                                title: 'Active Borrows',
                                count: '$totalBorrowed',
                                icon: Icons.bookmark_added_rounded,
                                iconColor: Colors.orange.shade800,
                                bgColor: Colors.orange.shade50,
                                isTabletOrWeb: isTabletOrWeb,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Section Title: Quick Management Actions
                    const Text(
                      'Quick Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Access Cards Grid (2 columns on mobile, 4 columns on tablet/web)
                    GridView.count(
                      crossAxisCount: isTabletOrWeb ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isTabletOrWeb ? 1.1 : 1.25,
                      children: [
                        _QuickAccessCard(
                          icon: Icons.library_books_rounded,
                          label: 'Manage Books',
                          color: primaryBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageBooksPage()),
                            );
                          },
                        ),
                        _QuickAccessCard(
                          icon: Icons.bookmark_add_rounded,
                          label: 'Borrow / Return',
                          color: Colors.teal.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BorrowBookPage()),
                            );
                          },
                        ),
                        _QuickAccessCard(
                          icon: Icons.people_alt_rounded,
                          label: 'Members',
                          color: Colors.indigo.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MembersPage()),
                            );
                          },
                        ),
                        _QuickAccessCard(
                          icon: Icons.settings_suggest_rounded,
                          label: 'Settings',
                          color: Colors.blueGrey.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isTabletOrWeb;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isTabletOrWeb,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF003B7A);

    return Container(
      padding: EdgeInsets.all(isTabletOrWeb ? 22 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isTabletOrWeb ? 30 : 24),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: isTabletOrWeb ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: isTabletOrWeb ? 16 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isTabletOrWeb ? 15 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width,
      size.height,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}