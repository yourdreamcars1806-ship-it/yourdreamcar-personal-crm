import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/ui/admin_list_header.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/bid_amount_stepper.dart';
import '../../../services/bid_service.dart';

class AdminBidsPage extends StatefulWidget {
  const AdminBidsPage({super.key});

  @override
  State<AdminBidsPage> createState() => _AdminBidsPageState();
}

class _AdminBidsPageState extends State<AdminBidsPage> {
  static const _sky = Color(0xFF0056D2);

  final _api = BidService();
  final _search = TextEditingController();
  List<BidRecord> _items = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listAdmin();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  int _count(String status) => _items.where((b) => b.status == status).length;

  List<BidRecord> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _items.where((b) {
      if (_statusFilter != 'all' && b.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return '${b.carTitle} ${b.name} ${b.userName} ${b.phone} ${b.userEmail} ${b.city}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _setStatus(BidRecord bid, String status) async {
    try {
      final result = await _api.updateBid(id: bid.id, status: status);
      if (!mounted) return;
      if (result.instantWin) {
        AppToast.success(context, 'Bid matched price — customer won!');
      } else {
        AppToast.success(context, 'Bid ${status == 'accepted' ? 'accepted' : 'rejected'}');
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _updateAmount(BidRecord bid, double amount) async {
    try {
      final result = await _api.updateBid(id: bid.id, amount: amount);
      if (!mounted) return;
      if (result.instantWin) {
        AppToast.success(context, 'Price matched — bid won & car marked sold!');
      } else {
        AppToast.success(context, 'Bid amount updated');
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _deleteBid(BidRecord bid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bid?'),
        content: Text(
          'Remove ${bid.name.isEmpty ? bid.userName : bid.name}\'s bid on '
          '${bid.carTitle.isEmpty ? 'this car' : bid.carTitle}? '
          'This will also remove it from the user\'s account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.deleteBid(bid.id);
      if (!mounted) return;
      AppToast.success(context, 'Bid deleted');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  void _viewBid(BidRecord bid) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _BidDetailSheet(
        bid: bid,
        onAmountChanged: (amount) async {
          Navigator.pop(ctx);
          await _updateAmount(bid, amount);
        },
        onAccept: bid.status == 'pending' ? () async {
          Navigator.pop(ctx);
          await _setStatus(bid, 'accepted');
        } : null,
        onReject: bid.status == 'pending' ? () async {
          Navigator.pop(ctx);
          await _setStatus(bid, 'rejected');
        } : null,
        onDelete: () async {
          Navigator.pop(ctx);
          await _deleteBid(bid);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _sky,
        child: CustomScrollView(
          slivers: [
            const AdminListHeader(title: 'User bids'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'Total', value: '${_items.length}', color: _sky),
                    _StatChip(label: 'Pending', value: '${_count('pending')}', color: const Color(0xFFF59E0B)),
                    _StatChip(label: 'Accepted', value: '${_count('accepted')}', color: const Color(0xFF22C55E)),
                    _StatChip(label: 'Rejected', value: '${_count('rejected')}', color: const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search car, name, phone, email…',
                    prefixIcon: const Icon(Icons.search_rounded, color: _sky),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    _FilterChip(
                      label: 'Pending',
                      selected: _statusFilter == 'pending',
                      onTap: () => setState(() => _statusFilter = 'pending'),
                    ),
                    _FilterChip(
                      label: 'Accepted',
                      selected: _statusFilter == 'accepted',
                      onTap: () => setState(() => _statusFilter = 'accepted'),
                    ),
                    _FilterChip(
                      label: 'Rejected',
                      selected: _statusFilter == 'rejected',
                      onTap: () => setState(() => _statusFilter = 'rejected'),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _sky)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text(_error!))),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No bids found',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final b = filtered[i];
                    return _BidCard(
                      bid: b,
                      onTap: () => _viewBid(b),
                      onAccept: b.status == 'pending' ? () => _setStatus(b, 'accepted') : null,
                      onReject: b.status == 'pending' ? () => _setStatus(b, 'rejected') : null,
                      onDelete: () => _deleteBid(b),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({
    required this.bid,
    required this.onTap,
    this.onAccept,
    this.onReject,
    this.onDelete,
  });

  final BidRecord bid;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  Color _statusColor() {
    switch (bid.status) {
      case 'accepted':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                color: _statusColor(),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 88,
                        height: 72,
                        child: bid.carImageUrl.isEmpty
                            ? Image.asset(AppAssets.sampleCarListing, fit: BoxFit.cover)
                            : Image.network(bid.carImageUrl, fit: BoxFit.cover, cacheWidth: 176),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bid.carTitle.isEmpty ? 'Car bid' : bid.carTitle,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              _StatusBadge(status: bid.status),
                              if (onDelete != null)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                                  onPressed: onDelete,
                                  tooltip: 'Delete bid',
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bid.name.isEmpty ? bid.userName : bid.name,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${bid.phone}${bid.city.isNotEmpty ? ' • ${bid.city}' : ''}',
                            style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _PriceTag(
                                label: 'Bid',
                                value: formatInr(bid.amount),
                                color: const Color(0xFF031273),
                              ),
                              const SizedBox(width: 8),
                              _PriceTag(
                                label: 'Ask',
                                value: formatInr(bid.askPrice),
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          if (onAccept != null || onReject != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: onReject,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFFECACA)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: onAccept,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

class _BidDetailSheet extends StatefulWidget {
  const _BidDetailSheet({
    required this.bid,
    this.onAmountChanged,
    this.onAccept,
    this.onReject,
    this.onDelete,
  });

  final BidRecord bid;
  final ValueChanged<double>? onAmountChanged;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  @override
  State<_BidDetailSheet> createState() => _BidDetailSheetState();
}

class _BidDetailSheetState extends State<_BidDetailSheet> {
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.bid.amount;
  }

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, inset + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bid details',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              bid.carTitle.isEmpty ? 'Car bid' : bid.carTitle,
              style: GoogleFonts.dmSans(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (bid.carImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(bid.carImageUrl, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),
            if (bid.status == 'pending' && widget.onAmountChanged != null) ...[
              Text(
                'Adjust bid (±₹5,000 like user)',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              BidAmountStepper(
                amount: _amount,
                askPrice: bid.askPrice,
                onChanged: (v) => setState(() => _amount = v),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _amount.round() == bid.amount.round()
                    ? null
                    : () => widget.onAmountChanged?.call(_amount),
                child: const Text('Update bid amount'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              _DetailRow('Bid amount', formatInr(bid.amount)),
            ],
            _DetailRow('Ask price', formatInr(bid.askPrice)),
            _DetailRow('Customer', bid.name.isEmpty ? bid.userName : bid.name),
            _DetailRow('Phone', bid.phone),
            if (bid.userEmail.isNotEmpty) _DetailRow('Email', bid.userEmail),
            if (bid.city.isNotEmpty) _DetailRow('City', bid.city),
            _DetailRow('Status', bid.status.toUpperCase()),
            if (bid.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Message', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(bid.message, style: GoogleFonts.dmSans(height: 1.45)),
              ),
            ],
            if (widget.onAccept != null || widget.onReject != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.onAccept,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                      child: const Text('Accept bid'),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.onDelete != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete bid'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$value $label',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF031273);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: navy.withValues(alpha: 0.12),
        checkmarkColor: navy,
        labelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          color: selected ? navy : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 12, color: color),
      ),
    );
  }
}
