import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/inr.dart';
import '../../../core/io/pdf_file_helper.dart';
import '../../../core/ui/admin_list_header.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/delivery_note_service.dart';
import 'delivery_note_form_page.dart';
import 'delivery_note_view_page.dart';

class AdminDeliveryNotesPage extends StatefulWidget {
  const AdminDeliveryNotesPage({super.key});

  @override
  State<AdminDeliveryNotesPage> createState() => _AdminDeliveryNotesPageState();
}

class _AdminDeliveryNotesPageState extends State<AdminDeliveryNotesPage> {
  static const _navy = Color(0xFF031273);
  static const _sky = Color(0xFF0056D2);

  final _api = DeliveryNoteService();
  final _search = TextEditingController();
  List<DeliveryNoteRecord> _items = [];
  bool _loading = true;
  String? _error;
  String? _pdfLoadingId;

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

  List<DeliveryNoteRecord> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((n) {
      return '${n.deliveryNoteNo} ${n.customerName} ${n.vehicleBrand} ${n.vehicleModel} ${n.registrationNo} ${n.userEmail}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _openCreate() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const DeliveryNoteFormPage(adminMode: true),
      ),
    );
    if (saved == true) await _load();
  }

  void _view(DeliveryNoteRecord item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliveryNoteViewPage(
          note: item,
          pdfLoading: _pdfLoadingId == item.id,
          onPdf: () => _downloadPdf(item),
          onEdit: () async {
            Navigator.of(context).pop();
            await _edit(item);
          },
        ),
      ),
    );
  }

  Future<void> _edit(DeliveryNoteRecord item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DeliveryNoteFormPage(existing: item, adminMode: true),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(DeliveryNoteRecord item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete note?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800)),
        content: Text(
          'Remove ${item.deliveryNoteNo.isNotEmpty ? item.deliveryNoteNo : item.customerName}?',
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
    if (ok != true) return;
    try {
      await _api.delete(item.id);
      if (!mounted) return;
      AppToast.success(context, 'Deleted');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _downloadPdf(DeliveryNoteRecord item) async {
    setState(() => _pdfLoadingId = item.id);
    try {
      final bytes = await _api.downloadPdf(item.id);
      final name = item.deliveryNoteNo.isNotEmpty ? item.deliveryNoteNo : 'delivery-note';
      if (kIsWeb) {
        if (!mounted) return;
        AppToast.error(context, 'PDF download is not supported on web yet');
        return;
      }
      final result = await saveAndOpenPdf(bytes: bytes, baseName: name);
      if (!mounted) return;
      if (result.shared) {
        AppToast.success(context, 'PDF ready — choose Open or Save');
      } else {
        AppToast.success(context, 'PDF saved: ${result.path}');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _pdfLoadingId = null);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
            AdminListHeader(
              title: 'Delivery notes',
              actions: [
                IconButton(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'New note',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Total notes',
                        value: '${_items.length}',
                        icon: Icons.receipt_long_rounded,
                        color: _sky,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatPill(
                        label: 'Showing',
                        value: '${filtered.length}',
                        icon: Icons.filter_list_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
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
                    hintText: 'Search customer, vehicle, note no…',
                    prefixIcon: const Icon(Icons.search_rounded, color: _sky),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No delivery notes yet',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final pdfBusy = _pdfLoadingId == item.id;
                    return _NoteCard(
                      item: item,
                      initials: _initials(item.customerName),
                      pdfBusy: pdfBusy,
                      onView: () => _view(item),
                      onPdf: () => _downloadPdf(item),
                      onEdit: () => _edit(item),
                      onDelete: () => _delete(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: _navy,
        icon: const Icon(Icons.add_rounded),
        label: Text('New note', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.item,
    required this.initials,
    required this.pdfBusy,
    required this.onView,
    required this.onPdf,
    required this.onEdit,
    required this.onDelete,
  });

  final DeliveryNoteRecord item;
  final String initials;
  final bool pdfBusy;
  final VoidCallback onView;
  final VoidCallback onPdf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF031273);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [navy, Color(0xFF0056D2)]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: navy.withValues(alpha: 0.1),
                          child: Text(
                            initials,
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, color: navy),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.customerName.isNotEmpty ? item.customerName : 'Customer',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isBuy
                                          ? const Color(0xFFFFF7ED)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: item.isBuy
                                            ? const Color(0xFFFB923C)
                                            : const Color(0xFF0056D2),
                                      ),
                                    ),
                                    child: Text(
                                      item.noteTypeLabel,
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: item.isBuy
                                            ? const Color(0xFFAD5B00)
                                            : const Color(0xFF0056D2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.deliveryNoteNo.isNotEmpty
                                          ? item.deliveryNoteNo
                                          : 'Delivery note',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: const Color(0xFF0056D2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (item.totalPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              formatInr(item.totalPrice!),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF047857),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.directions_car_filled_rounded,
                      text: '${item.vehicleLabel}${item.registrationNo.isNotEmpty ? ' • ${item.registrationNo}' : ''}',
                    ),
                    if (item.userEmail.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoRow(icon: Icons.mail_outline_rounded, text: item.userEmail),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.visibility_rounded,
                            label: 'View',
                            color: const Color(0xFF0EA5E9),
                            onTap: onView,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.picture_as_pdf_rounded,
                            label: pdfBusy ? 'PDF…' : 'PDF',
                            color: const Color(0xFFDC2626),
                            onTap: pdfBusy ? null : onPdf,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            color: navy,
                            onTap: onEdit,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _IconAction(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFDC2626),
                          onTap: onDelete,
                        ),
                      ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: color,
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

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
