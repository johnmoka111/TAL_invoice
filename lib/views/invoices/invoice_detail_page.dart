// views/invoices/invoice_detail_page.dart
// Visualisation détaillée d'une facture avec possibilité de changer le statut ou de supprimer.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../logic/invoice/invoice_bloc.dart';
import '../../logic/invoice/invoice_event.dart';
import '../../logic/invoice/invoice_state.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../models/invoice_model.dart';
import '../shared/app_theme.dart';
import '../shared/primary_button.dart';
import 'pdf_invoice_api.dart'; // Ajout de l'API PDF
import '../../models/client_model.dart';

class InvoiceDetailPage extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  InvoiceModel? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    final invoice = await DatabaseHelper.instance.getInvoiceById(widget.invoiceId);
    if (mounted) {
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    }
  }

  void _updateStatus(InvoiceStatus newStatus) {
    context.read<InvoiceBloc>().add(ChangeInvoiceStatus(widget.invoiceId, newStatus));
  }

  void _deleteInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la facture'),
        content: const Text('Voulez-vous vraiment supprimer cette facture ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<InvoiceBloc>().add(DeleteInvoice(widget.invoiceId));
    }
  }

  Future<void> _downloadPdf() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! CompanyLoaded || _invoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données non prêtes pour le PDF')),
      );
      return;
    }

    try {
      final client = await DatabaseHelper.instance.getClientById(_invoice!.clientId);
      if (client == null) throw Exception('Client introuvable');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préparation du document PDF...'), duration: Duration(seconds: 1)),
      );

      if (mounted) {
        await PdfInvoiceApi.generateAndPrint(
          invoice: _invoice!,
          company: authState.company,
          client: client,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur PDF: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceOperationSuccess) {
          if (state.message.contains('supprimée')) {
            context.pop();
          } else {
            _loadInvoice(); // Recharger après changement de statut
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_invoice?.invoiceNumber ?? 'Facture'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteInvoice,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _invoice == null
                ? const Center(child: Text('Facture non trouvée'))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final invoice = _invoice!;
    final currency = _getCurrency();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête Statut ──────────────────────────────────────────
                  _buildStatusHeader(invoice),
                  const SizedBox(height: 16),

                  // ── Infos Client ──────────────────────────────────────────
                  _buildSection(
                    title: 'Destinataire',
                    icon: Icons.person_outline,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice.clientName ?? 'Client inconnu',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Date: ${DateFormat('dd MMMM yyyy').format(invoice.createdAt)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Articles ──────────────────────────────────────────────
                  _buildSection(
                    title: 'Articles',
                    icon: Icons.list_alt_rounded,
                    content: Column(
                      children: [
                        ...invoice.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.description,
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ${item.currency == "CDF" ? "FC" : "USD"}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Text('${item.total.toStringAsFixed(2)} ${item.currency == "CDF" ? "FC" : "USD"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                        const Divider(height: 24),
                        _summaryRow('Sous-total', invoice.subtotal, currency),
                        if (invoice.taxRate > 0)
                          _summaryRow('Taxe (${(invoice.taxRate * 100).round()}%)',
                              invoice.taxAmount, currency),
                        _summaryRow('TOTAL', invoice.total, currency, isBold: true),
                      ],
                    ),
                  ),

                  // ── Notes ────────────────────────────────────────────────
                  if (invoice.notes != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Notes',
                      icon: Icons.note_outlined,
                      content: Text(invoice.notes!),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Actions ────────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _buildActionButtons(invoice),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(InvoiceModel invoice) {
    Color color;
    IconData icon;
    switch (invoice.status) {
      case InvoiceStatus.draft:
        color = AppTheme.statusDraft;
        icon = Icons.edit_note_rounded;
      case InvoiceStatus.sent:
        color = AppTheme.statusSent;
        icon = Icons.hourglass_empty_rounded;
      case InvoiceStatus.paid:
        color = AppTheme.statusPaid;
        icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statut actuel', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(invoice.status.label.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark)),
            ],
          ),
          const Divider(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, String currency, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14)),
        Text('${amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
                color: isBold ? AppTheme.primary : Colors.black87)),
      ],
    );
  }

  Widget _buildActionButtons(InvoiceModel invoice) {
    return Column(
      children: [
        if (invoice.status == InvoiceStatus.draft)
          PrimaryButton(
            label: 'Valider la facture',
            icon: Icons.assignment_turned_in_rounded,
            onPressed: () => _updateStatus(InvoiceStatus.sent),
          ),
        if (invoice.status == InvoiceStatus.sent)
          PrimaryButton(
            label: 'Marquer comme payée',
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
            onPressed: () => _updateStatus(InvoiceStatus.paid),
          ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Télécharger / Partager PDF',
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.blueGrey,
          onPressed: _downloadPdf,
        ),
      ],
    );
  }

  String _getCurrency() {
    final s = context.read<AuthBloc>().state;
    return s is CompanyLoaded ? s.company.currency : 'USD';
  }
}
