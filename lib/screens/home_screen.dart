import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'wallet_screen.dart';
import 'scan_book_screen.dart';
import 'profile_screen.dart';
import 'library_id_screen.dart';
import 'reading_stats_screen.dart';
import 'book_detail_screen.dart';
import '../providers/activity_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/recommendation_provider.dart';
import '../models/book.dart';
import '../utils/image_utils.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final authProvider = Provider.of<AppAuthProvider>(context);
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final leaderboardProvider = Provider.of<LeaderboardProvider>(context);
    final theme = Theme.of(context);
    final user = authProvider.currentUser;

    final activeReservationsCount =
        reservationProvider.activeReservations.length;

    // Trigger pre-caching 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allUrls = libraryProvider.allBooks.map((b) => b.coverUrl).toList();
      final recUrls = recommendationProvider.recommendedBooks.map((b) => b.coverUrl).toList();
      ImageUtils.preCacheImages(context, [...allUrls, ...recUrls]);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await libraryProvider.fetchBooks();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()} 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: theme.textTheme.bodySmall?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name
                                  : 'Reader',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.headlineSmall?.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (user != null && user.badges.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: user.badges.take(3).map((badge) {
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 12, color: color),
                                        const SizedBox(width: 4),
                                        Text(
                                          badge,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlideRoute(page: const ProfileScreen()),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Wallet Card — direct Firestore read for real-time accuracy
                  if (user != null && !user.isAdmin) ...[
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('wallet')
                          .doc('default')
                          .snapshots(),
                      builder: (context, snapshot) {
                        double available = 0.0;
                        double locked = 0.0;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          available = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
                          locked = (data['lockedDeposit'] as num?)?.toDouble() ?? 0.0;
                        }

                        return _WalletSummaryCard(
                          availableBalance: available,
                          lockedDeposit: locked,
                          onTap: () {
                            Navigator.push(
                              context,
                              FadeSlideRoute(page: const WalletScreen()),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      _QuickActionCard(
                        title: 'My\nLibrary ID',
                        icon: Icons.qr_code_2_rounded,
                        gradientColors: const [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2)
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlideRoute(page: const LibraryIdScreen()),
                          );
                        },
                      ),
                      _QuickActionCard(
                        title: 'Discover\nBooks',
                        icon: Icons.search_rounded,
                        gradientColors: const [
                          Color(0xFF3B82F6),
                          Color(0xFF2563EB)
                        ],
                        onTap: () => onNavigate(1),
                      ),
                      _QuickActionCard(
                        title: 'My\nReservations',
                        icon: Icons.bookmark_added_rounded,
                        gradientColors: const [
                          Color(0xFF14B8A6),
                          Color(0xFF0D9488)
                        ],
                        onTap: () => onNavigate(2),
                        badgeCount: activeReservationsCount,
                      ),
                      _QuickActionCard(
                        title: 'My\nBorrowings',
                        icon: Icons.menu_book_rounded,
                        gradientColors: const [
                          Color(0xFFF59E0B),
                          Color(0xFFD97706)
                        ],
                        onTap: () => onNavigate(3),
                      ),
                      _QuickActionCard(
                        title: 'Reading\nAnalytics',
                        icon: Icons.analytics_rounded,
                        gradientColors: const [
                          Color(0xFF3B82F6),
                          Color(0xFF2563EB)
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlideRoute(page: const ReadingStatsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Feature 1: Recommended For You
                  if (recommendationProvider.recommendedBooks.isNotEmpty) ...[
                    Text(
                      'Recommended For You',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendationProvider.recommendedBooks.length,
                        itemBuilder: (context, index) {
                          final book = recommendationProvider.recommendedBooks[index];
                          return _RecommendedBookCard(book: book);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Recent Additions
                  Text(
                    'Recent Additions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  libraryProvider.isLoading
                      ? Column(
                          children: List.generate(
                              3,
                              (_) => _BookShimmer()),
                        )
                      : libraryProvider.allBooks.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Icon(Icons.auto_stories_outlined,
                                        size: 48,
                                        color: theme.dividerColor),
                                    const SizedBox(height: 12),
                                    Text('No books available yet',
                                        style: TextStyle(
                                            color: theme.textTheme.bodySmall?.color)),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  libraryProvider.allBooks.take(3).length,
                              itemBuilder: (context, index) {
                                final book = libraryProvider.allBooks[index];
                                return _RecentBookTile(
                                  book: book,
                                  index: index,
                                );
                              },
                            ),
                  const SizedBox(height: 28),

                  // Feature 4: Top Readers Leaderboard
                  if (leaderboardProvider.topReaders.isNotEmpty) ...[
                    _LeaderboardSection(readers: leaderboardProvider.topReaders),
                    const SizedBox(height: 28),
                  ],

                  // Feature 3: Live Library Activity
                  _ActivityFeedSection(activities: activityProvider.activities),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Wallet Summary Card ───
class _WalletSummaryCard extends StatelessWidget {
  final double availableBalance;
  final double lockedDeposit;
  final VoidCallback onTap;

  const _WalletSummaryCard({
    required this.availableBalance,
    required this.lockedDeposit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.walletGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withAlpha(50),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Balance',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: availableBalance),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  '₹${value.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: _WalletChip(
                    label: 'Available',
                    amount: availableBalance,
                    color: const Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _WalletChip(
                    label: 'Locked',
                    amount: lockedDeposit,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _WalletChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: ₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Card ───
class _QuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final int? badgeCount;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badgeCount,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                  if (widget.badgeCount != null && widget.badgeCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.gradientColors[0],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.badgeCount.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      height: 1.3,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Book Tile ───
class _RecentBookTile extends StatelessWidget {
  final Book book;
  final int index;

  const _RecentBookTile({
    required this.book,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlideRoute(page: BookDetailScreen(book: book)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl,
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_library_rounded, size: 24, color: AppColors.primary.withAlpha(180)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature 1: Recommended Book Card ───
class _RecommendedBookCard extends StatelessWidget {
  final Book book;

  const _RecommendedBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlideRoute(page: BookDetailScreen(book: book)),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: book.coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade100,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.local_library_rounded, size: 40, color: AppColors.primary.withAlpha(180)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              book.genre.isNotEmpty ? book.genre : book.author,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature 4: Leaderboard Section ───
class _LeaderboardSection extends StatelessWidget {
  final List<dynamic> readers;

  const _LeaderboardSection({required this.readers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Readers This Month',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: readers.asMap().entries.map((entry) {
              final index = entry.key;
              final reader = entry.value;
              final Color rankColor = index == 0 
                  ? const Color(0xFFF59E0B) 
                  : index == 1 
                      ? const Color(0xFF94A3B8) 
                      : index == 2 
                          ? const Color(0xFFB45309) 
                          : theme.textTheme.bodySmall?.color ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rankColor.withAlpha(isDark ? 50 : 20),
                        shape: BoxShape.circle,
                        border: Border.all(color: rankColor.withAlpha(isDark ? 100 : 40), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withAlpha(30),
                      child: Text(
                        reader.name[0].toUpperCase(),
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reader.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Text(
                      '${reader.booksBorrowed} books',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    if (index == 0) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Feature 3: Activity Feed Section ───
class _ActivityFeedSection extends StatelessWidget {
  final List<dynamic> activities;

  const _ActivityFeedSection({required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Library Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            IconData icon = Icons.info_outline;
            Color color = Colors.grey;
            
            if (activity.actionType == 'borrowed') {
              icon = Icons.menu_book_rounded;
              color = AppColors.primary;
            } else if (activity.actionType == 'returned') {
              icon = Icons.check_circle_rounded;
              color = AppColors.success;
            } else if (activity.actionType == 'reserved') {
              icon = Icons.bookmark_rounded;
              color = AppColors.warning;
            } else if (activity.actionType == 'cancelled') {
              icon = Icons.cancel_rounded;
              color = AppColors.error;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                        children: [
                          TextSpan(text: activity.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: ' ${activity.actionType} '),
                          TextSpan(text: activity.bookTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Shimmer Placeholder ───
class _BookShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
