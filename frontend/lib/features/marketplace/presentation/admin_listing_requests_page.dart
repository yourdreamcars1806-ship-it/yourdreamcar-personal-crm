import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/ui/admin_list_header.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/listing_request_service.dart';

class AdminListingRequestsPage extends StatefulWidget {
  const AdminListingRequestsPage({super.key});

  @override
  State<AdminListingRequestsPage> createState() =>
      _AdminListingRequestsPageState();
}

class _AdminListingRequestsPageState extends State<AdminListingRequestsPage> {
  static const _sky = Color(0xFF0056D2);

  final _api = ListingRequestService();
  final _search = TextEditingController();
  List<ListingRequestRecord> _items = [];
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

  int _count(String status) => _items.where((r) => r.status == status).length;

  List<ListingRequestRecord> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _items.where((r) {
      if (_statusFilter != 'all' && r.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return '${r.brand} ${r.model} ${r.userName} ${r.userEmail} ${r.phone} ${r.city} ${r.vehicleNumber}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _reject(ListingRequestRecord item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject request?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800)),
        content: Text('Reject ${item.brand} ${item.model}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.review(id: item.id, action: 'reject');
      if (!mounted) return;
      AppToast.success(context, 'Request rejected');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _openPublish(ListingRequestRecord item) async {
    final published = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _PublishSheet(item: item, api: _api),
    );
    if (published == true && mounted) await _load();
  }

  void _viewRequest(ListingRequestRecord item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _RequestDetailSheet(
        item: item,
        onReject: item.status == 'pending' ? () async {
          Navigator.pop(ctx);
          await _reject(item);
        } : null,
        onPublish: item.status == 'pending' ? () async {
          Navigator.pop(ctx);
          await _openPublish(item);
        } : null,
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
            const AdminListHeader(title: 'User car requests'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'Total', value: '${_items.length}', color: _sky),
                    _StatChip(label: 'Pending', value: '${_count('pending')}', color: const Color(0xFFF59E0B)),
                    _StatChip(label: 'Approved', value: '${_count('approved')}', color: const Color(0xFF22C55E)),
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
                    hintText: 'Search brand, model, user, city…',
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
                    _FilterChip(label: 'All', selected: _statusFilter == 'all', onTap: () => setState(() => _statusFilter = 'all')),
                    _FilterChip(label: 'Pending', selected: _statusFilter == 'pending', onTap: () => setState(() => _statusFilter = 'pending')),
                    _FilterChip(label: 'Approved', selected: _statusFilter == 'approved', onTap: () => setState(() => _statusFilter = 'approved')),
                    _FilterChip(label: 'Rejected', selected: _statusFilter == 'rejected', onTap: () => setState(() => _statusFilter = 'rejected')),
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
                    'No car requests found',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
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
                    final item = filtered[i];
                    return _RequestCard(
                      item: item,
                      onTap: () => _viewRequest(item),
                      onReject: item.status == 'pending' ? () => _reject(item) : null,
                      onPublish: item.status == 'pending' ? () => _openPublish(item) : null,
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.item,
    required this.onTap,
    this.onReject,
    this.onPublish,
  });

  final ListingRequestRecord item;
  final VoidCallback onTap;
  final VoidCallback? onReject;
  final VoidCallback? onPublish;

  Color _statusColor() {
    switch (item.status) {
      case 'approved':
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
              Container(height: 4, color: _statusColor()),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 96,
                        height: 78,
                        child: item.imageUrl.isEmpty
                            ? Image.asset(AppAssets.sampleCarListing, fit: BoxFit.cover)
                            : Image.network(item.imageUrl, fit: BoxFit.cover, cacheWidth: 192),
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
                                  '${item.brand} ${item.model}',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              _StatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.year} • ${item.fuelType} • ${item.ownership}',
                            style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Expected ${formatInr(item.expectedPrice)} • ${item.city}',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (item.userName.isNotEmpty) item.userName,
                              item.phone,
                            ].join(' • '),
                            style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFF475569)),
                          ),
                          if (onReject != null || onPublish != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: onReject,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFFECACA)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: onPublish,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF031273),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Publish'),
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

class _RequestDetailSheet extends StatelessWidget {
  const _RequestDetailSheet({
    required this.item,
    this.onReject,
    this.onPublish,
  });

  final ListingRequestRecord item;
  final VoidCallback? onReject;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, inset + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Car request details',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 16),
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(item.imageUrl, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),
            _DetailRow('Vehicle', '${item.brand} ${item.model}'),
            _DetailRow('Year', '${item.year}'),
            _DetailRow('Fuel', item.fuelType),
            _DetailRow('Ownership', item.ownership),
            if (item.vehicleNumber.isNotEmpty) _DetailRow('Reg. no.', item.vehicleNumber),
            if (item.kmDriven > 0) _DetailRow('KM driven', '${item.kmDriven}'),
            _DetailRow('Expected price', formatInr(item.expectedPrice)),
            _DetailRow('City', item.city),
            _DetailRow('Seller', item.userName.isNotEmpty ? item.userName : '—'),
            _DetailRow('Phone', item.phone),
            if (item.userEmail.isNotEmpty) _DetailRow('Email', item.userEmail),
            _DetailRow('Status', item.status.toUpperCase()),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Description', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(item.description, style: GoogleFonts.dmSans(height: 1.45)),
              ),
            ],
            if (onReject != null || onPublish != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: onReject, child: const Text('Reject')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPublish,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF031273)),
                      child: const Text('Review & publish'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PublishSheet extends StatefulWidget {
  const _PublishSheet({required this.item, required this.api});

  final ListingRequestRecord item;
  final ListingRequestService api;

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  static const _navy = Color(0xFF031273);

  late final TextEditingController _title;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _buy;
  late final TextEditingController _sell;
  late final TextEditingController _desc;
  late String _fuel;
  late String _ownership;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(
      text: item.title.isEmpty ? '${item.brand} ${item.model}' : item.title,
    );
    _brand = TextEditingController(text: item.brand);
    _model = TextEditingController(text: item.model);
    _year = TextEditingController(text: '${item.year}');
    _buy = TextEditingController();
    _sell = TextEditingController(text: item.expectedPrice.toStringAsFixed(0));
    _desc = TextEditingController(text: item.description);
    _fuel = item.fuelType;
    _ownership = item.ownership;
  }

  @override
  void dispose() {
    _title.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _buy.dispose();
    _sell.dispose();
    _desc.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Future<void> _publish() async {
    final buy = double.tryParse(_buy.text.trim());
    final sell = double.tryParse(_sell.text.trim());
    if (buy == null || buy < 0) {
      AppToast.error(context, 'Enter buy price (admin only)');
      return;
    }
    if (sell == null || sell < 0) {
      AppToast.error(context, 'Enter sell price (public)');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.review(
        id: widget.item.id,
        action: 'publish',
        fields: {
          'title': _title.text.trim(),
          'brand': _brand.text.trim(),
          'model': _model.text.trim(),
          'year': int.tryParse(_year.text.trim()) ?? widget.item.year,
          'fuelType': _fuel,
          'ownership': _ownership,
          'buyPrice': buy,
          'sellPrice': sell,
          'description': _desc.text.trim(),
        },
      );
      if (!mounted) return;
      AppToast.success(context, 'Car published to marketplace');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, inset + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Review & publish',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Buy price stays admin-only. Sell price is shown to users.',
              style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(controller: _title, decoration: _dec('Listing title')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _brand, decoration: _dec('Brand'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _model, decoration: _dec('Model'))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: _dec('Year'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buy,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Buy price (admin)', hint: '₹'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sell,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Sell price (public)', hint: '₹'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _fuel,
              decoration: _dec('Fuel type'),
              items: const [
                DropdownMenuItem(value: 'PETROL', child: Text('Petrol')),
                DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                DropdownMenuItem(value: 'CNG', child: Text('CNG')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _fuel = v);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _ownership,
              decoration: _dec('Ownership'),
              items: const [
                DropdownMenuItem(value: '1st owner', child: Text('1st owner')),
                DropdownMenuItem(value: '2nd owner', child: Text('2nd owner')),
                DropdownMenuItem(value: '3rd owner', child: Text('3rd owner')),
                DropdownMenuItem(value: '4th owner', child: Text('4th owner')),
                DropdownMenuItem(value: '5th owner', child: Text('5th owner')),
                DropdownMenuItem(value: 'multiple owner', child: Text('Multiple owner')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _ownership = v);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              maxLines: 3,
              decoration: _dec('Description'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _publish,
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(
                      'Publish to marketplace',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
                    ),
            ),
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
            width: 120,
            child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
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
          Text('$value $label', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 13)),
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
      case 'approved':
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
