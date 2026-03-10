// views/settings/settings_page.dart
// Paramètres de l'application et modification du profil entreprise.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/theme/theme_cubit.dart'; // Import ThemeCubit
import '../shared/app_theme.dart';
import '../setup/profile_setup_page.dart';
import 'invoice_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is CompanyNotFound) {
          // Si réinitialisé, on repart à zéro
          context.go('/');
        } else if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Paramètres')),
        body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! CompanyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final company = authState.company;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.paddingMD),
            children: [
              // ── Thème ──────────────────────────────────────────────────
              _buildSectionTitle('APPARENCE'),
              Card(
                child: BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, mode) {
                    final isDark = mode == ThemeMode.dark;
                    return ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark ? Colors.amber : AppTheme.primary,
                      ),
                      title: Text(isDark ? 'Mode Sombre' : 'Mode Clair'),
                      trailing: Switch(
                        value: isDark,
                        activeThumbColor: AppTheme.primaryLight,
                        onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Mon profil entreprise ─────────────────────────────────────
              _buildSectionTitle('ENTREPRISE'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business_rounded, color: AppTheme.primary),
                      title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Modifier les informations'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileSetupPage(existingCompany: company),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    if (company.rccm != null) ...[
                      _buildInfoTile(Icons.assignment_ind_rounded, 'Numéro RCCM', company.rccm!),
                      const Divider(height: 1, indent: 56),
                    ],
                    if (company.idNational != null) ...[
                      _buildInfoTile(Icons.badge_rounded, 'ID National', company.idNational!),
                      const Divider(height: 1, indent: 56),
                    ],
                    _buildInfoTile(Icons.euro_symbol_rounded, 'Devise', company.currency),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Paramètres de facture ─────────────────────────────────────────
              _buildSectionTitle('FACTURE'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                      title: const Text('Paramètres de facture'),
                      subtitle: const Text('Logo, signature, responsable...'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvoiceSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Données et Sécurité ──────────────────────────────────────
              _buildSectionTitle('DONNÉES'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage_rounded, color: AppTheme.primary),
                      title: const Text('Sauvegarde locale'),
                      subtitle: const Text('Les données sont stockées sur cet appareil'),
                      trailing: const Chip(label: Text('OFFLINE')),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.error),
                      title: const Text('Effacer toutes les données',
                          style: TextStyle(color: AppTheme.error)),
                      onTap: () => _showResetConfirmation(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── À propos ────────────────────────────────────────────────
              _buildSectionTitle('À PROPOS'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline, color: AppTheme.primary),
                      title: Text('Version'),
                      trailing: Text('1.0.0'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: AppTheme.primary),
                      title: const Text('À propos du développeur'),
                      subtitle: const Text('Contact & Bio (John Moka)'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/about'),
                    ),
                  ],
                ),
              ),
            ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      dense: true,
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialisation complète ?'),
        content: const Text(
            'Toutes vos factures, vos clients et vos paramètres seront DEFINITIVEMENT supprimés. Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const ResetApp());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('EFFACER TOUT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
