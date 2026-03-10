// views/settings/invoice_settings_page.dart
// ──────────────────────────────────────────────────────────────────────────────
// Page de personnalisation de la facture :
//   - Modification du logo entreprise
//   - Upload signature PNG transparente
//   - Champ nom du responsable
//   - Champ poste du responsable
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../models/company_model.dart';
import '../shared/app_theme.dart';

class InvoiceSettingsPage extends StatefulWidget {
  const InvoiceSettingsPage({super.key});

  @override
  State<InvoiceSettingsPage> createState() => _InvoiceSettingsPageState();
}

class _InvoiceSettingsPageState extends State<InvoiceSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _managerNameCtrl = TextEditingController();
  final _managerRoleCtrl = TextEditingController();
  final _defaultNotesCtrl = TextEditingController();

  // Chemins d'images sélectionnés (null = pas modifié)
  String? _newLogoPath;
  String? _newSignaturePath;

  // Données actuelles chargées depuis le BLoC
  CompanyModel? _company;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is CompanyLoaded) {
      _company = state.company;
      _managerNameCtrl.text = state.company.managerName ?? '';
      _managerRoleCtrl.text = state.company.managerRole ?? '';
      _defaultNotesCtrl.text = state.company.defaultNotes ?? '';
    }
  }

  @override
  void dispose() {
    _managerNameCtrl.dispose();
    _managerRoleCtrl.dispose();
    _defaultNotesCtrl.dispose();
    super.dispose();
  }

  // ── Sélection du logo ──────────────────────────────────────────────────────
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _newLogoPath = picked.path);
    }
  }

  // ── Sélection de la signature PNG ─────────────────────────────────────────
  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _newSignaturePath = picked.path);
    }
  }

  // ── Sauvegarde des paramètres ─────────────────────────────────────────────
  Future<void> _save() async {
    if (_company == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = _company!.copyWith(
      logoPath: _newLogoPath ?? _company!.logoPath,
      signaturePath: _newSignaturePath ?? _company!.signaturePath,
      managerName: _managerNameCtrl.text.trim().isEmpty ? null : _managerNameCtrl.text.trim(),
      managerRole: _managerRoleCtrl.text.trim().isEmpty ? null : _managerRoleCtrl.text.trim(),
      defaultNotes: _defaultNotesCtrl.text.trim().isEmpty ? null : _defaultNotesCtrl.text.trim(),
    );

    context.read<AuthBloc>().add(SaveCompany(updated));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isSaving = false);
        if (state is CompanyLoaded) {
          _company = state.company;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paramètres de facture sauvegardés'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres de facture'),
          actions: [
            TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Sauvegarder'),
            ),
          ],
        ),
        body: _company == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.paddingMD),
                  children: [
                    // ── Info Banner ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.primary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ces paramètres s\'appliquent automatiquement à toutes les nouvelles factures générées.',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(180)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section : Logo entreprise ──────────────────────────────
                    _buildSectionTitle('LOGO ENTREPRISE'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Aperçu logo actuel ou nouveau
                            _buildLogoPreview(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.photo_library_rounded),
                                    label: const Text('Choisir un logo'),
                                    onPressed: _pickLogo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Le logo apparaîtra en haut de la facture et en filigrane (opacité 5%).',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section : Signature ────────────────────────────────────
                    _buildSectionTitle('SIGNATURE NUMÉRIQUE'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSignaturePreview(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.draw_rounded),
                                    label: const Text('Importer une signature PNG'),
                                    onPressed: _pickSignature,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Recommandé : image PNG avec fond transparent. La signature sera affichée dans la partie basse de la facture.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section : Responsable ──────────────────────────────────
                    _buildSectionTitle('RESPONSABLE'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _managerNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nom du responsable',
                                hintText: 'Ex: Jean-Pierre Mobutu',
                                prefixIcon: Icon(Icons.person_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _managerRoleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Poste du responsable',
                                hintText: 'Ex: Directeur, CEO, Gérant...',
                                prefixIcon: Icon(Icons.work_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Suggestions rapides
                            Wrap(
                              spacing: 8,
                              children: [
                                'Directeur', 'CEO', 'Gérant',
                                'Installateur privé', 'Responsable technique'
                              ].map((role) => ActionChip(
                                label: Text(role, style: const TextStyle(fontSize: 12)),
                                onPressed: () => setState(() => _managerRoleCtrl.text = role),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section : Notes par défaut ──────────────────────────────
                    _buildSectionTitle('NOTES & CONDITIONS PAR DÉFAUT'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _defaultNotesCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Notes automatiques (RIB, délais...)',
                                hintText: 'Ex: Merci de régler sous 15 jours...',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ces notes seront automatiquement ajoutées au bas de chaque nouvelle facture.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Aperçu bas de facture ──────────────────────────────────
                    _buildSectionTitle('APERÇU BAS DE FACTURE'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSignaturePreviewBox(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Aperçu du logo ─────────────────────────────────────────────────────────
  Widget _buildLogoPreview() {
    final effectivePath = _newLogoPath ?? _company?.logoPath;
    if (effectivePath == null || effectivePath.isEmpty) {
      return Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(effectivePath),
        height: 90,
        width: 90,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
      ),
    );
  }

  // ── Aperçu de la signature ─────────────────────────────────────────────────
  Widget _buildSignaturePreview() {
    final effectivePath = _newSignaturePath ?? _company?.signaturePath;
    if (effectivePath == null || effectivePath.isEmpty) {
      return Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.draw_outlined, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text('Aucune signature importée', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withAlpha(80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(effectivePath),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
        ),
      ),
    );
  }

  // ── Aperçu bas de facture (signature + nom + poste) ────────────────────────
  Widget _buildSignaturePreviewBox() {
    final signaturePath = _newSignaturePath ?? _company?.signaturePath;
    final managerName = _managerNameCtrl.text.trim().isNotEmpty
        ? _managerNameCtrl.text.trim()
        : (_company?.managerName ?? '');
    final managerRole = _managerRoleCtrl.text.trim().isNotEmpty
        ? _managerRoleCtrl.text.trim()
        : (_company?.managerRole ?? '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIGNATURE & CACHET',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          // Signature image
          if (signaturePath != null && signaturePath.isNotEmpty)
            SizedBox(
              height: 60,
              child: Image.file(File(signaturePath), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            )
          else
            Container(height: 40, color: Colors.transparent),
          const Divider(thickness: 0.5),
          if (managerName.isNotEmpty)
            Text(managerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (managerRole.isNotEmpty)
            Text(managerRole, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
