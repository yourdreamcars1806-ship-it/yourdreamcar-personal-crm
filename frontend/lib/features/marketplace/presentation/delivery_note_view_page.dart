import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/inr.dart';
import '../../../core/ui/app_logo.dart';
import '../../../services/delivery_note_service.dart';

class DeliveryNoteViewPage extends StatelessWidget {
  const DeliveryNoteViewPage({
    super.key,
    required this.note,
    this.onEdit,
    this.onPdf,
    this.pdfLoading = false,
  });

  final DeliveryNoteRecord note;
  final VoidCallback? onEdit;
  final VoidCallback? onPdf;
  final bool pdfLoading;

  static const _navy = Color(0xFF031273);
  static const _sky = Color(0xFF0056D2);

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }

  String _val(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? '—' : t;
  }

  String _valNum(num? n) {
    if (n == null) return '—';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            centerTitle: false,
            title: Text(
              note.deliveryNoteNo.isNotEmpty ? note.deliveryNoteNo : 'Delivery note',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            actions: [
              if (onPdf != null)
                IconButton(
                  onPressed: pdfLoading ? null : onPdf,
                  icon: pdfLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  tooltip: 'Download PDF',
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _sky, Color(0xFF3D8BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_navy, _sky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40003173),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.95),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const AppLogo(round: true, width: 56),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR DREAM CARS',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Clover Hills Plaza, NIBM, Pune',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xCCFFFFFF),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          note.isBuy
                              ? 'VEHICLE PURCHASE NOTE'
                              : 'VEHICLE DELIVERY NOTE',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFFFC14A),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          note.customerName.isNotEmpty
                              ? note.customerName
                              : (note.isBuy ? 'Seller' : 'Customer'),
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _summaryStrip(),
                const SizedBox(height: 14),
                _section('Delivery details', Icons.event_note_rounded, [
                  _row('Delivery note no.', note.deliveryNoteNo),
                  _row('Date', _fmtDate(note.deliveryDate)),
                  _row('Time', note.deliveryTime),
                ]),
                _section(
                  note.isBuy ? 'Seller details' : 'Customer details',
                  Icons.person_outline_rounded,
                  [
                  _row(note.isBuy ? 'Seller name' : 'Customer name', note.customerName),
                  _row('Address', note.customerAddress),
                  _row('Mobile', note.customerMobile),
                  _row('ID proof', note.idProofType),
                  _row('ID no.', note.idProofNo),
                  if (note.userEmail.isNotEmpty) _row('Submitted by', note.userEmail),
                ]),
                _section('Vehicle details', Icons.directions_car_filled_rounded, [
                  _row('Make / brand', note.vehicleBrand),
                  _row('Model / variant', note.vehicleModel),
                  _row('Registration no.', note.registrationNo),
                  _row('Year', _valNum(note.yearOfManufacture)),
                  _row('Colour', note.colour),
                  _row('Fuel type', note.fuelType),
                  _row('Chassis no.', note.chassisNo),
                  _row('Engine no.', note.engineNo),
                  _row('Odometer (KM)', _valNum(note.odometerKm)),
                ]),
                _section('Payment details', Icons.payments_outlined, [
                  _row('Total price', note.totalPrice != null ? formatInr(note.totalPrice!) : '—'),
                  _row('Amount received', note.amountReceived != null ? formatInr(note.amountReceived!) : '—'),
                  _row('Balance', note.balanceAmount != null ? formatInr(note.balanceAmount!) : '—'),
                  _row('Payment mode', note.paymentMode),
                ]),
                _section('Documents handed over', Icons.folder_shared_outlined, [
                  _row('Items', note.documentsHandedOver),
                ]),
                _section('Declaration', Icons.draw_outlined, [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      note.isBuy
                          ? 'I, ${_val(note.declarationCustomerName)}, confirm sale of the vehicle to Your Dream Cars and handover of keys/documents as listed above.'
                          : 'I, ${_val(note.declarationCustomerName)}, confirm physical delivery of the vehicle and receipt of keys/documents as listed above.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        height: 1.5,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _row(
                    note.isBuy ? 'Seller signature name' : 'Customer signature name',
                    note.customerSignatureName,
                  ),
                  _row('Signed date', _fmtDate(note.signedAt)),
                  if (note.authorizedSignatoryName.isNotEmpty)
                    _row('Authorized signatory', note.authorizedSignatoryName),
                  if (note.vehicleHandedOverBy.isNotEmpty)
                    _row('Handed over by', note.vehicleHandedOverBy),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: const AppLogo(round: true, width: 46),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.vehicleLabel,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (note.registrationNo.isNotEmpty) note.registrationNo,
                    if (note.paymentMode.isNotEmpty) note.paymentMode,
                  ].join(' • '),
                  style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (note.totalPrice != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatInr(note.totalPrice!),
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF047857),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: _sky),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _val(value),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
