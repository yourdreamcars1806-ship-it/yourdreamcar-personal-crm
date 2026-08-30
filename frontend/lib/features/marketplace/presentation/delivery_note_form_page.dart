import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/inr.dart';
import '../../../core/ui/app_logo.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/delivery_note_service.dart';

class DeliveryNoteFormPage extends StatefulWidget {
  const DeliveryNoteFormPage({
    super.key,
    this.existing,
    this.adminMode = false,
  });

  final DeliveryNoteRecord? existing;
  final bool adminMode;

  @override
  State<DeliveryNoteFormPage> createState() => _DeliveryNoteFormPageState();
}

class _DeliveryNoteFormPageState extends State<DeliveryNoteFormPage> {
  static const _navy = Color(0xFF031273);
  static const _sky = Color(0xFF0056D2);
  static const _bg = Color(0xFFF0F4FA);

  final _api = DeliveryNoteService();
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  late final TextEditingController _noteNo;
  late final TextEditingController _deliveryTime;
  late final TextEditingController _customerName;
  late final TextEditingController _customerAddress;
  late final TextEditingController _customerMobile;
  late final TextEditingController _idProofType;
  late final TextEditingController _idProofNo;
  late final TextEditingController _vehicleBrand;
  late final TextEditingController _vehicleModel;
  late final TextEditingController _registrationNo;
  late final TextEditingController _year;
  late final TextEditingController _colour;
  late final TextEditingController _fuelType;
  late final TextEditingController _chassisNo;
  late final TextEditingController _engineNo;
  late final TextEditingController _odometer;
  late final TextEditingController _totalPrice;
  late final TextEditingController _amountReceived;
  late final TextEditingController _balance;
  late final TextEditingController _documents;
  late final TextEditingController _declarationName;
  late final TextEditingController _signatureName;
  late final TextEditingController _authorizedName;
  late final TextEditingController _handedOverBy;
  late final TextEditingController _userEmail;

  DateTime? _deliveryDate;
  String _noteType = 'sell';
  String _paymentMode = '';
  bool _submitting = false;
  final Set<String> _docChecks = {};

  static const _docOptions = [
    'RC',
    'Insurance',
    'PUC',
    'Service Records',
    'Keys',
    'Spare Key',
  ];

  static const _paymentModes = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Finance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _noteNo = TextEditingController(text: e?.deliveryNoteNo ?? '');
    _deliveryTime = TextEditingController(text: e?.deliveryTime ?? '');
    _customerName = TextEditingController(text: e?.customerName ?? '');
    _customerAddress = TextEditingController(text: e?.customerAddress ?? '');
    _customerMobile = TextEditingController(text: e?.customerMobile ?? '');
    _idProofType = TextEditingController(text: e?.idProofType ?? '');
    _idProofNo = TextEditingController(text: e?.idProofNo ?? '');
    _vehicleBrand = TextEditingController(text: e?.vehicleBrand ?? '');
    _vehicleModel = TextEditingController(text: e?.vehicleModel ?? '');
    _registrationNo = TextEditingController(text: e?.registrationNo ?? '');
    _year = TextEditingController(text: e?.yearOfManufacture?.toString() ?? '');
    _colour = TextEditingController(text: e?.colour ?? '');
    _fuelType = TextEditingController(text: e?.fuelType ?? '');
    _chassisNo = TextEditingController(text: e?.chassisNo ?? '');
    _engineNo = TextEditingController(text: e?.engineNo ?? '');
    _odometer = TextEditingController(text: e?.odometerKm?.toString() ?? '');
    _totalPrice = TextEditingController(
      text: e?.totalPrice != null ? e!.totalPrice!.toStringAsFixed(0) : '',
    );
    _amountReceived = TextEditingController(
      text: e?.amountReceived != null ? e!.amountReceived!.toStringAsFixed(0) : '',
    );
    _balance = TextEditingController(
      text: e?.balanceAmount != null ? e!.balanceAmount!.toStringAsFixed(0) : '',
    );
    _documents = TextEditingController(text: e?.documentsHandedOver ?? '');
    _declarationName = TextEditingController(
      text: e?.declarationCustomerName ?? e?.customerName ?? '',
    );
    _signatureName = TextEditingController(
      text: e?.customerSignatureName ?? e?.customerName ?? '',
    );
    _authorizedName = TextEditingController(text: e?.authorizedSignatoryName ?? '');
    _handedOverBy = TextEditingController(text: e?.vehicleHandedOverBy ?? '');
    _userEmail = TextEditingController(text: e?.userEmail ?? '');
    _deliveryDate = e?.deliveryDate ?? DateTime.now();
    _noteType = e?.noteType ?? 'sell';
    _paymentMode = e?.paymentMode ?? '';

    if (_documents.text.isNotEmpty) {
      for (final d in _docOptions) {
        if (_documents.text.toLowerCase().contains(d.toLowerCase())) {
          _docChecks.add(d);
        }
      }
    } else {
      _docChecks.addAll(_docOptions.take(4));
      _syncDocField();
    }

    _totalPrice.addListener(_recalcBalance);
    _amountReceived.addListener(_recalcBalance);
    _customerName.addListener(_syncDeclarationName);
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _noteNo, _deliveryTime, _customerName, _customerAddress, _customerMobile,
      _idProofType, _idProofNo, _vehicleBrand, _vehicleModel, _registrationNo,
      _year, _colour, _fuelType, _chassisNo, _engineNo, _odometer,
      _totalPrice, _amountReceived, _balance, _documents, _declarationName,
      _signatureName, _authorizedName, _handedOverBy, _userEmail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncDeclarationName() {
    if (_declarationName.text.trim().isEmpty) {
      _declarationName.text = _customerName.text;
    }
    if (_signatureName.text.trim().isEmpty) {
      _signatureName.text = _customerName.text;
    }
  }

  void _recalcBalance() {
    final total = double.tryParse(_totalPrice.text.trim());
    final paid = double.tryParse(_amountReceived.text.trim());
    if (total != null && paid != null) {
      _balance.text = (total - paid).clamp(0, double.infinity).toStringAsFixed(0);
    }
  }

  void _syncDocField() {
    final extra = _documents.text.trim();
    final picked = _docChecks.toList()..sort();
    _documents.text = picked.isEmpty ? extra : picked.join(', ');
  }

  double get _progress {
    int filled = 0;
    int total = 8;
    if (_customerName.text.trim().isNotEmpty) filled++;
    if (_customerMobile.text.trim().isNotEmpty) filled++;
    if (_vehicleBrand.text.trim().isNotEmpty || _vehicleModel.text.trim().isNotEmpty) {
      filled++;
    }
    if (_registrationNo.text.trim().isNotEmpty) filled++;
    if (_totalPrice.text.trim().isNotEmpty) filled++;
    if (_paymentMode.isNotEmpty) filled++;
    if (_documents.text.trim().isNotEmpty) filled++;
    if (_signatureName.text.trim().isNotEmpty) filled++;
    return filled / total;
  }

  Map<String, dynamic> _payload() {
    int? parseInt(String s) => int.tryParse(s.trim());
    double? parseDouble(String s) => double.tryParse(s.trim());
    _syncDocField();
    return {
      'noteType': _noteType,
      if (widget.adminMode && _noteNo.text.trim().isNotEmpty)
        'deliveryNoteNo': _noteNo.text.trim(),
      'deliveryDate': _deliveryDate?.toUtc().toIso8601String(),
      'deliveryTime': _deliveryTime.text.trim(),
      'customerName': _customerName.text.trim(),
      'customerAddress': _customerAddress.text.trim(),
      'customerMobile': _customerMobile.text.trim(),
      'idProofType': _idProofType.text.trim(),
      'idProofNo': _idProofNo.text.trim(),
      'vehicleBrand': _vehicleBrand.text.trim(),
      'vehicleModel': _vehicleModel.text.trim(),
      'registrationNo': _registrationNo.text.trim(),
      'yearOfManufacture': parseInt(_year.text),
      'colour': _colour.text.trim(),
      'fuelType': _fuelType.text.trim(),
      'chassisNo': _chassisNo.text.trim(),
      'engineNo': _engineNo.text.trim(),
      'odometerKm': parseInt(_odometer.text),
      'totalPrice': parseDouble(_totalPrice.text),
      'amountReceived': parseDouble(_amountReceived.text),
      'balanceAmount': parseDouble(_balance.text),
      'paymentMode': _paymentMode,
      'documentsHandedOver': _documents.text.trim(),
      'declarationCustomerName': _declarationName.text.trim(),
      'customerSignatureName': _signatureName.text.trim(),
      'signedAt': DateTime.now().toUtc().toIso8601String(),
      'authorizedSignatoryName': _authorizedName.text.trim(),
      'vehicleHandedOverBy': _handedOverBy.text.trim(),
      if (widget.adminMode && _userEmail.text.trim().isNotEmpty)
        'userEmail': _userEmail.text.trim().toLowerCase(),
    };
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _navy)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _navy)),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final ampm = picked.period == DayPeriod.am ? 'AM' : 'PM';
      _deliveryTime.text = '$h:${picked.minute.toString().padLeft(2, '0')} $ampm';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.adminMode &&
        widget.existing == null &&
        _userEmail.text.trim().isEmpty) {
      AppToast.error(context, 'Customer account email is required');
      return;
    }
    setState(() => _submitting = true);
    try {
      if (widget.existing != null && widget.adminMode) {
        await _api.update(widget.existing!.id, _payload());
        if (!mounted) return;
        AppToast.success(context, 'Delivery note updated');
      } else {
        await _api.create(_payload());
        if (!mounted) return;
        AppToast.success(context, 'Delivery note submitted');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final progress = _progress;

    return Scaffold(
      backgroundColor: _bg,
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverAppBar(
                  expandedHeight: 168,
                  pinned: true,
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    title: Text(
                      editing ? 'Edit note' : 'Delivery note',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_navy, _sky, Color(0xFF3D8BFF)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -20,
                            child: Icon(
                              Icons.description_rounded,
                              size: 140,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 72, 20, 52),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  child: const AppLogo(round: true, width: 52),
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
                                          fontSize: 20,
                                          letterSpacing: 0.5,
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
                                      const SizedBox(height: 6),
                                      Text(
                                        _noteType == 'buy'
                                            ? 'Vehicle purchase note'
                                            : 'Vehicle delivery note',
                                        style: GoogleFonts.dmSans(
                                          color: const Color(0xFFFFC14A),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          letterSpacing: 0.8,
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _ProgressCard(progress: progress),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (widget.adminMode)
                        _section(
                          step: '00',
                          icon: Icons.swap_horiz_rounded,
                          title: 'Note type',
                          subtitle: 'Buy from customer or sell to customer',
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'sell',
                                  label: Text('Sell'),
                                  icon: Icon(Icons.sell_outlined, size: 18),
                                ),
                                ButtonSegment(
                                  value: 'buy',
                                  label: Text('Buy'),
                                  icon: Icon(Icons.shopping_bag_outlined, size: 18),
                                ),
                              ],
                              selected: {_noteType},
                              onSelectionChanged: _submitting
                                  ? null
                                  : (s) => setState(() => _noteType = s.first),
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                textStyle: WidgetStatePropertyAll(
                                  GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      _section(
                        step: '01',
                        icon: Icons.event_note_rounded,
                        title: 'Delivery details',
                        subtitle: 'Date, time & reference number',
                        children: [
                          if (widget.adminMode && widget.existing == null)
                            _field(
                              _userEmail,
                              _noteType == 'buy'
                                  ? 'Seller account email'
                                  : 'Customer account email',
                              icon: Icons.alternate_email_rounded,
                              required: true,
                              hint: _noteType == 'buy'
                                  ? 'Seller must have this login email'
                                  : 'Buyer must have this login email',
                              keyboard: TextInputType.emailAddress,
                            ),
                          if (widget.adminMode)
                            _field(_noteNo, 'Delivery note no.', icon: Icons.tag_rounded),
                          Row(
                            children: [
                              Expanded(child: _dateTile()),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _field(
                                  _deliveryTime,
                                  'Delivery time',
                                  icon: Icons.schedule_rounded,
                                  readOnly: true,
                                  onTap: _pickTime,
                                  hint: 'Tap to pick',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _section(
                        step: '02',
                        icon: Icons.person_outline_rounded,
                        title: _noteType == 'buy' ? 'Seller details' : 'Customer details',
                        subtitle: _noteType == 'buy'
                            ? 'Person selling the vehicle to us'
                            : 'Buyer information & ID proof',
                        children: [
                          _field(
                            _customerName,
                            _noteType == 'buy' ? 'Seller name' : 'Customer name',
                            icon: Icons.badge_outlined,
                            required: true,
                          ),
                          _field(
                            _customerAddress,
                            'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                          _field(
                            _customerMobile,
                            'Mobile no.',
                            icon: Icons.phone_android_rounded,
                            keyboard: TextInputType.phone,
                            required: true,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _field(_idProofType, 'ID proof', icon: Icons.credit_card_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _field(_idProofNo, 'ID no.', icon: Icons.numbers_rounded)),
                            ],
                          ),
                        ],
                      ),
                      _section(
                        step: '03',
                        icon: Icons.directions_car_filled_rounded,
                        title: 'Vehicle details',
                        subtitle: 'Make, model, registration & specs',
                        children: [
                          Row(
                            children: [
                              Expanded(child: _field(_vehicleBrand, 'Make / brand', icon: Icons.factory_outlined)),
                              const SizedBox(width: 10),
                              Expanded(child: _field(_vehicleModel, 'Model / variant', icon: Icons.category_outlined)),
                            ],
                          ),
                          _field(_registrationNo, 'Registration no.', icon: Icons.confirmation_number_outlined),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  _year,
                                  'Year',
                                  icon: Icons.calendar_month_outlined,
                                  keyboard: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _field(_colour, 'Colour', icon: Icons.palette_outlined)),
                            ],
                          ),
                          _field(_fuelType, 'Fuel type', icon: Icons.local_gas_station_outlined),
                          _field(_chassisNo, 'Chassis no.', icon: Icons.qr_code_2_rounded),
                          _field(_engineNo, 'Engine no.', icon: Icons.settings_outlined),
                          _field(
                            _odometer,
                            'Odometer (KM)',
                            icon: Icons.speed_rounded,
                            keyboard: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ],
                      ),
                      _section(
                        step: '04',
                        icon: Icons.payments_outlined,
                        title: 'Payment details',
                        subtitle: 'Price, received amount & mode',
                        children: [
                          _field(
                            _totalPrice,
                            'Total vehicle price',
                            icon: Icons.currency_rupee_rounded,
                            keyboard: TextInputType.number,
                            prefix: '₹ ',
                          ),
                          _field(
                            _amountReceived,
                            'Amount received',
                            icon: Icons.account_balance_wallet_outlined,
                            keyboard: TextInputType.number,
                            prefix: '₹ ',
                          ),
                          _field(
                            _balance,
                            'Balance amount',
                            icon: Icons.balance_rounded,
                            readOnly: true,
                            prefix: '₹ ',
                          ),
                          if (_balance.text.isNotEmpty &&
                              double.tryParse(_balance.text) != null &&
                              double.parse(_balance.text) > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDBA74)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Balance pending: ${formatInr(double.parse(_balance.text))}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF9A3412),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            'Payment mode',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _paymentModes.map((mode) {
                              final selected = _paymentMode == mode;
                              return FilterChip(
                                label: Text(mode),
                                selected: selected,
                                onSelected: (_) => setState(() => _paymentMode = mode),
                                selectedColor: _navy.withValues(alpha: 0.12),
                                checkmarkColor: _navy,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected ? _navy : const Color(0xFF64748B),
                                ),
                                side: BorderSide(
                                  color: selected ? _navy : const Color(0xFFE2E8F0),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      _section(
                        step: '05',
                        icon: Icons.folder_shared_outlined,
                        title: 'Documents handed over',
                        subtitle: 'Select items delivered with the vehicle',
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _docOptions.map((d) {
                              final selected = _docChecks.contains(d);
                              return FilterChip(
                                label: Text(d),
                                selected: selected,
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _docChecks.add(d);
                                    } else {
                                      _docChecks.remove(d);
                                    }
                                    _syncDocField();
                                  });
                                },
                                selectedColor: const Color(0xFFDCFCE7),
                                checkmarkColor: const Color(0xFF15803D),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          _field(
                            _documents,
                            'Additional notes',
                            icon: Icons.note_alt_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      _section(
                        step: '06',
                        icon: Icons.draw_outlined,
                        title: 'Delivery declaration',
                        subtitle: 'Customer acknowledgment & signatures',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _navy.withValues(alpha: 0.06),
                                  _sky.withValues(alpha: 0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'I confirm that I have inspected the vehicle and taken physical delivery from Your Dream Cars. I acknowledge receipt of keys and documents listed above.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13.5,
                                height: 1.5,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field(_declarationName, 'Declaration name', icon: Icons.edit_note_rounded),
                          _field(_signatureName, 'Customer signature name', icon: Icons.draw_rounded),
                          if (widget.adminMode) ...[
                            _field(
                              _authorizedName,
                              'Authorized signatory',
                              icon: Icons.verified_user_outlined,
                            ),
                            _field(
                              _handedOverBy,
                              'Vehicle handed over by',
                              icon: Icons.handshake_outlined,
                            ),
                          ],
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded),
                              const SizedBox(width: 8),
                              Text(
                                editing ? 'Save changes' : 'Submit delivery note',
                                style: GoogleFonts.dmSans(
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
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String step,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_navy, _sky]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            step,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: _sky,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    String? hint,
    String? prefix,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          prefixIcon: icon != null ? Icon(icon, size: 20, color: _sky) : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _navy, width: 1.5),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _dateTile() {
    final label = _deliveryDate == null
        ? 'Select date'
        : '${_deliveryDate!.day.toString().padLeft(2, '0')} / ${_deliveryDate!.month.toString().padLeft(2, '0')} / ${_deliveryDate!.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Delivery date',
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: _sky),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Form completion',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF031273),
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0056D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF0056D2),
            ),
          ),
        ],
      ),
    );
  }
}
