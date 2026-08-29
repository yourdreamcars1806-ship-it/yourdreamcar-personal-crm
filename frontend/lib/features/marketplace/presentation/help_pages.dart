import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/app_toast.dart';

abstract final class AppSupport {
  static const email = 'yourdreamcars1806@gmail.com';
  static const appName = 'Your Dream Car';
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _HelpScaffold(
      title: 'Support',
      subtitle: 'We are here to help you buy, sell, and bid with confidence.',
      icon: Icons.support_agent_rounded,
      accent: const [Color(0xFF0056D2), Color(0xFF3D8BFF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroActionCard(
            icon: Icons.mail_outline_rounded,
            title: 'Email our team',
            subtitle: AppSupport.email,
            buttonLabel: 'Copy email',
            onAction: () async {
              await Clipboard.setData(
                const ClipboardData(text: AppSupport.email),
              );
              if (!context.mounted) return;
              AppToast.success(context, 'Email copied to clipboard');
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.schedule_rounded,
                  label: 'Response',
                  value: '1 business day',
                  color: const Color(0xFF0F9D58),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.access_time_rounded,
                  label: 'Hours',
                  value: 'Mon–Sat 10–7',
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('What we can help with'),
          const SizedBox(height: 10),
          _HelpTopicTile(
            icon: Icons.account_circle_outlined,
            title: 'Account & login',
            subtitle: 'Password, access, and profile updates',
          ),
          _HelpTopicTile(
            icon: Icons.directions_car_outlined,
            title: 'Listings & requests',
            subtitle: 'Submit, review, and publish status',
          ),
          _HelpTopicTile(
            icon: Icons.gavel_rounded,
            title: 'Bids & callbacks',
            subtitle: 'Offers, wins, and seller contact',
          ),
          _HelpTopicTile(
            icon: Icons.report_problem_outlined,
            title: 'Report an issue',
            subtitle: 'Wrong photos, price, or car details',
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Quick answers'),
          const SizedBox(height: 10),
          _FaqTile(
            question: 'When does my car go live?',
            answer:
                'After you submit a request, admin reviews photos and details. It appears on the marketplace only once approved and published.',
          ),
          _FaqTile(
            question: 'What happens after I place a bid?',
            answer:
                'Your bid is sent to our team. We review it and contact you by phone. Matching the exact sell price can win the car instantly.',
          ),
          _FaqTile(
            question: 'Is payment done in the app?',
            answer:
                'No in-app payment yet. Final price, inspection, documents, and payment are agreed directly with our team.',
          ),
        ],
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _sections = [
    (
      'About Your Dream Car',
      'Your Dream Car is a used-car marketplace and dealership app. You can browse cars, place bids, and submit a car for sale. Submitting a car does not publish it immediately. An admin may accept, edit, or reject a request, then publish it to the marketplace.',
    ),
    (
      'Accounts',
      'You must provide accurate details when you sign up. You are responsible for keeping your password safe. We may suspend an account that is used for fraud, spam, or misuse of listings and bids.',
    ),
    (
      'Listings',
      'When you add a car, you send a listing request with photos and details, including the sell price you want shown to buyers. You confirm that you are allowed to offer that vehicle and that the information and photos are true. Admin may change details (including price) before publishing. A request is not a live advertisement until it is published.',
    ),
    (
      'Prices and bids',
      'The sell price on the marketplace is the public asking price. A bid is an offer to buy, not a completed sale. Admin may accept or reject a bid. No payment is processed inside the app unless we clearly say so. Final sale terms, inspection, documents, and payment happen as agreed with our team.',
    ),
    (
      'Content',
      'Do not upload stolen photos, fake documents, or illegal content. We may remove listings or bids that break these terms or local law.',
    ),
    (
      'Limitation',
      'Cars are used vehicles. Condition can vary. Inspect a car before you buy. We are not liable for indirect loss, or for deals made outside the process shown in the app, to the extent allowed by law.',
    ),
    (
      'Changes',
      'We may update these terms. Continued use of the app after an update means you accept the new terms. For questions, use Support in Profile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _HelpScaffold(
      title: 'Terms & Conditions',
      subtitle: 'Rules for using ${AppSupport.appName}.',
      icon: Icons.description_outlined,
      accent: const [Color(0xFF003EA8), Color(0xFF0056D2)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _UpdatedPill(date: '22 August 2026'),
          const SizedBox(height: 18),
          for (var i = 0; i < _sections.length; i++)
            _LegalSectionCard(
              index: i + 1,
              title: _sections[i].$1,
              body: _sections[i].$2,
            ),
        ],
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _sections = [
    (
      'Data we collect',
      'Account: name, email, and password (stored as a hash, not plain text). Listings: car details, photos, city, phone, and the sell price you submit. Bids: offer amount, name, phone, city, and message. Device: basic app and login session data so you stay signed in.',
    ),
    (
      'How we use it',
      'We use this data to run your account, review and publish cars, handle bids, contact you about a listing or offer, send service notices (such as a new car alert if you allow it), and keep the app secure.',
    ),
    (
      'What is public',
      'Published cars show on the marketplace with photos, specs, and sell price. Buy price and internal admin notes are not shown to users. Your bid amount is visible to admin, not to other buyers.',
    ),
    (
      'Sharing',
      'We share data with service providers we need to run the app (for example image hosting and email delivery). We do not sell your personal data. We may share information if required by law or to prevent fraud.',
    ),
    (
      'Storage',
      'Data is stored on our servers and trusted cloud providers. We keep listing and bid records as long as needed to operate the business and meet legal duties, then delete or anonymise them where practical.',
    ),
    (
      'Your choices',
      'You can update your password in Profile. To correct listing details, change an email, or ask us to delete your account, contact support. Some records may be kept where the law requires it.',
    ),
    (
      'Contact',
      'Privacy questions: ${AppSupport.email}',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _HelpScaffold(
      title: 'Privacy Policy',
      subtitle: 'How we collect, use, and protect your data.',
      icon: Icons.privacy_tip_outlined,
      accent: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _UpdatedPill(date: '22 August 2026'),
          const SizedBox(height: 18),
          for (var i = 0; i < _sections.length; i++)
            _LegalSectionCard(
              index: i + 1,
              title: _sections[i].$1,
              body: _sections[i].$2,
            ),
        ],
      ),
    );
  }
}

class _HelpScaffold extends StatelessWidget {
  const _HelpScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 168,
              backgroundColor: accent.first,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: accent,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 24,
                        right: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(icon, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 16,
        color: MarketColors.text,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _UpdatedPill extends StatelessWidget {
  const _UpdatedPill({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: MarketColors.line),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.update_rounded, size: 16, color: MarketColors.primary),
          const SizedBox(width: 8),
          Text(
            'Last updated · $date',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: MarketColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: MarketTheme.cardShadow,
        border: Border.all(color: MarketColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0056D2), Color(0xFF3D8BFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: MarketColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: MarketColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: MarketColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MarketColors.line),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MarketColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: MarketColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTopicTile extends StatelessWidget {
  const _HelpTopicTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MarketColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MarketColors.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: MarketColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: MarketColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MarketColors.muted,
                    fontWeight: FontWeight.w600,
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

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _open ? MarketColors.primary.withValues(alpha: 0.35) : MarketColors.line,
        ),
        boxShadow: _open ? MarketTheme.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: MarketColors.text,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: MarketColors.primary,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      widget.answer,
                      style: const TextStyle(
                        height: 1.45,
                        color: MarketColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  crossFadeState:
                      _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MarketColors.line),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0056D2), Color(0xFF3D8BFF)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: MarketColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              height: 1.5,
              color: MarketColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
