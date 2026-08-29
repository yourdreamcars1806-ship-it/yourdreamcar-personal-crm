import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/inr.dart';
import '../../../core/io/pdf_file_helper.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/delivery_note_service.dart';
import 'delivery_note_view_page.dart';

class UserDeliveryNotesPage extends StatefulWidget {
  const UserDeliveryNotesPage({super.key});

  @override
  State<UserDeliveryNotesPage> createState() => _UserDeliveryNotesPageState();
}

class _UserDeliveryNotesPageState extends State<UserDeliveryNotesPage> {
  static const _navy = Color(0xFF031273);
  static const _sky = Color(0xFF0056D2);

  final _api = DeliveryNoteService();
  List<DeliveryNoteRecord> _items = [];
  bool _loading = true;
  String? _error;
  String? _pdfLoadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listMine();
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

  void _view(DeliveryNoteRecord item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliveryNoteViewPage(
          note: item,
          pdfLoading: _pdfLoadingId == item.id,
          onPdf: () => _downloadPdf(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _sky,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy, _sky],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'My delivery notes',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vehicle delivery documents issued by Your Dream Cars',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xCCFFFFFF),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _sky.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined, size: 40, color: _sky),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No delivery notes yet',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: MarketColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When admin issues your vehicle delivery note, it will appear here with PDF download.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: MarketColors.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final pdfBusy = _pdfLoadingId == item.id;
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _view(item),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8EEF5)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.vehicleLabel,
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.deliveryNoteNo.isNotEmpty
                                              ? item.deliveryNoteNo
                                              : 'Delivery note',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: _sky,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.totalPrice != null)
                                    Text(
                                      formatInr(item.totalPrice!),
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF047857),
                                      ),
                                    ),
                                ],
                              ),
                              if (item.registrationNo.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.registrationNo,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _view(item),
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      label: const Text('View'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: pdfBusy ? null : () => _downloadPdf(item),
                                      icon: pdfBusy
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                      label: Text(pdfBusy ? 'PDF…' : 'Download PDF'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
