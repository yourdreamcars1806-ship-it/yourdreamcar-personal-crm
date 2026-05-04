import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/car_service.dart';
import '../data/order_store.dart';
import '../domain/order_entry.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  final _carApi = CarService();
  final _store = OrderStore();
  final _orders = <OrderEntry>[];
  List<CarRecord> _cars = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _store.load(),
        _carApi.listCars(limit: 250, omitDescription: true),
      ]);
      if (!mounted) return;
      final orders = results[0] as List<OrderEntry>;
      final cars = (results[1] as CarListResponse).cars;
      setState(() {
        _orders
          ..clear()
          ..addAll(orders);
        _cars = cars;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> openAddOrderDialog() async {
    await _openOrderSheet();
  }

  Future<void> _openEditOrderDialog(OrderEntry entry) async {
    await _openOrderSheet(editing: entry);
  }

  Future<void> _openOrderSheet({OrderEntry? editing}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_cars.isEmpty) {
      await _loadData();
    }
    if (!mounted) return;
    if (_cars.isEmpty) {
      AppToast.info(context, 'Please add cars first in Inventory');
      return;
    }

    String? selectedCarId = editing?.carId ?? _cars.first.id;
    DateTime orderDate = editing?.orderDate ?? DateTime.now();
    DateTime deliveryDate =
        editing?.deliveryDate ?? DateTime.now().add(const Duration(days: 3));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF101828) : const Color(0xFFF7FAFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickDate({required bool delivery}) async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: delivery ? deliveryDate : orderDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setModalState(() {
                if (delivery) {
                  deliveryDate = picked;
                } else {
                  orderDate = picked;
                  if (deliveryDate.isBefore(orderDate)) {
                    deliveryDate = orderDate;
                  }
                }
              });
            }

            Future<void> pickCar() async {
              final picked = await showModalBottomSheet<String>(
                context: ctx,
                backgroundColor: isDark
                    ? const Color(0xFF162138)
                    : Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (sheetCtx) {
                  return SafeArea(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                      itemCount: _cars.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final car = _cars[index];
                        final id = car.id;
                        final title = car.title.isNotEmpty
                            ? car.title
                            : '${car.brand} ${car.model}';
                        final selected = id == selectedCarId;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: selected
                              ? const Color(0x1F1D63ED)
                              : (isDark
                                    ? const Color(0xFF101B30)
                                    : const Color(0xFFF7FAFF)),
                          leading: const Icon(
                            Icons.directions_car_rounded,
                            color: Color(0xFF1D63ED),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFE6EEFF)
                                  : const Color(0xFF16345E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF1D63ED),
                                )
                              : null,
                          onTap: () => Navigator.pop(sheetCtx, id),
                        );
                      },
                    ),
                  );
                },
              );
              if (picked == null) return;
              setModalState(() => selectedCarId = picked);
            }
            final selectedCar = _cars.firstWhere(
              (car) => car.id == selectedCarId,
              orElse: () => _cars.first,
            );
            final selectedCarLabel = selectedCar.title.trim().isNotEmpty
                ? selectedCar.title
                : '${selectedCar.brand} ${selectedCar.model}';

            return AnimatedPadding(
              duration: const Duration(milliseconds: 140),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162138) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120A3A7A),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        editing == null ? 'Add order' : 'Edit order',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select car and schedule dates',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF5B769E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: pickCar,
                        child: InputDecorator(
                          decoration: _orderFieldDecoration(
                            label: 'Select car',
                            icon: Icons.directions_car_rounded,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedCarLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFE6EEFF)
                                        : const Color(0xFF16345E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF1D63ED),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, c) {
                          final stacked = c.maxWidth < 430;
                          if (stacked) {
                            return Column(
                              children: [
                                _DateSelectTile(
                                  title: 'Order date',
                                  value: _fmtDate(orderDate),
                                  icon: Icons.event_available_rounded,
                                  onTap: () => pickDate(delivery: false),
                                ),
                                const SizedBox(height: 8),
                                _DateSelectTile(
                                  title: 'Delivery date',
                                  value: _fmtDate(deliveryDate),
                                  icon: Icons.local_shipping_outlined,
                                  onTap: () => pickDate(delivery: true),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _DateSelectTile(
                                  title: 'Order date',
                                  value: _fmtDate(orderDate),
                                  icon: Icons.event_available_rounded,
                                  onTap: () => pickDate(delivery: false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DateSelectTile(
                                  title: 'Delivery date',
                                  value: _fmtDate(deliveryDate),
                                  icon: Icons.local_shipping_outlined,
                                  onTap: () => pickDate(delivery: true),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () async {
                          final car = _cars.firstWhere(
                            (c) => c.id == selectedCarId,
                            orElse: () => _cars.first,
                          );
                          late final OrderEntry item;
                          if (editing == null) {
                            item = OrderEntry(
                              id: '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}',
                              carId: car.id,
                              carLabel: car.title.isNotEmpty
                                  ? car.title
                                  : '${car.brand} ${car.model}',
                              orderDate: orderDate,
                              deliveryDate: deliveryDate,
                              status: 'pending',
                              createdAt: DateTime.now(),
                            );
                          } else {
                            item = editing.copyWith(
                              carId: car.id,
                              carLabel: car.title.isNotEmpty
                                  ? car.title
                                  : '${car.brand} ${car.model}',
                              orderDate: orderDate,
                              deliveryDate: deliveryDate,
                            );
                          }

                          try {
                            setState(() {
                              if (editing == null) {
                                _orders.insert(0, item);
                              } else {
                                final idx = _orders.indexWhere((e) => e.id == editing.id);
                                if (idx != -1) _orders[idx] = item;
                              }
                            });
                            await _store.save(_orders);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            AppToast.success(
                              context,
                              editing == null
                                  ? 'Order added successfully'
                                  : 'Order updated successfully',
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            AppToast.error(ctx, e.toString());
                          }
                        },
                        icon: Icon(editing == null ? Icons.add_rounded : Icons.check_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D63ED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(editing == null ? 'Save order' : 'Update order'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markDelivered(OrderEntry entry) async {
    final idx = _orders.indexWhere((e) => e.id == entry.id);
    if (idx == -1) return;
    setState(() {
      _orders[idx] = entry.copyWith(status: 'delivered');
    });
    await _store.save(_orders);
  }

  Future<void> _deleteOrder(OrderEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete order?'),
        content: Text('Remove order for "${entry.carLabel}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE07771),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      setState(() => _orders.removeWhere((e) => e.id == entry.id));
      await _store.save(_orders);
      if (!mounted) return;
      AppToast.success(context, 'Order deleted successfully');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  InputDecoration _orderFieldDecoration({
    required String label,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF6A86AF),
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1D63ED)),
      filled: true,
      fillColor: isDark ? const Color(0xFF101B30) : const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2F426A) : const Color(0xFFD7E5FF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2F426A) : const Color(0xFFD7E5FF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1D63ED), width: 1.4),
      ),
    );
  }

  List<OrderEntry> get _visibleOrders {
    if (_filter == 'Pending') {
      return _orders.where((e) => !e.isDelivered).toList();
    }
    if (_filter == 'Delivered') {
      return _orders.where((e) => e.isDelivered).toList();
    }
    return _orders;
  }

  int get _deliveredCount => _orders.where((e) => e.isDelivered).length;

  String? _carImageById(String carId) {
    for (final car in _cars) {
      if (car.id == carId && car.imageUrl.isNotEmpty) return car.imageUrl;
    }
    return null;
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF1D63ED),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE6EEFF)
                                : const Color(0xFF0F2442),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: openAddOrderDialog,
                        icon: const Icon(Icons.add_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0x1F1D63ED),
                          foregroundColor: const Color(0xFF1D63ED),
                        ),
                        label: const Text(
                          'Add',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _OrdersSummaryGrid(
                    totalCars: _cars.length,
                    orderCars: _orders.length,
                    deliveredCars: _deliveredCount,
                    onAddOrder: openAddOrderDialog,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        active: _filter == 'All',
                        onTap: () => setState(() => _filter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        active: _filter == 'Pending',
                        onTap: () => setState(() => _filter = 'Pending'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Delivered',
                        active: _filter == 'Delivered',
                        onTap: () => setState(() => _filter = 'Delivered'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_visibleOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _orders.isEmpty
                          ? 'No orders yet.\nTap Add to create order.'
                          : 'No $_filter orders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9DB0CC)
                            : BrandColors.muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  sliver: SliverList.separated(
                    itemCount: _visibleOrders.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = _visibleOrders[i];
                      final imageUrl = _carImageById(e.carId);
                      return Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162138) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2F426A)
                                : const Color(0xFFDCE9FF),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: e.isDelivered
                                    ? const Color(0x1F22C55E)
                                    : const Color(0x1F1D63ED),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Icon(
                                              e.isDelivered
                                                  ? Icons.task_alt_rounded
                                                  : Icons.timelapse_rounded,
                                              color: e.isDelivered
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF1D63ED),
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      e.isDelivered
                                          ? Icons.task_alt_rounded
                                          : Icons.timelapse_rounded,
                                      color: e.isDelivered
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF1D63ED),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.carLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFE6EEFF)
                                          : const Color(0xFF16345E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Order: ${_fmtDate(e.orderDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF9DB0CC)
                                          : BrandColors.muted.withValues(alpha: 0.95),
                                    ),
                                  ),
                                  Text(
                                    'Delivery: ${_fmtDate(e.deliveryDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF9DB0CC)
                                          : BrandColors.muted.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () => _openEditOrderDialog(e),
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: isDark
                                            ? const Color(0xFF9DB0CC)
                                            : const Color(0xFF355F9A),
                                        size: 18,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteOrder(e),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFE07771),
                                        size: 18,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                e.isDelivered
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x1F22C55E),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'Delivered',
                                          style: TextStyle(
                                            color: Color(0xFF15803D),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : OutlinedButton(
                                        onPressed: () => _markDelivered(e),
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('Deliver'),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 82)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSelectTile extends StatelessWidget {
  const _DateSelectTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101B30) : const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2F426A) : const Color(0xFFD7E5FF),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D63ED), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF6A86AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF16345E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF6A86AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? const Color(0x1F1D63ED)
              : (isDark ? const Color(0xFF162138) : Colors.white),
          border: Border.all(
            color: active
                ? const Color(0xFF1D63ED)
                : (isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? const Color(0xFF1D63ED)
                : (isDark ? const Color(0xFF9DB0CC) : const Color(0xFF5B769E)),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _OrdersSummaryGrid extends StatelessWidget {
  const _OrdersSummaryGrid({
    required this.totalCars,
    required this.orderCars,
    required this.deliveredCars,
    required this.onAddOrder,
  });

  final int totalCars;
  final int orderCars;
  final int deliveredCars;
  final VoidCallback onAddOrder;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        title: 'Total cars',
        value: '$totalCars',
        icon: Icons.directions_car_rounded,
        accent: const Color(0xFF22D3EE),
      ),
      _SummaryCardData(
        title: 'Order cars',
        value: '$orderCars',
        icon: Icons.shopping_bag_outlined,
        accent: const Color(0xFF1D63ED),
      ),
      _SummaryCardData(
        title: 'Delivered',
        value: '$deliveredCars',
        icon: Icons.task_alt_rounded,
        accent: const Color(0xFF22C55E),
      ),
      _SummaryCardData(
        title: 'Add order',
        value: 'Create',
        icon: Icons.add_circle_rounded,
        accent: const Color(0xFF7C3AED),
        onTap: onAddOrder,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: _SummaryCard(data: card)))
              .toList(),
        );
      },
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162138) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? data.accent.withValues(alpha: 0.5)
                  : data.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, color: data.accent, size: 22),
              const SizedBox(height: 7),
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFFE6EEFF) : const Color(0xFF16345E),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9DB0CC) : const Color(0xFF5B769E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
