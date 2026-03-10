// models/company_model.dart
// Modèle représentant le profil de l'entreprise de l'utilisateur.
// Stocké dans la table SQLite `companies`.

class CompanyModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String currency; // ex: USD, CDF
  final String? logoPath;        // Chemin local vers le logo sur l'appareil
  final String? rccm;
  final String? idNational;
  final String? registrationCertificate;
  final DateTime createdAt;

  // ── Nouveaux champs : personnalisation de facture ──────────────────────────
  final String? signaturePath; // Chemin vers l'image PNG de signature
  final String? managerName;   // Nom du responsable
  final String? managerRole;   // Poste du responsable (Directeur, CEO, etc.)
  final String? defaultNotes;  // Notes et conditions par défaut (ex: RIB, délais)

  const CompanyModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.currency,
    this.logoPath,
    this.rccm,
    this.idNational,
    this.registrationCertificate,
    required this.createdAt,
    this.signaturePath,
    this.managerName,
    this.managerRole,
    this.defaultNotes,
  });

  /// Convertit un Map (ligne SQLite) en CompanyModel
  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      currency: map['currency'] as String,
      logoPath: map['logo_path'] as String?,
      rccm: map['rccm'] as String?,
      idNational: map['id_national'] as String?,
      registrationCertificate: map['registration_certificate'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      signaturePath: map['signature_path'] as String?,
      managerName: map['manager_name'] as String?,
      managerRole: map['manager_role'] as String?,
      defaultNotes: map['default_notes'] as String?,
    );
  }

  /// Convertit en Map pour insertion/mise à jour SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'currency': currency,
      'logo_path': logoPath,
      'rccm': rccm,
      'id_national': idNational,
      'registration_certificate': registrationCertificate,
      'created_at': createdAt.toIso8601String(),
      'signature_path': signaturePath,
      'manager_name': managerName,
      'manager_role': managerRole,
      'default_notes': defaultNotes,
    };
  }

  /// Crée une copie avec des champs modifiés
  CompanyModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? currency,
    String? logoPath,
    String? rccm,
    String? idNational,
    String? registrationCertificate,
    DateTime? createdAt,
    String? signaturePath,
    String? managerName,
    String? managerRole,
    String? defaultNotes,
    // Flags pour forcer null (ex: supprimer logo/signature)
    bool clearLogoPath = false,
    bool clearSignaturePath = false,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      rccm: rccm ?? this.rccm,
      idNational: idNational ?? this.idNational,
      registrationCertificate: registrationCertificate ?? this.registrationCertificate,
      createdAt: createdAt ?? this.createdAt,
      signaturePath: clearSignaturePath ? null : (signaturePath ?? this.signaturePath),
      managerName: managerName ?? this.managerName,
      managerRole: managerRole ?? this.managerRole,
      defaultNotes: defaultNotes ?? this.defaultNotes,
    );
  }

  @override
  String toString() =>
      'CompanyModel(id: $id, name: $name, currency: $currency)';
}

