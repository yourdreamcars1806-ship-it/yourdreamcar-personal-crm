import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/listing_request_service.dart';

class SellRequestPage extends StatefulWidget {
  const SellRequestPage({super.key, this.onSubmitted});

  final VoidCallback? onSubmitted;

  @override
  State<SellRequestPage> createState() => _SellRequestPageState();
}

class _SellRequestPageState extends State<SellRequestPage> {
  final _api = ListingRequestService();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _km = TextEditingController();
  final _sellPrice = TextEditingController();
  final _city = TextEditingController(text: 'Pune');
  final _phone = TextEditingController();
  final _desc = TextEditingController();
  String _fuel = 'PETROL';
  String _ownership = '1st owner';
  File? _image;
  bool _loading = false;

  static const _ownerships = [
    '1st owner',
    '2nd owner',
    '3rd owner',
    '4th owner',
    '5th owner',
    'multiple owner',
  ];

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _km.dispose();
    _sellPrice.dispose();
    _city.dispose();
    _phone.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (_image == null) {
      AppToast.error(context, 'Add a car photo');
      return;
    }
    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      AppToast.error(context, 'Enter brand and model');
      return;
    }
    if (_phone.text.trim().length < 8) {
      AppToast.error(context, 'Enter a valid phone number');
      return;
    }
    final sell = double.tryParse(_sellPrice.text.trim()) ?? 0;
    if (sell <= 0) {
      AppToast.error(context, 'Enter the sell price');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.create(
        fields: {
          'brand': _brand.text.trim(),
          'model': _model.text.trim(),
          'year': _year.text.trim().isEmpty ? '2020' : _year.text.trim(),
          'fuelType': _fuel,
          'ownership': _ownership,
          'kmDriven': _km.text.trim().isEmpty ? '0' : _km.text.trim(),
          'sellPrice': _sellPrice.text.trim(),
          'expectedPrice': _sellPrice.text.trim(),
          'city': _city.text.trim(),
          'phone': _phone.text.trim(),
          'description': _desc.text.trim(),
        },
        imageFile: _image,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        'Request sent. Admin will review, edit if needed, then publish.',
      );
      _brand.clear();
      _model.clear();
      _year.clear();
      _km.clear();
      _sellPrice.clear();
      _phone.clear();
      _desc.clear();
      setState(() => _image = null);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          title: const Text(
            'Car listing request',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const Text(
              'Fill details and send a request. It will not go live until admin accepts, edits if needed, and publishes.',
              style: TextStyle(color: MarketColors.muted, height: 1.35),
            ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EAF3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _image == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: MarketColors.primary),
                      SizedBox(height: 8),
                      Text(
                        'Add car photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MarketColors.muted,
                        ),
                      ),
                    ],
                  )
                : Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
          ),
        ),
        const SizedBox(height: 14),
        _field(_brand, 'Brand (Hyundai, Tata...)'),
        const SizedBox(height: 10),
        _field(_model, 'Model (Creta, Nexon...)'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _field(_year, 'Year', keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_km, 'KM driven', keyboard: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 10),
        _field(
          _sellPrice,
          'Sell price (₹) — shown to buyers after publish',
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _dec('Fuel type'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _fuel,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'PETROL', child: Text('Petrol')),
                DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                DropdownMenuItem(value: 'CNG', child: Text('CNG')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _fuel = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _dec('Ownership'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _ownership,
              isExpanded: true,
              items: [
                for (final o in _ownerships)
                  DropdownMenuItem(value: o, child: Text(o)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _ownership = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _field(_city, 'City'),
        const SizedBox(height: 10),
        _field(_phone, 'Phone', keyboard: TextInputType.phone),
        const SizedBox(height: 10),
        _field(_desc, 'Description (optional)', maxLines: 3),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MarketColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text(
                    'Send request to admin',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4EAF3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4EAF3)),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _dec(hint),
    );
  }
}
