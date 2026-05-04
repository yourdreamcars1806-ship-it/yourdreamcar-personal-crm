class OrderEntry {
  const OrderEntry({
    required this.id,
    required this.carId,
    required this.carLabel,
    required this.orderDate,
    required this.deliveryDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String carId;
  final String carLabel;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String status; // pending | delivered
  final DateTime createdAt;

  bool get isDelivered => status == 'delivered';

  OrderEntry copyWith({
    String? id,
    String? carId,
    String? carLabel,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? status,
    DateTime? createdAt,
  }) {
    return OrderEntry(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      carLabel: carLabel ?? this.carLabel,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'carLabel': carLabel,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderEntry.fromMap(Map<String, dynamic> map) {
    return OrderEntry(
      id: map['id']?.toString() ?? '',
      carId: map['carId']?.toString() ?? '',
      carLabel: map['carLabel']?.toString() ?? '',
      orderDate:
          DateTime.tryParse(map['orderDate']?.toString() ?? '') ??
          DateTime.now(),
      deliveryDate:
          DateTime.tryParse(map['deliveryDate']?.toString() ?? '') ??
          DateTime.now(),
      status: map['status']?.toString() == 'delivered' ? 'delivered' : 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
