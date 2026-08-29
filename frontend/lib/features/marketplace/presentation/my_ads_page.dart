import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/bid_amount_stepper.dart';
import '../../../core/ui/frost_card.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/bid_service.dart';
import '../../../services/listing_request_service.dart';
import 'user_car_details_page.dart';

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({
    super.key,
    this.onAddCar,
    this.onBrowseCars,
    this.initialTab = 0,
  });

  final Future<void> Function()? onAddCar;
  final VoidCallback? onBrowseCars;
  final int initialTab;

  @override
  State<MyAdsPage> createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> {
  final _adsApi = ListingRequestService();
  final _bidApi = BidService();
  List<ListingRequestRecord> _ads = [];
  List<BidRecord> _bids = [];
  bool _loading = true;
  String? _error;
  String _name = '';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _bidApi.listMine(),
        _adsApi.listMine(),
        AuthService.getStoredName(),
      ]);
      if (!mounted) return;
      setState(() {
        _bids = results[0] as List<BidRecord>;
        _ads = results[1] as List<ListingRequestRecord>;
        _name = (results[2] as String).trim();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateBidAmount(BidRecord bid, double amount) async {
    try {
      final result = await _bidApi.updateMyBid(id: bid.id, amount: amount);
      if (!mounted) return;
      if (result.instantWin) {
        AppToast.success(context, 'Price matched — you won this car!');
      } else {
        AppToast.success(context, 'Bid updated');
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _addCar() async {
    await widget.onAddCar?.call();
    if (mounted) _load();
  }

  int get _pendingAds => _ads.where((a) => a.status == 'pending').length;
  int get _liveAds => _ads.where((a) => a.status == 'approved').length;
  int get _openBids => _bids.where((b) => b.status == 'pending').length;

  String get _hello {
    if (_name.isEmpty) return 'Dashboard';
    return 'Hi, ${_name.split(RegExp(r'\s+')).first}';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        body: RefreshIndicator(
          color: MarketColors.primary,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: DashboardHeroHeader(
                  badge: 'MY ACCOUNT',
                  title: _hello,
                  subtitle: 'Track bids, adjust offers, and manage your car requests',
                  stats: [
                    ('Bids', '${_bids.length}'),
                    ('Pending', '$_pendingAds'),
                    ('Live', '$_liveAds'),
                  ],
                  trailing: widget.onAddCar != null
                      ? Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _addCar,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.add_rounded, color: Colors.white),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.gavel_rounded,
                          label: 'Bids',
                          value: '${_bids.length}',
                          hint: _openBids == 0
                              ? 'None waiting'
                              : '$_openBids waiting',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.hourglass_top_rounded,
                          label: 'Pending',
                          value: '$_pendingAds',
                          hint: 'In review',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_rounded,
                          label: 'Live',
                          value: '$_liveAds',
                          hint: 'Published',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: _Segment(
                    tab: _tab,
                    bids: _bids.length,
                    cars: _ads.length,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: MarketColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Message(
                    icon: Icons.wifi_off_rounded,
                    title: 'Could not load',
                    body: _error!,
                    action: 'Retry',
                    onAction: _load,
                  ),
                )
              else if (_tab == 0 && _bids.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Message(
                    icon: Icons.gavel_rounded,
                    title: 'No bids yet',
                    body: 'Open a car and tap Place a bid. Updates show here.',
                    action: 'Browse cars',
                    onAction: widget.onBrowseCars,
                  ),
                )
              else if (_tab == 1 && _ads.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Message(
                    icon: Icons.directions_car_filled_rounded,
                    title: 'No car requests',
                    body:
                        'Add your car. Admin will review, then publish it.',
                    action: 'Add your car',
                    onAction: widget.onAddCar == null ? null : _addCar,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: _tab == 0 ? _bids.length : _ads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (_tab == 0) {
                        return _BidCard(
                          item: _bids[i],
                          onUpdated: _load,
                          onAmountChanged: (bid, amount) =>
                              _updateBidAmount(bid, amount),
                        );
                      }
                      return _AdCard(item: _ads[i]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF8)),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MarketColors.primary.withValues(alpha: 0.15),
                      MarketColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: MarketColors.primary),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: MarketColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: MarketColors.text,
            ),
          ),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: MarketColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.tab,
    required this.bids,
    required this.cars,
    required this.onChanged,
  });

  final int tab;
  final int bids;
  final int cars;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EEF8)),
      ),
      child: Row(
        children: [
          _SegBtn(
            label: 'My bids',
            count: bids,
            selected: tab == 0,
            onTap: () => onChanged(0),
          ),
          _SegBtn(
            label: 'Car requests',
            count: cars,
            selected: tab == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? MarketColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? Colors.white : MarketColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: selected ? Colors.white : MarketColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF3FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: MarketColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: MarketColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MarketColors.muted, height: 1.4),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: MarketColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BidCard extends StatefulWidget {
  const _BidCard({
    required this.item,
    required this.onUpdated,
    required this.onAmountChanged,
  });

  final BidRecord item;
  final Future<void> Function() onUpdated;
  final Future<void> Function(BidRecord bid, double amount) onAmountChanged;

  @override
  State<_BidCard> createState() => _BidCardState();
}

class _BidCardState extends State<_BidCard> {
  late double _amount;
  bool _expanded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = widget.item.amount;
  }

  @override
  void didUpdateWidget(_BidCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.amount != widget.item.amount) {
      _amount = widget.item.amount;
    }
  }

  Future<void> _saveAmount() async {
    if (_saving || _amount.round() == widget.item.amount.round()) return;
    setState(() => _saving = true);
    await widget.onAmountChanged(widget.item, _amount);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = _statusStyle(item.status);
    final diff = item.amount - item.askPrice;
    final vsAsk = item.askPrice <= 0
        ? ''
        : diff == 0
            ? 'Same as sell price'
            : diff < 0
                ? '${formatInr(-diff)} below'
                : '${formatInr(diff)} above';
    final canEdit = item.status == 'pending';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.carId.isEmpty
            ? null
            : () => UserCarDetailsPage.open(context, carId: item.carId),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EEF8)),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Thumb(url: item.carImageUrl, fallback: Icons.gavel_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.carTitle.isEmpty ? 'Car bid' : item.carTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: MarketColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatInr(item.amount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: MarketColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            'Sell ${formatInr(item.askPrice)}',
                            if (vsAsk.isNotEmpty) vsAsk,
                            if (_ago(item.createdAt).isNotEmpty) _ago(item.createdAt),
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: MarketColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StatusChip(label: status.$1, color: status.$2),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFB7C4D6)),
                ],
              ),
              if (canEdit) ...[
                const SizedBox(height: 12),
                Material(
                  color: MarketColors.chipBg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18, color: MarketColors.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Adjust bid (±₹5,000)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: MarketColors.text,
                              ),
                            ),
                          ),
                          Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: MarketColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  BidAmountStepper(
                    amount: _amount,
                    askPrice: item.askPrice,
                    enabled: !_saving,
                    onChanged: (v) => setState(() => _amount = v),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _saving || _amount.round() == item.amount.round()
                        ? null
                        : _saveAmount,
                    style: FilledButton.styleFrom(
                      backgroundColor: MarketColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update bid amount',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.item});

  final ListingRequestRecord item;

  @override
  Widget build(BuildContext context) {
    final status = switch (item.status) {
      'approved' => ('Published', const Color(0xFF1E7A48)),
      'rejected' => ('Rejected', const Color(0xFFC0392B)),
      _ => ('Pending review', MarketColors.primary),
    };
    final canOpen = item.publishedCarId.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canOpen
            ? () => UserCarDetailsPage.open(context, carId: item.publishedCarId)
            : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EEF8)),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(
                url: item.imageUrl,
                fallback: Icons.directions_car_filled_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.brand} ${item.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: MarketColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        '${item.year}',
                        formatKm(item.kmDriven),
                        formatInr(item.expectedPrice),
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MarketColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(label: status.$1, color: status.$2),
                        if (_ago(item.createdAt).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _ago(item.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: MarketColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (canOpen)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB7C4D6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.fallback});

  final String url;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 86,
        height: 86,
        child: url.isEmpty
            ? ColoredBox(
                color: const Color(0xFFEEF3FB),
                child: Icon(fallback, color: MarketColors.primary),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  AppAssets.sampleCarListing,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

(String, Color) _statusStyle(String status) {
  return switch (status) {
    'accepted' => ('Won', const Color(0xFF1E7A48)),
    'rejected' => ('Rejected', const Color(0xFFC0392B)),
    _ => ('Pending', MarketColors.primary),
  };
}

String _ago(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final mins = DateTime.now().difference(local).inMinutes;
  if (mins < 1) return 'Just now';
  if (mins < 60) return '${mins}m ago';
  final hours = mins ~/ 60;
  if (hours < 24) return '${hours}h ago';
  final days = hours ~/ 24;
  if (days < 7) return '${days}d ago';
  return '${local.day}/${local.month}/${local.year}';
}
