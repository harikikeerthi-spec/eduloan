import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification.dart';
import '../widgets/mesh_background.dart';
import '../services/notification_service.dart';
import 'main_navigation.dart';
import 'community_page.dart';
import 'document_vault_page.dart';
import 'my_loans_page.dart';
import 'profile_page.dart';
import 'refer_and_earn_page.dart';
import 'ai_tools/ai_tools_page.dart';
import 'ai_tools/visa_interview_page.dart';
import 'essential_service_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _notificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    final success = await _notificationService.markAsRead(id);
    if (success) {
      _loadNotifications();
    }
  }

  Future<void> _clearAll() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      _loadNotifications();
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // 1. Mark as read immediately
    _markAsRead(notification.id);

    if (!mounted) return;

    final titleLower = notification.title.toLowerCase();
    final bodyLower = notification.body.toLowerCase();

    // 2. Group / Forum / Community / Poll / Discussion / Mentorship
    if (notification.type == NotificationType.communityMessage ||
        titleLower.contains('group') ||
        titleLower.contains('community') ||
        titleLower.contains('poll') ||
        titleLower.contains('forum') ||
        titleLower.contains('mentor') ||
        titleLower.contains('chat') ||
        bodyLower.contains('group') ||
        bodyLower.contains('forum') ||
        bodyLower.contains('discussion') ||
        bodyLower.contains('poll')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityPage()),
      );
      return;
    }

    // 3. Documents / Vault / OCR / KYC
    if (titleLower.contains('document') ||
        titleLower.contains('vault') ||
        titleLower.contains('ocr') ||
        titleLower.contains('pan') ||
        titleLower.contains('aadhar') ||
        titleLower.contains('aadhaar') ||
        titleLower.contains('passport') ||
        titleLower.contains('marksheet') ||
        bodyLower.contains('document') ||
        bodyLower.contains('upload') ||
        bodyLower.contains('vault')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentVaultPage()),
      );
      return;
    }

    // 4. Visa Interview / Prep
    if (titleLower.contains('visa') ||
        titleLower.contains('interview') ||
        bodyLower.contains('visa') ||
        bodyLower.contains('consulate') ||
        bodyLower.contains('interview')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VisaInterviewPage()),
      );
      return;
    }

    // 5. Refer & Earn
    if (titleLower.contains('refer') ||
        titleLower.contains('reward') ||
        titleLower.contains('earn') ||
        bodyLower.contains('refer') ||
        bodyLower.contains('cashback')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReferAndEarnPage()),
      );
      return;
    }

    // 6. Essential Services (Forex, Housing, Flight, SIM)
    if (titleLower.contains('forex') ||
        titleLower.contains('accommodation') ||
        titleLower.contains('housing') ||
        titleLower.contains('credit card') ||
        titleLower.contains('essential') ||
        bodyLower.contains('forex') ||
        bodyLower.contains('housing') ||
        bodyLower.contains('accommodation')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EssentialServicePage(
            serviceTitle: 'Student Essentials & Forex',
            serviceSubtitle:
                'Get the best student forex rates, international bank accounts, SIM cards & housing.',
            primaryIcon: Icons.currency_exchange_rounded,
            themeColor: Color(0xFF10B981),
            serviceKey: 'essential_forex',
            features: [
              {
                'title': 'Zero Markup Rates',
                'desc':
                    'Best exchange rates with instant university transfers.',
              },
              {
                'title': 'Direct University Pay',
                'desc': 'Transfer tuition fees directly to your university.',
              },
              {
                'title': 'Pre-departure Assistance',
                'desc':
                    'Receive your student multi-currency card at your doorstep.',
              },
            ],
          ),
        ),
      );
      return;
    }

    // 7. Loans / Application / Sanction / Disbursement
    if (notification.type == NotificationType.loanUpdate ||
        titleLower.contains('loan') ||
        titleLower.contains('sanction') ||
        titleLower.contains('disbursement') ||
        titleLower.contains('approval') ||
        titleLower.contains('application') ||
        bodyLower.contains('loan') ||
        bodyLower.contains('sanction') ||
        bodyLower.contains('disburs')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyLoansPage()),
      );
      return;
    }

    // 8. Tools / Offers / Calculator / Eligibility
    if (notification.type == NotificationType.offer ||
        titleLower.contains('tool') ||
        titleLower.contains('calculator') ||
        titleLower.contains('eligibility') ||
        titleLower.contains('offer') ||
        bodyLower.contains('calculator') ||
        bodyLower.contains('tool')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiToolsPage()),
      );
      return;
    }

    // 9. Profile / Account / Settings
    if (titleLower.contains('profile') ||
        titleLower.contains('account') ||
        titleLower.contains('setting') ||
        bodyLower.contains('profile') ||
        bodyLower.contains('kyc') ||
        bodyLower.contains('security')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      return;
    }

    // 10. Default fallback: Dashboard / Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: _notifications.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = _notifications[index];
                                  return GestureDetector(
                                    onTap: () => _handleNotificationTap(notif),
                                    child: _buildNotificationCard(notif),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const Spacer(),
          Text(
            'Notifications',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.done_all, color: Color(0xFF311B92)),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.loanUpdate:
        icon = Icons.account_balance_rounded;
        color = const Color(0xFF10B981);
        break;
      case NotificationType.communityMessage:
        icon = Icons.forum_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case NotificationType.offer:
        icon = Icons.local_offer_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case NotificationType.system:
        icon = Icons.info_rounded;
        color = const Color(0xFF673AB7);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: notification.isRead
            ? null
            : Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Tap to view',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
