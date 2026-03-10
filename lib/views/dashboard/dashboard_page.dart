// views/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/database_helper.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../models/invoice_model.dart';
import '../shared/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _clientCount = 0;
  Map<String, int> _invoiceStats = {};
  double _totalRevenue = 0.0;
  List<InvoiceModel> _recentInvoices = [];
  bool _isLoadingStats = true;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    
    try {
      final db = DatabaseHelper.instance;
      
      // On lance les requêtes en parallèle pour la vitesse
      final results = await Future.wait([
        db.getClientCount(),
        db.getInvoiceCountByStatus(),
        db.getTotalRevenue(),
        db.getAllInvoices(), // Pour les activités récentes
      ]);

      if (mounted) {
        setState(() {
          _clientCount = results[0] as int;
          _invoiceStats = results[1] as Map<String, int>;
          _totalRevenue = results[2] as double;
          
          final allInvoices = results[3] as List<InvoiceModel>;
          _recentInvoices = allInvoices.take(5).toList();
          
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard Stats Error: $e");
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildModernHeader(isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // ── Grille de Stats ─────────────────────────────────────────
                      _buildStatsGrid(isDark),
                      const SizedBox(height: 32),

                      // ── Activités Récentes ─────────────────────────────────────
                      _sectionHeader('Activités Récentes', 'Factures', () => context.push('/invoices'), isDark),
                      const SizedBox(height: 12),
                      _buildRecentInvoices(isDark),
                      const SizedBox(height: 32),

                      // ── Raccourcis Rapides ─────────────────────────────────────
                      _sectionHeader('Modules', null, null, isDark),
                      const SizedBox(height: 12),
                      _buildModuleCards(isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/new').then((_) => _loadStats()),
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('NOUVELLE FACTURE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
      ).animate().scale(delay: 500.ms),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) {
          if (i == _currentNavIndex) return;
          setState(() => _currentNavIndex = i);
          switch (i) {
            case 1: context.push('/invoices').then((_) => _loadStats()); break;
            case 2: context.push('/clients').then((_) => _loadStats()); break;
            case 3: context.push('/settings').then((_) => _loadStats()); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Résumé'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Factures'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_rounded), label: 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final company = state is CompanyLoaded ? state.company : null;
              return Row(
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: company?.logoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(company!.logoPath!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.business_rounded, color: AppTheme.primary),
                  ).animate().scale(duration: 400.ms),
                  const SizedBox(width: 16),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          company?.name ?? 'Chargement...',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              company?.email ?? 'votre@entreprise.com',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final currency = _getCurrency();
    final totalInvoices = _invoiceStats.values.fold(0, (a, b) => a + b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statBox('REVENUS PAYÉS', '${NumberFormat.compact().format(_totalRevenue)} $currency', AppTheme.success, Icons.account_balance_wallet_rounded, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox('FACTURES', totalInvoices.toString(), AppTheme.primary, Icons.description_rounded, isDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statBox('CLIENTS', _clientCount.toString(), const Color(0xFF673AB7), Icons.people_rounded, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox('À RÉCUPÉRER', '${_invoiceStats['sent'] ?? 0}', AppTheme.accent, Icons.pending_actions_rounded, isDark),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _statBox(String label, String value, Color accentColor, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(40), width: 1.5),
        boxShadow: [
          if (!isDark) BoxShadow(color: accentColor.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Icon(icon, size: 14, color: accentColor.withAlpha(150)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryDark)),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(bool isDark) {
    if (_isLoadingStats) return const Center(child: LinearProgressIndicator());
    if (_recentInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('Aucune facture récente', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: AnimationConfiguration.toStaggeredList(
        duration: const Duration(milliseconds: 375),
        childAnimationBuilder: (widget) => SlideAnimation(horizontalOffset: 50.0, child: FadeInAnimation(child: widget)),
        children: _recentInvoices.map((inv) => _invoiceTile(inv, isDark)).toList(),
      ),
    );
  }

  Widget _invoiceTile(InvoiceModel inv, bool isDark) {
    final statusColor = inv.status == InvoiceStatus.paid 
        ? AppTheme.statusPaid 
        : inv.status == InvoiceStatus.sent 
            ? AppTheme.statusSent 
            : AppTheme.statusDraft;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withAlpha(30))),
      child: ListTile(
        onTap: () => context.push('/invoices/${inv.id}').then((_) => _loadStats()),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withAlpha(20), shape: BoxShape.circle),
          child: Icon(Icons.receipt_rounded, color: statusColor, size: 20),
        ),
        title: Text(inv.clientName ?? 'Client Inconnu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text(DateFormat('dd MMM').format(inv.createdAt), style: const TextStyle(fontSize: 11)),
        trailing: Text(
          '${inv.total.toStringAsFixed(0)} ${_getCurrency()}',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
        ),
      ),
    );
  }

  Widget _buildModuleCards(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _moduleButton('CLIENTS', Icons.people_rounded, const Color(0xFF673AB7), '/clients', isDark),
        _moduleButton('PARAMÈTRES', Icons.tune_rounded, const Color(0xFF009688), '/settings', isDark),
      ],
    );
  }

  Widget _moduleButton(String label, IconData icon, Color color, String route, bool isDark) {
    return InkWell(
      onTap: () => context.push(route).then((_) => _loadStats()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? actionText, VoidCallback? onAction, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
        if (actionText != null)
          TextButton(onPressed: onAction, child: Text(actionText, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w900))),
      ],
    );
  }

  String _getCurrency() {
    final authState = context.read<AuthBloc>().state;
    if (authState is CompanyLoaded) return authState.company.currency;
    return 'USD';
  }
}

