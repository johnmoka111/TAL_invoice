// models/client_model.dart
// Modèle représentant un client de l'entrepreneur.
// Stocké dans la table SQLite `clients`.

class ClientModel {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  const ClientModel({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.createdAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ClientModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ClientModel(id: $id, name: $name)';
}
