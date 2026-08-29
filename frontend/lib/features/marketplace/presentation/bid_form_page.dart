import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/bid_amount_stepper.dart';
import '../../../core/ui/live_bid_timer.dart';
import '../../../services/auth_service.dart';
import '../../../services/bid_service.dart';
import '../../../services/car_service.dart';
import 'user_shell.dart';

class BidFormPage extends StatefulWidget {
  const BidFormPage({super.key, required this.car});

  final CarRecord car;

  @override
  State<BidFormPage> createState() => _BidFormPageState();
}

class _BidFormPageState extends State<BidFormPage>
    with TickerProviderStateMixin, LiveBidSessionMixin {
  final _api = BidService();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController(text: 'Pune');
  final _message = TextEditingController();
  final _amountFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _messageFocus = FocusNode();
  bool _loading = false;
  double _offerAmount = 0;

  @override
  void initState() {
    super.initState();
    initLiveBidSession();
    _offerAmount = _roundOffer(widget.car.sellPrice).toDouble();
    _amount.text = '${_offerAmount.round()}';
    _prefill();
    _amount.addListener(_tick);
    _amountFocus.addListener(_tick);
    _nameFocus.addListener(_tick);
    _phoneFocus.addListener(_tick);
    _cityFocus.addListener(_tick);
    _messageFocus.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _prefill() async {
    final name = await AuthService.getStoredName();
    if (!mounted) return;
    if (name.isNotEmpty) setState(() => _name.text = name);
  }

  @override
  void dispose() {
    disposeLiveBidSession();
    _amount.dispose();
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _message.dispose();
    _amountFocus.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cityFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  double? get _bidAmount => _offerAmount;

  void _setOffer(double value) {
    final rounded = _roundOffer(value).toDouble();
    setState(() {
      _offerAmount = rounded;
      _amount.text = '${rounded.round()}';
      _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    });
  }

  List<int> get _chips {
    final ask = widget.car.sellPrice.round();
    if (ask <= 0) return const [];
    final raw = <int>{
      _roundOffer(ask * 0.90),
      _roundOffer(ask * 0.95),
      ask,
      _roundOffer(ask * 1.05),
    }..removeWhere((v) => v < 1);
    final list = raw.toList()..sort();
    return list;
  }

  int _roundOffer(num value) {
    final n = value.round();
    if (n >= 100000) return (n / 5000).round() * 5000;
    if (n >= 10000) return (n / 1000).round() * 1000;
    return n;
  }

  Future<void> _submit() async {
    final amount = _bidAmount;
    if (amount == null || amount < 1) {
      AppToast.error(context, 'Enter your bid amount');
      _amountFocus.requestFocus();
      return;
    }
    if (_name.text.trim().length < 2) {
      AppToast.error(context, 'Enter your name');
      _nameFocus.requestFocus();
      return;
    }
    if (_phone.text.trim().length < 8) {
      AppToast.error(context, 'Enter a valid phone number');
      _phoneFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await _api.create(
        carId: widget.car.id,
        amount: amount,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      if (result.instantWin) {
        AppToast.success(context, 'You won! Bid matched the sell price.');
      } else {
        AppToast.success(context, 'Bid submitted. Check your dashboard.');
      }
      Navigator.of(context).pop(true);
      UserShell.openDashboard?.call();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final title = car.title.isNotEmpty ? car.title : '${car.brand} ${car.model}';
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final amount = _bidAmount;
    final ask = car.sellPrice;
    final diff = amount == null ? null : amount - ask;

    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0056D2),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Place your bid',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: LiveBidTimerDisplay(
                  elapsed: liveElapsed,
                  pulse: livePulse,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: LiveBidTimerBanner(
                      elapsed: liveElapsed,
                      pulse: livePulse,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CarSummary(car: car, title: title),
                          const SizedBox(height: 16),
                          _AmountCard(
                            controller: _amount,
                            focusNode: _amountFocus,
                            enabled: !_loading,
                            formatted: amount == null ? '' : formatInr(amount),
                            diffLabel: _diffLabel(diff),
                            diffColor: _diffColor(diff),
                            askPrice: ask,
                            offerAmount: _offerAmount,
                            onStep: _setOffer,
                          ),
                          if (_chips.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final chip in _chips)
                                  _OfferChip(
                                    label: formatInr(chip),
                                    selected: amount?.round() == chip,
                                    onTap: _loading
                                        ? null
                                        : () => _setOffer(chip.toDouble()),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Text(
                            'Your details',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: MarketColors.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _BidField(
                            icon: Icons.person_outline_rounded,
                            hint: 'Full name',
                            controller: _name,
                            focusNode: _nameFocus,
                            enabled: !_loading,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _phoneFocus.requestFocus(),
                          ),
                          const SizedBox(height: 10),
                          _BidField(
                            icon: Icons.phone_outlined,
                            hint: 'Phone number',
                            controller: _phone,
                            focusNode: _phoneFocus,
                            enabled: !_loading,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10,
                            onSubmitted: (_) => _cityFocus.requestFocus(),
                          ),
                          const SizedBox(height: 10),
                          _BidField(
                            icon: Icons.location_city_outlined,
                            hint: 'City',
                            controller: _city,
                            focusNode: _cityFocus,
                            enabled: !_loading,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _messageFocus.requestFocus(),
                          ),
                          const SizedBox(height: 10),
                          _BidField(
                            icon: Icons.chat_bubble_outline_rounded,
                            hint: 'Message to seller (optional)',
                            controller: _message,
                            focusNode: _messageFocus,
                            enabled: !_loading,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140056D2),
                    blurRadius: 18,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + (keyboard > 0 ? 0 : MediaQuery.paddingOf(context).bottom)),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x400056D2),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MarketColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF7AA3E6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gavel_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Submit bid',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _diffLabel(double? diff) {
    if (diff == null) return 'Compared with the public sell price';
    if (diff == 0) return 'Same as sell price';
    if (diff < 0) return '${formatInr(-diff)} below sell price';
    return '${formatInr(diff)} above sell price';
  }

  Color _diffColor(double? diff) {
    if (diff == null || diff == 0) return MarketColors.muted;
    if (diff < 0) return const Color(0xFF1E7A48);
    return const Color(0xFFB45309);
  }
}

class _CarSummary extends StatelessWidget {
  const _CarSummary({required this.car, required this.title});

  final CarRecord car;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 92,
              height: 72,
              child: car.imageUrl.isEmpty
                  ? Image.asset(AppAssets.sampleCarListing, fit: BoxFit.cover)
                  : Image.network(
                      car.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        AppAssets.sampleCarListing,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: MarketColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${car.year}  •  ${car.fuelType}  •  ${car.ownership}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MarketColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sell ${formatInr(car.sellPrice)}',
                  style: const TextStyle(
                    color: MarketColors.primary,
                    fontWeight: FontWeight.w800,
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

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.formatted,
    required this.diffLabel,
    required this.diffColor,
    required this.askPrice,
    required this.offerAmount,
    required this.onStep,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String formatted;
  final String diffLabel;
  final Color diffColor;
  final double askPrice;
  final double offerAmount;
  final ValueChanged<double> onStep;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focused ? MarketColors.primary : const Color(0xFFE4EAF3),
          width: focused ? 1.6 : 1,
        ),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your offer',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: MarketColors.text,
            ),
          ),
          const SizedBox(height: 12),
          BidAmountStepper(
            amount: offerAmount,
            onChanged: onStep,
            enabled: enabled,
            askPrice: askPrice,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final n = double.tryParse(v.trim());
              if (n != null && n >= 1) onStep(n);
            },
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MarketColors.text,
            ),
            decoration: const InputDecoration(
              labelText: 'Or type amount',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (formatted.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              formatted,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: MarketColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            diffLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: diffColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MarketColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? MarketColors.primary : const Color(0xFFE4EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : MarketColors.text,
          ),
        ),
      ),
    );
  }
}

class _BidField extends StatelessWidget {
  const _BidField({
    required this.icon,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: maxLines > 1 ? null : 54,
      constraints: BoxConstraints(minHeight: maxLines > 1 ? 96 : 54),
      padding: EdgeInsets.fromLTRB(14, maxLines > 1 ? 12 : 0, 8, maxLines > 1 ? 8 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? MarketColors.primary : const Color(0xFFE4EAF3),
          width: focused ? 1.4 : 1,
        ),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child: Icon(
              icon,
              size: 22,
              color: focused ? MarketColors.primary : MarketColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              maxLines: maxLines,
              maxLength: maxLength,
              textCapitalization: textCapitalization,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MarketColors.text,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA8BA),
                  fontWeight: FontWeight.w500,
                ),
                isDense: true,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
