import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import 'pdf_invoice_api.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../logic/invoice/invoice_bloc.dart';
import '../../logic/invoice/invoice_event.dart';
import '../../logic/invoice/invoice_state.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../models/invoice_model.dart';
import '../shared/app_theme.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  InvoiceStatus? _activeFilter;

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(const LoadInvoices());
  }

  void _applyFilter(InvoiceStatus? status) {
    setState(() => _activeFilter = status);
    context.read<InvoiceBloc>().add(FilterInvoices(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Factures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Imprimer tout (6 par page)',
            onPressed: () => _bulkPrint(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filtres ──────────────────────────────────────────────────────
            _buildFilterBar(),

            // ── Liste ─────────────────────────────────────────────────────────
            Expanded(
              child: BlocConsumer<InvoiceBloc, InvoiceState>(
                listener: (context, state) {
                  if (state is InvoiceOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.success,
                    ));
                  } else if (state is InvoiceError) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.error,
                    ));
                  }
                },
                builder: (context, state) {
                  if (state is InvoiceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<InvoiceModel> invoices = [];
                  if (state is InvoiceLoaded) invoices = state.invoices;
                  if (state is InvoiceOperationSuccess) invoices = state.invoices;

                  if (invoices.isEmpty) return _emptyState();

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount: invoices.length,
                      itemBuilder: (ctx, i) {
                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _invoiceTile(invoices[i]),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/new').then((_) {
          if (mounted) context.read<InvoiceBloc>().add(const LoadInvoices());
        }),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle Facture'),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = <InvoiceStatus?>[null, ...InvoiceStatus.values];
    final labels = {
      null: 'Toutes',
      InvoiceStatus.draft: 'Brouillon',
      InvoiceStatus.sent: 'En attente',
      InvoiceStatus.paid: 'Payée',
    };

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMD),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final status = filters[index];
          final selected = _activeFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[status]!),
              selected: selected,
              onSelected: (_) => _applyFilter(status),
              selectedColor: AppTheme.primary,
              backgroundColor: Theme.of(context).cardColor,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _invoiceTile(InvoiceModel invoice) {
    final currency = _getCurrency();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _statusColor(invoice.status).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_rounded, color: _statusColor(invoice.status), size: 24),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.clientName ?? 'Client Inconnu',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(invoice.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,##0.00').format(invoice.total)} $currency',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isDark ? AppTheme.primaryLight : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            _statusBadge(invoice.status),
          ],
        ),
        onTap: () => context.push('/invoices/${invoice.id}').then((_) {
          if (mounted) context.read<InvoiceBloc>().add(const LoadInvoices());
        }),
      ),
    );
  }

  Widget _statusBadge(InvoiceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withAlpha(40),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: _statusColor(status),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return const Color(0xFF9E9E9E);
      case InvoiceStatus.sent:
        return Colors.orange;
      case InvoiceStatus.paid:
        return AppTheme.success;
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppTheme.primary.withAlpha(50)),
          const SizedBox(height: 20),
          const Text(
            'Aucune facture trouvée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Commencez par en créer une nouvelle.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getCurrency() {
    final s = context.read<AuthBloc>().state;
    return s is CompanyLoaded ? s.company.currency : 'USD';
  }

  Future<void> _bulkPrint(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! CompanyLoaded) return;

    final invoiceState = context.read<InvoiceBloc>().state;
    List<InvoiceModel> invoices = [];
    if (invoiceState is InvoiceLoaded) invoices = invoiceState.invoices;
    if (invoiceState is InvoiceOperationSuccess) invoices = invoiceState.invoices;

    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune facture à imprimer')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préparation de l\'impression en masse...')));

    try {
      final allClients = await DatabaseHelper.instance.getAllClients();
      await PdfInvoiceApi.generateBulkInvoices(
        invoices: invoices,
        company: authState.company,
        allClients: allClients,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
      }
    }
  }
}
