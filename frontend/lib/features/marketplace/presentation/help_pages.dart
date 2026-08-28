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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Need help with a listing, bid, or your account? Our team is here.',
            style: TextStyle(color: MarketColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.mail_outline_rounded,
            title: 'Email us',
            subtitle: AppSupport.email,
            trailing: Icons.copy_rounded,
            onTap: () async {
              await Clipboard.setData(
                const ClipboardData(text: AppSupport.email),
              );
              if (!context.mounted) return;
              AppToast.success(context, 'Email copied');
            },
          ),
          const SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.schedule_rounded,
            title: 'Response time',
            subtitle: 'Usually within 1 business day, Mon–Sat 10am–7pm IST',
          ),
          const SizedBox(height: 22),
          const Text(
            'What we can help with',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: MarketColors.text,
            ),
          ),
          const SizedBox(height: 10),
          const _Bullet('Login, update password, and account access'),
          const _Bullet('Car listing requests and publish status'),
          const _Bullet('Bids, callbacks, and listing questions'),
          const _Bullet('Wrong details, photos, or price on a live ad'),
          const SizedBox(height: 22),
          const Text(
            'How it works',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: MarketColors.text,
            ),
          ),
          const SizedBox(height: 10),
          const _Bullet(
            'Adding a car sends a request. It goes live only after admin review.',
          ),
          const _Bullet(
            'A bid is an offer. Our team contacts you after you submit it.',
          ),
          const _Bullet(
            'The sell price on a car is public. Buy price is for admin only.',
          ),
        ],
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HelpScaffold(
      title: 'Terms & Conditions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegalP(
            'Last updated: 22 August 2026',
            muted: true,
          ),
          _LegalH('1. About Your Dream Car'),
          _LegalP(
            'Your Dream Car is a used-car marketplace and dealership app. You can browse cars, place bids, and submit a car for sale. Submitting a car does not publish it immediately. An admin may accept, edit, or reject a request, then publish it to the marketplace.',
          ),
          _LegalH('2. Accounts'),
          _LegalP(
            'You must provide accurate details when you sign up. You are responsible for keeping your password safe. We may suspend an account that is used for fraud, spam, or misuse of listings and bids.',
          ),
          _LegalH('3. Listings'),
          _LegalP(
            'When you add a car, you send a listing request with photos and details, including the sell price you want shown to buyers. You confirm that you are allowed to offer that vehicle and that the information and photos are true. Admin may change details (including price) before publishing. A request is not a live advertisement until it is published.',
          ),
          _LegalH('4. Prices and bids'),
          _LegalP(
            'The sell price on the marketplace is the public asking price. A bid is an offer to buy, not a completed sale. Admin may accept or reject a bid. No payment is processed inside the app unless we clearly say so. Final sale terms, inspection, documents, and payment happen as agreed with our team.',
          ),
          _LegalH('5. Content'),
          _LegalP(
            'Do not upload stolen photos, fake documents, or illegal content. We may remove listings or bids that break these terms or local law.',
          ),
          _LegalH('6. Limitation'),
          _LegalP(
            'Cars are used vehicles. Condition can vary. Inspect a car before you buy. We are not liable for indirect loss, or for deals made outside the process shown in the app, to the extent allowed by law.',
          ),
          _LegalH('7. Changes'),
          _LegalP(
            'We may update these terms. Continued use of the app after an update means you accept the new terms. For questions, use Support in Profile.',
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HelpScaffold(
      title: 'Privacy Policy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegalP(
            'Last updated: 22 August 2026',
            muted: true,
          ),
          _LegalH('1. Data we collect'),
          _LegalP(
            'Account: name, email, and password (stored as a hash, not plain text). Listings: car details, photos, city, phone, and the sell price you submit. Bids: offer amount, name, phone, city, and message. Device: basic app and login session data so you stay signed in.',
          ),
          _LegalH('2. How we use it'),
          _LegalP(
            'We use this data to run your account, review and publish cars, handle bids, contact you about a listing or offer, send service notices (such as a new car alert if you allow it), and keep the app secure.',
          ),
          _LegalH('3. What is public'),
          _LegalP(
            'Published cars show on the marketplace with photos, specs, and sell price. Buy price and internal admin notes are not shown to users. Your bid amount is visible to admin, not to other buyers.',
          ),
          _LegalH('4. Sharing'),
          _LegalP(
            'We share data with service providers we need to run the app (for example image hosting and email delivery). We do not sell your personal data. We may share information if required by law or to prevent fraud.',
          ),
          _LegalH('5. Storage'),
          _LegalP(
            'Data is stored on our servers and trusted cloud providers. We keep listing and bid records as long as needed to operate the business and meet legal duties, then delete or anonymise them where practical.',
          ),
          _LegalH('6. Your choices'),
          _LegalP(
            'You can update your password in Profile. To correct listing details, change an email, or ask us to delete your account, contact support. Some records may be kept where the law requires it.',
          ),
          _LegalH('7. Contact'),
          _LegalP(
            'Privacy questions: ${AppSupport.email}',
          ),
        ],
      ),
    );
  }
}

class _HelpScaffold extends StatelessWidget {
  const _HelpScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: MarketColors.text,
          elevation: 0,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [child],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: MarketColors.primary),
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
                        color: MarketColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(trailing, color: MarketColors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: MarketColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: MarketColors.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalH extends StatelessWidget {
  const _LegalH(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: MarketColors.text,
        ),
      ),
    );
  }
}

class _LegalP extends StatelessWidget {
  const _LegalP(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.45,
        color: muted ? MarketColors.muted : MarketColors.text,
        fontWeight: muted ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
