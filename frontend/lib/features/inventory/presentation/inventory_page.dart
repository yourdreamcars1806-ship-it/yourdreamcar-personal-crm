import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/expense_service.dart';
import '../../../services/car_service.dart';
import '../../../services/car_catalog_service.dart';
import '../../expenses/domain/expense_entry.dart';

String _inventoryCarSubtitle(CarRecord car) {
  final base = '${car.brand} · ${car.model} · ${car.year}';
  final vn = car.vehicleNumber.trim();
  if (vn.isEmpty) return base;
  return '$base · $vn';
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, this.onCarCountChanged});

  final ValueChanged<int>? onCarCountChanged;

  @override
  State<InventoryPage> createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage> {
  static const List<String> _ownershipChoices = [
    '1st owner',
    '2nd owner',
    '3rd owner',
    '4th owner',
    '5th owner',
    'multiple owner',
  ];

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _carsApi = CarService();
  final _titleController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _picked;
  List<File> _exteriorPicked = [];
  List<File> _interiorPicked = [];
  List<String> _existingExterior = [];
  List<String> _existingInterior = [];
  String _fuelType = 'PETROL';
  String _ownership = '1st owner';
  String _availability = 'stock';
  bool _liveBidEnabled = false;
  DateTime _buyDate = DateTime.now();
  DateTime? _saleDate;
  List<CarRecord> _cars = [];
  CarRecord? _editingCar;
  String? _statusMessage;
  bool _busy = false;

  /// When true, Add/Edit form is shown. Default false = inventory list only.
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  List<String> get _ownershipItems => _ownershipChoices.contains(_ownership)
      ? _ownershipChoices
      : [..._ownershipChoices, _ownership];

  @override
  void dispose() {
    _titleController.dispose();
    _vehicleNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Drawer: show inventory list (not the form).
  void openCarManager() {
    setState(() => _showAddForm = false);
  }

  /// Drawer: open add-car form.
  void openAddCarForm() {
    setState(() {
      _clearForm();
      _showAddForm = true;
      _statusMessage = null;
    });
  }

  Future<void> _loadCars() async {
    try {
      final response = await _carsApi.listCars(limit: 300);
      if (!mounted) return;
      setState(() {
        _cars = response.cars;
      });
      widget.onCarCountChanged?.call(response.total);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
    }
  }

  Future<void> _pick() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() {
      _picked = File(x.path);
    });
  }

  Future<void> _pickExterior() async {
    final xs = await _picker.pickMultiImage(
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (xs.isEmpty) return;
    setState(() {
      _exteriorPicked = [..._exteriorPicked, ...xs.map((x) => File(x.path))];
    });
  }

  Future<void> _pickInterior() async {
    final xs = await _picker.pickMultiImage(
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (xs.isEmpty) return;
    setState(() {
      _interiorPicked = [..._interiorPicked, ...xs.map((x) => File(x.path))];
    });
  }

  Future<void> _pickDate({required bool saleDate}) async {
    final initial = saleDate ? (_saleDate ?? DateTime.now()) : _buyDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (saleDate) {
        _saleDate = picked;
      } else {
        _buyDate = picked;
      }
    });
  }

  String _fmtDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, String> _buildFields() {
    return {
      'title': _titleController.text.trim(),
      'vehicleNumber': _vehicleNumberController.text.trim(),
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'fuelType': _fuelType,
      'ownership': _ownership,
      'availability': _availability,
      'year': _yearController.text.trim(),
      'buyPrice': _buyPriceController.text.trim(),
      'sellPrice': _sellPriceController.text.trim(),
      'buyDate': _fmtDate(_buyDate),
      'saleDate': _saleDate == null ? '' : _fmtDate(_saleDate!),
      'description': _descriptionController.text.trim(),
      'liveBidEnabled': _liveBidEnabled ? 'true' : 'false',
    };
  }

  Map<String, String> _fieldsFromCar(CarRecord car, {bool? liveBidEnabled}) {
    return {
      'title': car.title,
      'vehicleNumber': car.vehicleNumber,
      'brand': car.brand,
      'model': car.model,
      'fuelType': car.fuelType,
      'ownership': car.ownership,
      'availability': car.availability,
      'year': '${car.year}',
      'buyPrice': car.buyPrice.toStringAsFixed(0),
      'sellPrice': car.sellPrice.toStringAsFixed(0),
      'buyDate': _fmtDate(car.buyDate),
      'saleDate': car.saleDate == null ? '' : _fmtDate(car.saleDate!),
      'description': car.description,
      'liveBidEnabled': (liveBidEnabled ?? car.liveBidEnabled) ? 'true' : 'false',
    };
  }

  Future<void> _toggleLiveBid(CarRecord car, bool enabled) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMessage = enabled ? 'Starting live bid…' : 'Stopping live bid…';
    });
    try {
      await _carsApi.updateCar(
        id: car.id,
        fields: _fieldsFromCar(car, liveBidEnabled: enabled),
        keepExteriorUrls: car.exteriorImages,
        keepInteriorUrls: car.interiorImages,
      );
      await _loadCars();
      if (!mounted) return;
      AppToast.success(
        context,
        enabled ? 'Live bidding enabled' : 'Live bidding disabled',
      );
      setState(() => _statusMessage = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.toString());
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitCar() async {
    if (_busy) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    final isEditing = _editingCar != null;
    if (_editingCar == null && _picked == null) {
      setState(() => _statusMessage = 'Image is required for new car');
      AppToast.error(context, 'Image is required for new car');
      return;
    }

    setState(() {
      _busy = true;
      _statusMessage = _editingCar == null
          ? 'Adding car...'
          : 'Updating car...';
    });
    try {
      if (_editingCar == null) {
        await _carsApi.createCar(
          fields: _buildFields(),
          imageFile: _picked!,
          exteriorImages: _exteriorPicked,
          interiorImages: _interiorPicked,
        );
      } else {
        await _carsApi.updateCar(
          id: _editingCar!.id,
          fields: _buildFields(),
          imageFile: _picked,
          exteriorImages: _exteriorPicked,
          interiorImages: _interiorPicked,
          keepExteriorUrls: _existingExterior,
          keepInteriorUrls: _existingInterior,
        );
      }
      CarCatalogService.instance.invalidate();
      unawaited(CarCatalogService.instance.load(force: true));
      if (!mounted) return;
      _clearForm();
      await _loadCars();
      setState(() {
        _statusMessage = isEditing
            ? 'Car updated successfully'
            : 'Car added successfully';
        _showAddForm = false;
      });
      AppToast.success(
        context,
        isEditing ? 'Car updated successfully' : 'Car added successfully',
      );
    } catch (e) {
      setState(() {
        _statusMessage = e.toString();
      });
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _clearForm() {
    _editingCar = null;
    _picked = null;
    _exteriorPicked = [];
    _interiorPicked = [];
    _existingExterior = [];
    _existingInterior = [];
    _titleController.clear();
    _vehicleNumberController.clear();
    _brandController.clear();
    _modelController.clear();
    _yearController.clear();
    _buyPriceController.clear();
    _sellPriceController.clear();
    _descriptionController.clear();
    _fuelType = 'PETROL';
    _ownership = '1st owner';
    _availability = 'stock';
    _liveBidEnabled = false;
    _buyDate = DateTime.now();
    _saleDate = null;
  }

  void _startEdit(CarRecord car) {
    setState(() {
      _editingCar = car;
      _picked = null;
      _exteriorPicked = [];
      _interiorPicked = [];
      _existingExterior = [...car.exteriorImages];
      _existingInterior = [...car.interiorImages];
      _titleController.text = car.title;
      _vehicleNumberController.text = car.vehicleNumber;
      _brandController.text = car.brand;
      _modelController.text = car.model;
      _yearController.text = '${car.year}';
      _buyPriceController.text = car.buyPrice.toStringAsFixed(0);
      _sellPriceController.text = car.sellPrice.toStringAsFixed(0);
      _descriptionController.text = car.description;
      _fuelType = car.fuelType;
      _ownership = car.ownership;
      _availability = car.availability;
      _liveBidEnabled = car.liveBidEnabled;
      _buyDate = car.buyDate;
      _saleDate = car.saleDate;
      _showAddForm = true;
      _statusMessage = null;
    });
  }

  Future<void> _deleteCar(CarRecord car) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete car'),
        content: Text('Delete ${car.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    setState(() {
      _busy = true;
      _statusMessage = 'Deleting ${car.title}...';
    });
    try {
      await _carsApi.deleteCar(car.id);
      await _loadCars();
      if (!mounted) return;
      setState(() => _statusMessage = 'Deleted ${car.title}');
      AppToast.success(context, 'Deleted ${car.title}');
    } catch (e) {
      setState(() => _statusMessage = e.toString());
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _closeForm() {
    setState(() {
      _showAddForm = false;
      _clearForm();
      _statusMessage = null;
    });
  }

  static const Color _formInk = Color(0xFF16345E);
  static const Color _formLabel = Color(0xFF5B769E);
  static const Color _formBorder = Color(0xFFD7E5FF);
  static const Color _formAccent = Color(0xFF1D63ED);

  InputDecoration _formInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _formLabel, fontWeight: FontWeight.w500),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
        top: 16,
        bottom: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _formBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _formBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _formAccent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.3),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    bool requiredField = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: _formInk,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: _formInputDecoration(label).copyWith(
        hintText: hintText,
        hintStyle: TextStyle(
          color: _formLabel.withValues(alpha: 0.75),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      validator: requiredField
          ? (value) {
              if ((value ?? '').trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : (_) => null,
    );
  }

  Widget _photoPreviewStrip({
    required double maxW,
    required List<String> existingUrls,
    required List<File> pickedFiles,
    required ValueChanged<String> onRemoveExisting,
    required ValueChanged<int> onRemovePicked,
  }) {
    if (existingUrls.isEmpty && pickedFiles.isEmpty) {
      return SizedBox(width: maxW);
    }
    return SizedBox(
      width: maxW,
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final url in existingUrls)
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 8, top: 4),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onRemoveExisting(url),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < pickedFiles.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 8, top: 4),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      pickedFiles[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onRemovePicked(i),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _formSectionHeader(
    double maxWidth,
    String title,
    IconData icon, {
    bool first = false,
  }) {
    return SizedBox(
      width: maxWidth,
      child: Padding(
        padding: EdgeInsets.only(top: first ? 2 : 18, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _formAccent),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _formLabel.withValues(alpha: 0.95),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: _formBorder.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerTile({
    required double width,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy ? null : onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _formBorder),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: _formAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.25,
                        color: _formInk,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 22,
                    color: _formLabel.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Display label for dropdown items (API values stay raw: PETROL, stock, …).
  static String _dropdownCaption(String fieldLabel, String raw) {
    switch (fieldLabel) {
      case 'Fuel Type':
        switch (raw) {
          case 'PETROL':
            return 'Petrol';
          case 'DIESEL':
            return 'Diesel';
          case 'CNG':
            return 'CNG';
          default:
            return raw;
        }
      case 'Availability':
        switch (raw) {
          case 'stock':
            return 'In Stock';
          case 'outstock':
            return 'Sold';
          default:
            return raw;
        }
      default:
        return raw;
    }
  }

  /// ListView + overlay dropdown menus often misbehave; sheet picker is reliable.
  Future<void> _openDropdownPicker({
    required String label,
    required List<String> options,
    required String current,
    required ValueChanged<String> onPick,
  }) async {
    if (!mounted || _busy) return;
    FocusScope.of(context).unfocus();
    String caption(String raw) => _dropdownCaption(label, raw);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF16345E);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.55;

    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (ctx) {
        final bottomSafe = MediaQuery.paddingOf(ctx).bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, bottomSafe + 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: isDark ? const Color(0xFF1A2235) : Colors.white,
              elevation: 16,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: fg,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                            color: isDark ? Colors.white54 : const Color(0xFF5B769E),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        shrinkWrap: false,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        children: [
                          for (final o in options)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Material(
                                color: o == current
                                    ? const Color(0x141D63ED)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(
                                    caption(o),
                                    style: TextStyle(
                                      fontWeight: o == current
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: fg,
                                      fontSize: 15,
                                    ),
                                  ),
                                  trailing: o == current
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF1D63ED),
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(ctx, o),
                                ),
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
        );
      },
    );

    if (chosen != null && mounted) {
      onPick(chosen);
    }
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    String caption(String raw) => _dropdownCaption(label, raw);

    const fieldStyle = TextStyle(
      color: _formInk,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    final decoration = _formInputDecoration(label).copyWith(
      contentPadding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 8,
        top: 16,
        bottom: 16,
      ),
      suffixIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _formAccent,
      ),
    );

    return FormField<String>(
      initialValue: value,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
      builder: (fieldState) {
        final effective = fieldState.value ?? value;
        final deco = decoration.copyWith(errorText: fieldState.errorText);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _busy
                ? null
                : () async {
                    await _openDropdownPicker(
                      label: label,
                      options: options,
                      current: effective,
                      onPick: (picked) {
                        fieldState.didChange(picked);
                        onChanged(picked);
                      },
                    );
                  },
            child: InputDecorator(
              decoration: deco,
              child: Text(
                caption(effective),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fieldStyle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 620;
        final half = twoCol
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        Widget fieldCell(Widget child) => SizedBox(width: half, child: child);

        final maxW = constraints.maxWidth;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE9FF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141D63ED),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: maxW,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0x161D63ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: _formAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingCar == null
                                  ? 'Add new car'
                                  : 'Edit car details',
                              style: const TextStyle(
                                color: _formInk,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vehicle info, specs & pricing, dates, photo — step through below.',
                              style: TextStyle(
                                color: _formLabel.withValues(alpha: 0.92),
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _formSectionHeader(
                  maxW,
                  'Vehicle',
                  Icons.app_registration_rounded,
                  first: true,
                ),
                fieldCell(
                  _textField(controller: _titleController, label: 'Title'),
                ),
                fieldCell(
                  _textField(
                    controller: _vehicleNumberController,
                    label: 'Vehicle number',
                    requiredField: false,
                    hintText: 'e.g. registration / plate no.',
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                fieldCell(
                  _textField(controller: _brandController, label: 'Brand'),
                ),
                fieldCell(
                  _textField(controller: _modelController, label: 'Model'),
                ),
                _formSectionHeader(maxW, 'Specs', Icons.tune_rounded),
                fieldCell(
                  _dropdown(
                    label: 'Fuel Type',
                    value: _fuelType,
                    options: const ['CNG', 'PETROL', 'DIESEL'],
                    onChanged: (v) =>
                        setState(() => _fuelType = v ?? _fuelType),
                  ),
                ),
                fieldCell(
                  _dropdown(
                    label: 'Ownership',
                    value: _ownership,
                    options: _ownershipItems,
                    onChanged: (v) =>
                        setState(() => _ownership = v ?? _ownership),
                  ),
                ),
                fieldCell(
                  _dropdown(
                    label: 'Availability',
                    value: _availability,
                    options: const ['stock', 'outstock'],
                    onChanged: (v) =>
                        setState(() => _availability = v ?? _availability),
                  ),
                ),
                fieldCell(
                  Container(
                    width: maxW,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _liveBidEnabled
                          ? const Color(0x14E53935)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _liveBidEnabled
                            ? const Color(0x55E53935)
                            : _formBorder,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _liveBidEnabled,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _liveBidEnabled = v),
                      activeColor: const Color(0xFFE53935),
                      title: const Text(
                        'Live bidding',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _formInk,
                        ),
                      ),
                      subtitle: Text(
                        _liveBidEnabled
                            ? 'Users can place bids on this car'
                            : 'Bidding closed until you turn this on',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _formLabel,
                        ),
                      ),
                      secondary: Icon(
                        _liveBidEnabled
                            ? Icons.gavel_rounded
                            : Icons.gavel_outlined,
                        color: _liveBidEnabled
                            ? const Color(0xFFE53935)
                            : _formLabel,
                      ),
                    ),
                  ),
                ),
                fieldCell(
                  _textField(
                    controller: _yearController,
                    label: 'Year',
                    keyboardType: TextInputType.number,
                  ),
                ),
                _formSectionHeader(maxW, 'Pricing', Icons.payments_rounded),
                fieldCell(
                  _textField(
                    controller: _buyPriceController,
                    label: 'Buy price (admin only)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                fieldCell(
                  _textField(
                    controller: _sellPriceController,
                    label: 'Sell price (public)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                _formSectionHeader(maxW, 'Dates', Icons.date_range_rounded),
                fieldCell(
                  _datePickerTile(
                    width: half,
                    icon: Icons.today_rounded,
                    text: 'Purchase · ${_fmtDate(_buyDate)}',
                    onTap: () => _pickDate(saleDate: false),
                  ),
                ),
                fieldCell(
                  _datePickerTile(
                    width: half,
                    icon: Icons.event_available_rounded,
                    text: _saleDate == null
                        ? 'Sale date (optional)'
                        : 'Sold · ${_fmtDate(_saleDate!)}',
                    onTap: () => _pickDate(saleDate: true),
                  ),
                ),
                _formSectionHeader(maxW, 'Notes', Icons.notes_rounded),
                SizedBox(
                  width: maxW,
                  child: _textField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 4,
                    hintText: 'Condition, features, service history…',
                  ),
                ),
                _formSectionHeader(maxW, 'Photo', Icons.photo_camera_rounded),
                SizedBox(
                  width: maxW,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0x241D63ED),
                      foregroundColor: _formAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0x553E9AFE)),
                      ),
                    ),
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(
                      _picked == null ? 'Choose cover photo' : 'Replace cover photo',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (_picked != null || _editingCar != null)
                  SizedBox(
                    width: maxW,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _formBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _picked != null
                            ? Image.file(
                                _picked!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _editingCar!.coverImageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                _formSectionHeader(maxW, 'Exterior photos', Icons.directions_car_filled_rounded),
                SizedBox(
                  width: maxW,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0x221D63ED),
                      foregroundColor: _formAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0x443E9AFE)),
                      ),
                    ),
                    onPressed: _busy ? null : _pickExterior,
                    icon: const Icon(Icons.collections_rounded),
                    label: const Text(
                      'Add exterior photos (multiple)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                _photoPreviewStrip(
                  maxW: maxW,
                  existingUrls: _existingExterior,
                  pickedFiles: _exteriorPicked,
                  onRemoveExisting: (url) => setState(() => _existingExterior.remove(url)),
                  onRemovePicked: (index) => setState(() => _exteriorPicked.removeAt(index)),
                ),
                _formSectionHeader(maxW, 'Interior photos', Icons.weekend_rounded),
                SizedBox(
                  width: maxW,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0x221D63ED),
                      foregroundColor: _formAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0x443E9AFE)),
                      ),
                    ),
                    onPressed: _busy ? null : _pickInterior,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text(
                      'Add interior photos (multiple)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                _photoPreviewStrip(
                  maxW: maxW,
                  existingUrls: _existingInterior,
                  pickedFiles: _interiorPicked,
                  onRemoveExisting: (url) => setState(() => _existingInterior.remove(url)),
                  onRemovePicked: (index) => setState(() => _interiorPicked.removeAt(index)),
                ),
                SizedBox(
                  width: maxW,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _formAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shadowColor: const Color(0x661D63ED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _busy ? null : _submitCar,
                    icon: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _editingCar == null
                                ? Icons.check_circle_outline_rounded
                                : Icons.save_rounded,
                          ),
                    label: Text(
                      _busy
                          ? 'Saving…'
                          : (_editingCar == null ? 'Save car' : 'Update car'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0E1320), Color(0xFF131C2E), Color(0xFF172339)]
              : const [Color(0xFFF7FAFF), Color(0xFFF2F7FF), Color(0xFFEAF2FF)],
        ),
      ),
      child: SafeArea(
        child: _showAddForm ? _buildFormScaffold() : _buildListScaffold(),
      ),
    );
  }

  Widget _buildFormScaffold() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _busy ? null : _closeForm,
                icon: const Icon(Icons.arrow_back_rounded),
                color: Color(0xFF16345E),
                tooltip: 'Back to inventory',
              ),
              Expanded(
                child: Text(
                  _editingCar == null ? 'Add car' : 'Edit car',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2442),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _buildForm(),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF5B769E),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListScaffold() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF162138), Color(0xFF1A2942)]
                    : const [Colors.white, Color(0xFFF4F8FF)],
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0A3A7A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFE6EEFF)
                              : const Color(0xFF0F2442),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_cars.length} vehicle${_cars.length == 1 ? '' : 's'} listed',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF9DB0CC)
                              : const Color(0xFF607BA5),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D63ED),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0x3A1D63ED),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _clearForm();
                            _showAddForm = true;
                            _statusMessage = null;
                          });
                        },
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Add car',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF1D63ED),
            onRefresh: _loadCars,
            child: _cars.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 48),
                      _EmptyInventory(
                        onAdd: () {
                          setState(() {
                            _clearForm();
                            _showAddForm = true;
                          });
                        },
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _cars.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final car = _cars[index];
                      return _InventoryDetailCard(
                        car: car,
                        busy: _busy,
                        onView: () => _openDetails(car),
                        onEdit: () => _startEdit(car),
                        onDelete: () => _deleteCar(car),
                        onToggleLiveBid: (enabled) => _toggleLiveBid(car, enabled),
                      );
                    },
                  ),
          ),
        ),
        if (_statusMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _statusMessage!,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF5B769E),
              ),
            ),
          ),
      ],
    );
  }

  void _openDetails(CarRecord car) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryCarDetailsPage(car: car),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF162138), Color(0xFF1A2942)]
              : [Colors.white, const Color(0xFFF4F8FF)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.garage_outlined, size: 56, color: const Color(0x991D63ED)),
          const SizedBox(height: 14),
          Text(
            'No cars yet',
            style: TextStyle(
              color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF173A64),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Add car to list your first vehicle with photo and details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF607BA5),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1D63ED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first car'),
          ),
        ],
      ),
    );
  }
}

class _InventoryDetailCard extends StatelessWidget {
  const _InventoryDetailCard({
    required this.car,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLiveBid,
  });

  final CarRecord car;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleLiveBid;

  static String _fmtPrice(double v) {
    if (v >= 100000) {
      return '₹ ${(v / 100000).toStringAsFixed(2)} L';
    }
    return '₹ ${v.toStringAsFixed(0)}';
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final inStock = car.availability == 'stock';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final imageWidth = width < 390 ? 108.0 : 124.0;
    final imageHeight = width < 390 ? 92.0 : 104.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(18),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF162138), Color(0xFF1A2942)]
                : [Colors.white, const Color(0xFFF4F8FF)],
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A0A3A7A),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Image.network(
                        car.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F6FF),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Color(0xFF1D63ED),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF1F6FF),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.directions_car_filled_rounded,
                            size: 34,
                            color: BrandColors.muted.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                car.title.isNotEmpty
                                    ? car.title
                                    : '${car.brand} ${car.model}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFE6EEFF)
                                      : const Color(0xFF0F2442),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: inStock
                                    ? const Color(0x1F34D399)
                                    : const Color(0x1FFB923C),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: inStock
                                      ? const Color(0x7734D399)
                                      : const Color(0x77FB923C),
                                ),
                              ),
                              child: Text(
                                inStock ? 'In Stock' : 'Sold',
                                style: TextStyle(
                                  color: inStock
                                      ? const Color(0xFF0B7A3E)
                                      : const Color(0xFFAD5B00),
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (inStock && car.liveBidEnabled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x1FE53935),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0x77E53935),
                                  ),
                                ),
                                child: const Text(
                                  'LIVE BID',
                                  style: TextStyle(
                                    color: Color(0xFFC62828),
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _inventoryCarSubtitle(car),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9DB0CC)
                                : BrandColors.muted.withValues(alpha: 0.94),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: _PriceLine(
                                label: 'Buy (admin)',
                                value: _fmtPrice(car.buyPrice),
                                muted: true,
                              ),
                            ),
                            Expanded(
                              child: _PriceLine(
                                label: 'Sell (public)',
                                value: _fmtPrice(car.sellPrice),
                                muted: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101B30) : const Color(0xFFF9FBFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Fuel', value: car.fuelType),
                    _DetailRow(
                      label: 'Vehicle number',
                      value: car.vehicleNumber.trim().isEmpty
                          ? '—'
                          : car.vehicleNumber,
                    ),
                    _DetailRow(label: 'Ownership', value: car.ownership),
                    _DetailRow(
                      label: 'Availability',
                      value: inStock ? 'In Stock' : 'Sold',
                    ),
                    _DetailRow(
                      label: 'Live bidding',
                      value: car.liveBidEnabled ? 'Open' : 'Closed',
                    ),
                    _DetailRow(label: 'Buy date', value: _fmtDate(car.buyDate)),
                    _DetailRow(
                      label: 'Sell date',
                      value: car.saleDate == null ? '-' : _fmtDate(car.saleDate!),
                    ),
                  ],
                ),
              ),
              if (car.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101B30) : const Color(0xFFF9FBFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D63ED),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        car.description,
                        style: TextStyle(
                          fontSize: 12.3,
                          height: 1.35,
                          color: BrandColors.muted.withValues(alpha: 0.96),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (inStock) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: car.liveBidEnabled
                        ? const Color(0x12E53935)
                        : (isDark ? const Color(0xFF101B30) : const Color(0xFFF9FBFF)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: car.liveBidEnabled
                          ? const Color(0x55E53935)
                          : (isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF)),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    value: car.liveBidEnabled,
                    onChanged: busy ? null : onToggleLiveBid,
                    activeColor: const Color(0xFFE53935),
                    title: Text(
                      car.liveBidEnabled ? 'Live bid running' : 'Start live bid',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                      ),
                    ),
                    subtitle: Text(
                      car.liveBidEnabled
                          ? 'Users can bid on this car now'
                          : 'Turn on to allow bidding',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9DB0CC) : BrandColors.muted,
                      ),
                    ),
                    secondary: Icon(
                      car.liveBidEnabled ? Icons.gavel_rounded : Icons.gavel_outlined,
                      color: car.liveBidEnabled
                          ? const Color(0xFFE53935)
                          : BrandColors.muted,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined, size: 17),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF355F9A),
                        side: const BorderSide(color: Color(0x55355F9A)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1D63ED),
                        side: const BorderSide(color: Color(0x661D63ED)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 17),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE07771),
                        side: const BorderSide(color: Color(0x44FF8A80)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF9DB0CC)
                    : BrandColors.muted.withValues(alpha: 0.92),
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF4F6D99),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF23456F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    required this.muted,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? const Color(0xFF9DB0CC)
                : BrandColors.muted.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: muted ? 13.5 : 15.5,
              fontWeight: FontWeight.w800,
              color: muted
                  ? (isDark ? const Color(0xFFB8C6DF) : const Color(0xFF5B769E))
                  : const Color(0xFF1D63ED),
            ),
          ),
        ),
      ],
    );
  }
}

class InventoryCarDetailsPage extends StatefulWidget {
  const InventoryCarDetailsPage({super.key, required this.car});

  final CarRecord car;

  @override
  State<InventoryCarDetailsPage> createState() => _InventoryCarDetailsPageState();
}

class _InventoryCarDetailsPageState extends State<InventoryCarDetailsPage> {
  final _expenseApi = ExpenseService();
  final _expenses = <ExpenseEntry>[];
  bool _loadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loadingExpenses = true);
    try {
      final all = await _expenseApi.fetchExpenses(limit: 500, carId: widget.car.id);
      if (!mounted) return;
      setState(() {
        _expenses
          ..clear()
          ..addAll(all);
        _loadingExpenses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingExpenses = false);
    }
  }

  Future<void> _openAddExpenseSheet() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add car expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2442),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: _fieldDecoration('Title (fuel, service, challan...)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('Price / amount'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0) {
                    AppToast.error(ctx, 'Enter valid title and price');
                    return;
                  }
                  try {
                    final entry = await _expenseApi.createExpense(
                      title: title,
                      amount: amount,
                      carId: widget.car.id,
                      carLabel: widget.car.title.isNotEmpty
                          ? widget.car.title
                          : '${widget.car.brand} ${widget.car.model}',
                    );
                    if (!mounted) return;
                    setState(() => _expenses.insert(0, entry));
                    if (ctx.mounted) Navigator.pop(ctx);
                    AppToast.success(context, 'Expense added successfully');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    AppToast.error(ctx, e.toString());
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D63ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Add expense',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditExpenseSheet(ExpenseEntry entry) async {
    final titleCtrl = TextEditingController(text: entry.title);
    final amountCtrl = TextEditingController(text: entry.amount.toStringAsFixed(0));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit car expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2442),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: _fieldDecoration('Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('Price / amount'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0) {
                    AppToast.error(ctx, 'Enter valid title and price');
                    return;
                  }
                  try {
                    final updated = await _expenseApi.updateExpense(
                      id: entry.id,
                      title: title,
                      amount: amount,
                    );
                    if (!mounted) return;
                    final idx = _expenses.indexWhere((e) => e.id == entry.id);
                    if (idx != -1) {
                      setState(() => _expenses[idx] = updated);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    AppToast.success(context, 'Expense updated successfully');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    AppToast.error(ctx, e.toString());
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D63ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Update expense',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteExpense(ExpenseEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense'),
        content: Text('Delete "${entry.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _expenseApi.deleteExpense(entry.id);
      if (!mounted) return;
      setState(() => _expenses.removeWhere((e) => e.id == entry.id));
      AppToast.success(context, 'Expense deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A93B7)),
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E5FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E5FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D63ED)),
      ),
    );
  }

  String _fmtPrice(double v) {
    if (v >= 100000) {
      return '₹ ${(v / 100000).toStringAsFixed(2)} L';
    }
    return '₹ ${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  double get _totalExpense => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  void _showExpenseBreakdown() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Expense breakdown'),
        content: SizedBox(
          width: 360,
          child: _expenses.isEmpty
              ? const Text('No expense history yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _expenses.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = _expenses[i];
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF23456F),
                            ),
                          ),
                        ),
                        Text(
                          _fmtPrice(e.amount),
                          style: const TextStyle(
                            color: Color(0xFF1D63ED),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final inStock = car.availability == 'stock';
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: const Text('Car details'),
        backgroundColor: const Color(0xFFFDFEFF),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                car.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF1F6FF),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 46,
                    color: Color(0x885B769E),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE9FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        car.title.isNotEmpty
                            ? car.title
                            : '${car.brand} ${car.model}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F2442),
                          height: 1.15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: inStock
                            ? const Color(0x1F34D399)
                            : const Color(0x1FFB923C),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: inStock
                              ? const Color(0x7734D399)
                              : const Color(0x77FB923C),
                        ),
                      ),
                      child: Text(
                        inStock ? 'In Stock' : 'Sold',
                        style: TextStyle(
                          color: inStock
                              ? const Color(0xFF0B7A3E)
                              : const Color(0xFFAD5B00),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _inventoryCarSubtitle(car),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5B769E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE9FF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PriceLine(
                    label: 'Buy (admin)',
                    value: _fmtPrice(car.buyPrice),
                    muted: true,
                  ),
                ),
                Expanded(
                  child: _PriceLine(
                    label: 'Sell (public)',
                    value: _fmtPrice(car.sellPrice),
                    muted: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE9FF)),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Fuel type', value: car.fuelType),
                _DetailRow(
                  label: 'Vehicle number',
                  value: car.vehicleNumber.trim().isEmpty
                      ? '—'
                      : car.vehicleNumber,
                ),
                _DetailRow(label: 'Ownership', value: car.ownership),
                _DetailRow(label: 'Availability', value: car.availability),
                _DetailRow(label: 'Buy date', value: _fmtDate(car.buyDate)),
                _DetailRow(
                  label: 'Sell date',
                  value: car.saleDate == null ? '-' : _fmtDate(car.saleDate!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE9FF)),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _showExpenseBreakdown,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDCE9FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFF1D63ED),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total car expenses',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF23456F),
                            ),
                          ),
                        ),
                        Text(
                          _fmtPrice(_totalExpense),
                          style: const TextStyle(
                            color: Color(0xFF1D63ED),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openAddExpenseSheet,
                    icon: const Icon(Icons.add_card_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D63ED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: const Text(
                      'Add car expense',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE9FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense history',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D63ED),
                  ),
                ),
                const SizedBox(height: 8),
                if (_loadingExpenses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'No car expense history yet.',
                      style: TextStyle(color: Color(0xFF5B769E)),
                    ),
                  )
                else
                  Column(
                    children: _expenses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final e = entry.value;
                      final isLast = index == _expenses.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${e.title}\n${_fmtDate(e.createdAt)}',
                                      style: const TextStyle(
                                        color: Color(0xFF23456F),
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _fmtPrice(e.amount),
                                    style: const TextStyle(
                                      color: Color(0xFF1D63ED),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => _openEditExpenseSheet(e),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: Color(0xFF355F9A),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteExpense(e),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFE07771),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                height: 10,
                                thickness: 1,
                                color: Color(0xFFDCE9FF),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          if (car.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE9FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D63ED),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    car.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Color(0xFF334F74),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
