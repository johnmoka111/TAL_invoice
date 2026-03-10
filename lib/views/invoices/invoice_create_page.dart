import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_helper.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/invoice/invoice_bloc.dart';
import '../../logic/invoice/invoice_event.dart';
import '../../logic/invoice/invoice_state.dart';
import '../../models/client_model.dart';
import '../../models/invoice_item_model.dart';
import '../../models/invoice_model.dart';
import '../shared/app_theme.dart';
import '../shared/custom_text_field.dart';
import '../shared/primary_button.dart';

class InvoiceCreatePage extends StatefulWidget {
  const InvoiceCreatePage({super.key});

  @override
  State<InvoiceCreatePage> createState() => _InvoiceCreatePageState();
}

class _InvoiceCreatePageState extends State<InvoiceCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  List<ClientModel> _clients = [];
  ClientModel? _selectedClient;
  bool _isLoadingClients = true;

  // Articles de facture (lignes dynamiques)
  final List<_ItemRow> _itemRows = [];

  double _taxRate = 0.0; // ex: 0.16 pour 16%

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadCompanyData();
    _addItemRow(); // Au moins une ligne par défaut
  }

  Future<void> _loadCompanyData() async {
    final company = await DatabaseHelper.instance.getCompany();
    if (mounted && company != null && company.defaultNotes != null) {
      _notesCtrl.text = company.defaultNotes!;
    }
  }

  Future<void> _loadClients() async {
    final clients = await DatabaseHelper.instance.getAllClients();
    if (mounted) {
      setState(() {
        _clients = clients;
        _isLoadingClients = false;
      });
    }
  }

  void _addItemRow() {
    final companyCurrency = _getCurrency();
    setState(() {
      _itemRows.add(_ItemRow()..currency = companyCurrency);
    });
  }

  void _removeItemRow(int index) {
    if (_itemRows.length == 1) return; // Garder au moins une ligne
    setState(() => _itemRows.removeAt(index));
  }

  /// Calcule le sous-total en lisant les valeurs des contrôleurs
  double get _subtotal {
    return _itemRows.fold(0.0, (sum, row) {
      final qty = double.tryParse(row.qtyCtrl.text) ?? 0.0;
      final price = double.tryParse(row.priceCtrl.text) ?? 0.0;
      return sum + (qty * price);
    });
  }

  double get _taxAmount => _subtotal * _taxRate;
  double get _total => _subtotal + _taxAmount;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner un client'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Construire les articles
    final items = _itemRows.map((row) {
      return InvoiceItemModel(
        description: row.descCtrl.text.trim(),
        quantity: double.tryParse(row.qtyCtrl.text) ?? 1.0,
        unitPrice: double.tryParse(row.priceCtrl.text) ?? 0.0,
        currency: row.currency,
      );
    }).toList();

    // Générer un numéro de facture unique
    final invoiceNumber =
        'FAC-${DateTime.now().year}-${const Uuid().v4().substring(0, 6).toUpperCase()}';

    final invoice = InvoiceModel(
      invoiceNumber: invoiceNumber,
      clientId: _selectedClient!.id!,
      items: items,
      taxRate: _taxRate,
      status: InvoiceStatus.draft,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    context.read<InvoiceBloc>().add(CreateInvoice(invoice));
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = _getCurrency();

    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceOperationSuccess) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ));
        } else if (state is InvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.error,
          ));
        }
      },
      builder: (context, state) {
        final isSaving = state is InvoiceLoading;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: const Text('Créer une Facture')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── CLIENT ───────────────────────────────────────────────────
                  _sectionHeader('CLIENT & DESTINATAIRE', Icons.person_pin_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildClientCard(isDark),
                  const SizedBox(height: 24),

                  // ── ARTICLES ─────────────────────────────────────────────────
                  _sectionHeader('LIGNES DE FACTURATION', Icons.shopping_basket_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildItemsList(isDark),
                  const SizedBox(height: 24),

                  // ── TAXE ─────────────────────────────────────────────────────
                  _sectionHeader('CONFIGURATION FISCALE', Icons.account_balance_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildTaxCard(isDark),
                  const SizedBox(height: 24),

                  // ── NOTES ────────────────────────────────────────────────────
                  _sectionHeader('NOTES & CONDITIONS', Icons.description_rounded, isDark),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _notesCtrl,
                    label: 'Notes de bas de page',
                    hint: 'Merci pour votre confiance...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 32),

                  // ── RÉSUMÉ TOTAL ──────────────────────────────────────────────
                  _buildTotalCard(currency, isDark).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  PrimaryButton(
                    label: 'GÉNÉRER LA FACTURE',
                    icon: Icons.check_circle_rounded,
                    isLoading: isSaving,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: isDark ? Colors.white70 : AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: _isLoadingClients
          ? const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator())
          : _clients.isEmpty
              ? _noClientsWarning()
              : DropdownButtonFormField<ClientModel>(
                  value: _selectedClient,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people_alt_rounded, color: AppTheme.primary),
                    hintText: 'Choisir le client bénéficiaire',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _clients
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedClient = c),
                  validator: (_) => _selectedClient == null ? 'Sélection requise' : null,
                ),
    );
  }

  Widget _buildItemsList(bool isDark) {
    return Column(
      children: [
        ...List.generate(_itemRows.length, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                if (!isDark) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemRows[i].descCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Désignation de l\'article ou service...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    if (_itemRows.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 22),
                        onPressed: () => _removeItemRow(i),
                      ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.5),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _smallField(
                        controller: _itemRows[i].qtyCtrl,
                        label: 'QTÉ',
                        hint: '1',
                        icon: Icons.numbers_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _smallField(
                        controller: _itemRows[i].priceCtrl,
                        label: 'PRIX UNitaire',
                        hint: '0.00',
                        icon: Icons.payments_rounded,
                        suffix: DropdownButton<String>(
                          value: _itemRows[i].currency,
                          underline: const SizedBox(),
                          items: ['USD', 'CDF'].map((e) => DropdownMenuItem(value: e, child: Text(e == 'CDF' ? 'FC' : 'USD', style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _itemRows[i].currency = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addItemRow,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('AJOUTER UNE LIGNE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _smallField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('APPLIQUER UNE TAXE (TVA)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: Text('${(_taxRate * 100).round()}%', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          Slider(
            value: _taxRate * 100,
            min: 0,
            max: 30,
            divisions: 30,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _taxRate = v / 100),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String currency, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          _totalRow('SOUS-TOTAL', _subtotal, currency, false),
          if (_taxRate > 0) ...[
            const SizedBox(height: 8),
            _totalRow('TAXE (${(_taxRate * 100).round()}%)', _taxAmount, currency, false),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),
          _totalRow('TOTAL GÉNÉRAL', _total, currency, true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, String currency, bool isMain) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isMain ? Colors.white : Colors.white70,
            fontSize: isMain ? 15 : 12,
            fontWeight: isMain ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '${NumberFormat('#,##0.00').format(amount)} $currency',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMain ? 22 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _noClientsWarning() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: 12),
          const Expanded(child: Text('Aucun client enregistré !', style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => context.push('/clients/new').then((_) => _loadClients()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('AJOUTER'),
          ),
        ],
      ),
    );
  }

  String _getCurrency() {
    final s = context.read<AuthBloc>().state;
    return s is CompanyLoaded ? s.company.currency : 'USD';
  }
}

/// Classe interne pour gérer les contrôleurs d'une ligne d'article
class _ItemRow {
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController priceCtrl = TextEditingController(text: '0');
  String currency = 'USD';

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}
