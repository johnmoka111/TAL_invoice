// models/invoice_model.dart
// Modèle représentant une facture complète avec ses articles.
// Stocké dans la table SQLite `invoices`, avec les items dans `invoice_items`.

import 'invoice_item_model.dart';

/// Statuts possibles d'une facture
enum InvoiceStatus {
  draft,   // Brouillon
  sent,    // Envoyée
  paid,    // Payée
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Brouillon';
      case InvoiceStatus.sent:
        return 'En attente';
      case InvoiceStatus.paid:
        return 'Payée';
    }
  }

  String get value {
    return name; // 'draft', 'sent', 'paid'
  }

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvoiceStatus.draft,
    );
  }
}

class InvoiceModel {
  final int? id;
  final String invoiceNumber; // ex: "FAC-2024-001"
  final int clientId;
  final String? clientName; // Jointure — non stocké directement
  final List<InvoiceItemModel> items;
  final double taxRate; // ex: 0.16 pour 16%
  final InvoiceStatus status;
  final String? notes;
  final DateTime createdAt;

  const InvoiceModel({
    this.id,
    required this.invoiceNumber,
    required this.clientId,
    this.clientName,
    required this.items,
    this.taxRate = 0.0,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  /// Sous-total avant taxes
  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  /// Montant de la taxe
  double get taxAmount => subtotal * taxRate;

  /// Total final TTC
  double get total => subtotal + taxAmount;

  factory InvoiceModel.fromMap(
    Map<String, dynamic> map, {
    List<InvoiceItemModel> items = const [],
    String? clientName,
  }) {
    return InvoiceModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      clientId: map['client_id'] as int,
      clientName: clientName,
      items: items,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatusExtension.fromString(
          map['status'] as String? ?? 'draft'),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'tax_rate': taxRate,
      'status': status.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InvoiceModel copyWith({
    int? id,
    String? invoiceNumber,
    int? clientId,
    String? clientName,
    List<InvoiceItemModel>? items,
    double? taxRate,
    InvoiceStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'InvoiceModel(id: $id, number: $invoiceNumber, total: $total, status: ${status.label})';
}
