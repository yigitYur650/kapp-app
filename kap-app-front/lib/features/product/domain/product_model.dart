// lib/features/product/domain/product_model.dart

class Product {
  final String id;
  final String name;
  final int quantity;
  final String? unit;
  final String? category;
  final bool checked;

  const Product({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit,
    this.category,
    this.checked = false,
  });

  Product copyWith({
    String? id,
    String? name,
    int? quantity,
    String? unit,
    String? category,
    bool? checked,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      checked: checked ?? this.checked,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit'] as String?,
      category: map['category'] as String?,
      checked: map['checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      'checked': checked,
    };
  }
}
