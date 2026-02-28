import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'wallet_screen.dart';
import 'library_id_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Avatar card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user.isAdmin ? '⭐ Administrator' : 'Member',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: user.isAdmin ? const Color(0xFFB45309) : AppColors.primary,
                        ),
                      ),
                    ),
                    if (!user.isAdmin) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatColumn(
                                  label: 'Total Borrows',
                                  value: user.booksBorrowed.toString(),
                                  icon: Icons.menu_book_rounded,
                                  color: AppColors.primary,
                                ),
                                Container(width: 1, height: 40, color: Colors.grey.shade300),
                                _StatColumn(
                                  label: 'Reading Streak',
                                  value: '${user.readingStreak} Days',
                                  icon: Icons.local_fire_department_rounded,
                                  color: Colors.deepOrange,
                                ),
                              ],
                            ),
                            if (user.badges.isNotEmpty) ...[
                              const Divider(height: 32),
                              Text('Unlocked Badges',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: user.badges.map((badge) {
                                  IconData icon = Icons.star_rounded;
                                  Color color = Colors.orange;
                                  if (badge == 'Bookworm') {
                                    icon = Icons.menu_book_rounded;
                                    color = Colors.blue;
                                  } else if (badge == 'Early Bird') {
                                    icon = Icons.alarm_on_rounded;
                                    color = Colors.green;
                                  } else if (badge == 'Consistent Reader') {
                                    icon = Icons.local_fire_department_rounded;
                                    color = Colors.deepOrange;
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color.withAlpha(50)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 16, color: color),
                                        const SizedBox(width: 6),
                                        Text(
                                          badge,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu items
              if (!user.isAdmin) ...[
                _ProfileMenuItem(
                  icon: Icons.qr_code_2_rounded,
                  iconBgColor: const Color(0xFFE0E7FF),
                  iconColor: const Color(0xFF4F46E5),
                  title: 'My Library ID',
                  subtitle: 'Show QR code to librarian to borrow',
                  onTap: () {
                    Navigator.push(context, FadeSlideRoute(page: const LibraryIdScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _ProfileMenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF059669),
                  title: 'My Wallet',
                  subtitle: 'View balances, deposits & fines',
                  onTap: () {
                    Navigator.push(context, FadeSlideRoute(page: const WalletScreen()));
                  },
                ),
                const SizedBox(height: 12),
              ],

              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                iconBgColor: AppColors.infoLight,
                iconColor: AppColors.info,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        content: Text('Are you sure you want to logout?',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                      await authProvider.signOut();
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withAlpha(100)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
