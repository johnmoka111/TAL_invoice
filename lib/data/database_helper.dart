import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/company_model.dart';
import '../models/client_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';

class DatabaseHelper {
  // ── Constantes ──────────────────────────────────────────────────────────────
  static const String _dbName = 'tal_invoice.db';
  static const int _dbVersion = 5;

  // Tables
  static const String tableCompanies = 'companies';
  static const String tableClients = 'clients';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceItems = 'invoice_items';

  // ── Singleton pattern ────────────────────────────────────────────────────────
  // Empêche les instantiations multiples de la DB qui créeraient des conflits.
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// Retourne l'instance de la DB, la crée si nécessaire.
  Future<Database> get database async {
    if (kIsWeb) {
      // Sur web, SQLite (sqflite) ne fonctionne pas ainsi.
      // On retourne une erreur qui sera captée par les BLoCs.
      throw UnsupportedError("SQLite (sqflite) n'est pas supporté sur Chrome/Web.");
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  // ── Initialisation ───────────────────────────────────────────────────────────
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Active les clés étrangères SQLite (désactivées par défaut)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Crée toutes les tables lors de la première installation.
  Future<void> _onCreate(Database db, int version) async {
    // ── Table entreprise (une seule ligne attendue) ──────────────────────────
    await db.execute('''
      CREATE TABLE $tableCompanies (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        email       TEXT    NOT NULL,
        phone       TEXT    NOT NULL,
        address     TEXT    NOT NULL,
        currency    TEXT    NOT NULL DEFAULT 'USD',
        logo_path   TEXT,
        rccm        TEXT,
        id_national TEXT,
        registration_certificate TEXT,
        created_at  TEXT    NOT NULL,
        signature_path TEXT,
        manager_name   TEXT,
        manager_role   TEXT,
        default_notes  TEXT
      )
    ''');

    // ── Table clients ────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableClients (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        email       TEXT,
        phone       TEXT,
        address     TEXT,
        created_at  TEXT    NOT NULL
      )
    ''');

    // ── Table factures ───────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableInvoices (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number  TEXT    NOT NULL UNIQUE,
        client_id       INTEGER NOT NULL,
        tax_rate        REAL    NOT NULL DEFAULT 0.0,
        status          TEXT    NOT NULL DEFAULT 'draft',
        notes           TEXT,
        created_at      TEXT    NOT NULL,
        FOREIGN KEY (client_id) REFERENCES $tableClients(id) ON DELETE RESTRICT
      )
    ''');

    // ── Table articles de facture ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableInvoiceItems (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id  INTEGER NOT NULL,
        description TEXT    NOT NULL,
        quantity    REAL    NOT NULL DEFAULT 1.0,
        unit_price  REAL    NOT NULL DEFAULT 0.0,
        currency    TEXT    NOT NULL DEFAULT 'USD',
        FOREIGN KEY (invoice_id) REFERENCES $tableInvoices(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Gère les migrations futures (ajout de colonnes, nouvelles tables…).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN rccm TEXT');
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN id_national TEXT');
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN registration_certificate TEXT');
    }
    if (oldVersion < 3) {
      // v3 : personnalisation de facture (signature, responsable)
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN signature_path TEXT');
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN manager_name TEXT');
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN manager_role TEXT');
    }
    if (oldVersion < 4) {
      // v4 : Notes et conditions par défaut
      await db.execute('ALTER TABLE $tableCompanies ADD COLUMN default_notes TEXT');
    }
    if (oldVersion < 5) {
      // v5 : Devise par article
      await db.execute('ALTER TABLE $tableInvoiceItems ADD COLUMN currency TEXT NOT NULL DEFAULT "USD"');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // CRUD — CompanyModel
  // ══════════════════════════════════════════════════════════════════════════════

  /// Sauvegarde ou met à jour le profil entreprise.
  /// On utilise INSERT OR REPLACE car une seule entreprise est attendue.
  Future<int> saveCompany(CompanyModel company) async {
    final db = await database;
    return await db.insert(
      tableCompanies,
      company.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère le premier profil entreprise trouvé (null si aucun).
  Future<CompanyModel?> getCompany() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCompanies,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CompanyModel.fromMap(maps.first);
  }

  /// Met à jour le profil entreprise existant.
  Future<int> updateCompany(CompanyModel company) async {
    final db = await database;
    return await db.update(
      tableCompanies,
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // CRUD — ClientModel
  // ══════════════════════════════════════════════════════════════════════════════

  /// Insère un nouveau client et retourne son id généré.
  Future<int> insertClient(ClientModel client) async {
    final db = await database;
    return await db.insert(tableClients, client.toMap());
  }

  /// Retourne tous les clients, triés par nom.
  Future<List<ClientModel>> getAllClients() async {
    final db = await database;
    final maps = await db.query(
      tableClients,
      orderBy: 'name ASC',
    );
    return maps.map((m) => ClientModel.fromMap(m)).toList();
  }

  /// Recherche des clients par nom (LIKE insensible à la casse).
  Future<List<ClientModel>> searchClients(String query) async {
    final db = await database;
    final maps = await db.query(
      tableClients,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => ClientModel.fromMap(m)).toList();
  }

  /// Récupère un client par son id.
  Future<ClientModel?> getClientById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableClients,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ClientModel.fromMap(maps.first);
  }

  /// Met à jour les informations d'un client existant.
  Future<int> updateClient(ClientModel client) async {
    final db = await database;
    return await db.update(
      tableClients,
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  /// Supprime un client. Échoue si des factures lui sont associées (FK RESTRICT).
  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete(
      tableClients,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // CRUD — InvoiceModel (avec ses items via transaction atomique)
  // ══════════════════════════════════════════════════════════════════════════════

  /// Insère une facture et tous ses articles dans une transaction atomique.
  /// Si l'insertion d'un article échoue, toute la transaction est annulée.
  Future<int> insertInvoice(InvoiceModel invoice) async {
    final db = await database;
    // Transaction garantit l'atomicité: tout ou rien
    return await db.transaction((txn) async {
      // 1. Insérer l'en-tête de facture
      final invoiceId = await txn.insert(tableInvoices, invoice.toMap());

      // 2. Insérer chaque article avec l'id de facture obtenu
      for (final item in invoice.items) {
        await txn.insert(
          tableInvoiceItems,
          item.copyWith(invoiceId: invoiceId).toMap(),
        );
      }
      return invoiceId;
    });
  }

  /// Retourne toutes les factures avec leur nom de client (jointure).
  Future<List<InvoiceModel>> getAllInvoices() async {
    final db = await database;

    // Jointure LEFT JOIN pour récupérer le nom du client
    final invoiceMaps = await db.rawQuery('''
      SELECT i.*, c.name AS client_name
      FROM $tableInvoices i
      LEFT JOIN $tableClients c ON i.client_id = c.id
      ORDER BY i.created_at DESC
    ''');

    // Pour chaque facture, charger ses articles
    final List<InvoiceModel> invoices = [];
    for (final map in invoiceMaps) {
      final items = await _getItemsForInvoice(db, map['id'] as int);
      invoices.add(InvoiceModel.fromMap(
        map,
        items: items,
        clientName: map['client_name'] as String?,
      ));
    }
    return invoices;
  }

  /// Récupère une facture par son id avec tous ses articles.
  Future<InvoiceModel?> getInvoiceById(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT i.*, c.name AS client_name
      FROM $tableInvoices i
      LEFT JOIN $tableClients c ON i.client_id = c.id
      WHERE i.id = ?
    ''', [id]);

    if (maps.isEmpty) return null;
    final items = await _getItemsForInvoice(db, id);
    return InvoiceModel.fromMap(maps.first, items: items,
        clientName: maps.first['client_name'] as String?);
  }

  /// Charge tous les articles d'une facture donnée.
  Future<List<InvoiceItemModel>> _getItemsForInvoice(
      Database db, int invoiceId) async {
    final itemMaps = await db.query(
      tableInvoiceItems,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return itemMaps.map((m) => InvoiceItemModel.fromMap(m)).toList();
  }

  /// Met à jour une facture et remplace ses articles (delete + re-insert).
  Future<void> updateInvoice(InvoiceModel invoice) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Mettre à jour l'en-tête
      await txn.update(
        tableInvoices,
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );
      // 2. Supprimer les anciens articles (CASCADE fait cela automatiquement
      //    lors d'un DELETE sur invoice, mais ici on garde la facture)
      await txn.delete(
        tableInvoiceItems,
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      // 3. Re-insérer les articles mis à jour
      for (final item in invoice.items) {
        await txn.insert(
          tableInvoiceItems,
          item.copyWith(invoiceId: invoice.id).toMap(),
        );
      }
    });
  }

  /// Supprime une facture et ses articles (CASCADE SQLite).
  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete(
      tableInvoices,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Met à jour uniquement le statut d'une facture.
  Future<int> updateInvoiceStatus(int id, InvoiceStatus status) async {
    final db = await database;
    return await db.update(
      tableInvoices,
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Statistiques Dashboard
  // ══════════════════════════════════════════════════════════════════════════════

  /// Retourne le nombre total de clients.
  Future<int> getClientCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM $tableClients');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Retourne le nombre de factures par statut.
  Future<Map<String, int>> getInvoiceCountByStatus() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) AS count
      FROM $tableInvoices
      GROUP BY status
    ''');
    return {for (final row in result) row['status'] as String: row['count'] as int};
  }

  /// Calcule le total des factures payées (somme des totaux via les items).
  Future<double> getTotalRevenue() async {
    final db = await database;
    // Jointure pour calculer le total de chaque facture payée
    final result = await db.rawQuery('''
      SELECT SUM(ii.quantity * ii.unit_price * (1 + i.tax_rate)) AS revenue
      FROM $tableInvoices i
      JOIN $tableInvoiceItems ii ON i.id = ii.invoice_id
      WHERE i.status = 'paid'
    ''');
    return (result.first['revenue'] as num?)?.toDouble() ?? 0.0;
  }

  /// Supprime toutes les données de toutes les tables (Factory Reset).
  Future<void> resetDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableInvoiceItems);
      await txn.delete(tableInvoices);
      await txn.delete(tableClients);
      await txn.delete(tableCompanies);
    });
  }
}
