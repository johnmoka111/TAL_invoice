// models/invoice_item_model.dart
// Représente une ligne d'article dans une facture.
// Stocké dans la table SQLite `invoice_items`.

class InvoiceItemModel {
  final int? id;
  final int? invoiceId; // Clé étrangère → invoices.id
  final String description;
  final double quantity;
  final double unitPrice;
  final String? currency; // USD ou FC

  const InvoiceItemModel({
    this.id,
    this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.currency,
  });

  /// Total calculé dynamiquement (non stocké)
  double get total => quantity * unitPrice;

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      description: map['description'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      currency: map['currency'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'currency': currency,
    };
  }

  InvoiceItemModel copyWith({
    int? id,
    int? invoiceId,
    String? description,
    double? quantity,
    double? unitPrice,
    String? currency,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() =>
      'InvoiceItemModel(description: $description, qty: $quantity, price: $unitPrice)';
}
