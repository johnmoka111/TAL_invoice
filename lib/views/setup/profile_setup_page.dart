// views/setup/profile_setup_page.dart
// ──────────────────────────────────────────────────────────────────────────────
// ProfileSetupPage — Configuration du profil entreprise (premier lancement).
// Formulaire avec validation complète → sauvegarde via AuthBloc → SaveCompany.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../models/company_model.dart';
import '../shared/app_theme.dart';
import '../shared/custom_text_field.dart';
import '../shared/primary_button.dart';

class ProfileSetupPage extends StatefulWidget {
  final CompanyModel? existingCompany; // null = création, non-null = édition

  const ProfileSetupPage({super.key, this.existingCompany});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de formulaire
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _rccmCtrl;
  late final TextEditingController _idNationalCtrl;
  late final TextEditingController _registrationCtrl;
  late final TextEditingController _defaultNotesCtrl;

  String _selectedCurrency = 'USD';
  String? _logoPath;
  bool _isSaving = false;

  static const List<String> _currencies = ['USD', 'CDF'];

  @override
  void initState() {
    super.initState();
    // Pré-remplir si mode édition
    final c = widget.existingCompany;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _rccmCtrl = TextEditingController(text: c?.rccm ?? '');
    _idNationalCtrl = TextEditingController(text: c?.idNational ?? '');
    _registrationCtrl = TextEditingController(text: c?.registrationCertificate ?? '');
    _defaultNotesCtrl = TextEditingController(text: c?.defaultNotes ?? '');
    _selectedCurrency = c?.currency ?? 'USD';
    _logoPath = c?.logoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _rccmCtrl.dispose();
    _idNationalCtrl.dispose();
    _registrationCtrl.dispose();
    _defaultNotesCtrl.dispose();
    super.dispose();
  }

  /// Ouvre la galerie pour sélectionner un logo
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  /// Validation et soumission du formulaire
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final company = CompanyModel(
      id: widget.existingCompany?.id,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      currency: _selectedCurrency,
      logoPath: _logoPath,
      rccm: _rccmCtrl.text.trim().isEmpty ? null : _rccmCtrl.text.trim(),
      idNational: _idNationalCtrl.text.trim().isEmpty ? null : _idNationalCtrl.text.trim(),
      registrationCertificate: _registrationCtrl.text.trim().isEmpty ? null : _registrationCtrl.text.trim(),
      createdAt: widget.existingCompany?.createdAt ?? DateTime.now(),
      // Préserver les nouveaux champs s'ils existent
      signaturePath: widget.existingCompany?.signaturePath,
      managerName: widget.existingCompany?.managerName,
      managerRole: widget.existingCompany?.managerRole,
      defaultNotes: _defaultNotesCtrl.text.trim().isEmpty ? null : _defaultNotesCtrl.text.trim(),
    );

    // Envoyer l'événement au AuthBloc
    context.read<AuthBloc>().add(SaveCompany(company));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCompany != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is CompanySaving) {
            setState(() => _isSaving = true);
          } else if (state is CompanySaved) {
            setState(() => _isSaving = false);
            if (!isEditing) {
              context.go('/dashboard');
            } else {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Configuration mise à jour'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating),
              );
            }
          } else if (state is CompanyError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                stretch: true,
                automaticallyImplyLeading: isEditing,
                backgroundColor: AppTheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Container(
                    color: AppTheme.primary,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Icon(Icons.business_center_rounded, size: 70, color: Colors.white)
                              .animate()
                              .scale(duration: 600.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 12),
                          const Text(
                            'PROFIL ENTREPRISE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
                          const Text(
                            'Identité visuelle et informations légales',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── LOGO ─────────────────────────────────────────────
                        Center(child: _buildLogoSelector()).animate().fadeIn(delay: 500.ms).scale(),
                        const SizedBox(height: 40),

                        // ── FORM ───────────────────────────
                        _sectionTitle('COORDONNÉES PRINCIPALES', isDark),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _nameCtrl,
                          label: 'Nom Commercial *',
                          hint: 'ex: John Moka Services SARL',
                          prefixIcon: Icons.badge_rounded,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ).animate().fadeIn(delay: 600.ms).slideX(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email de Facturation *',
                          hint: 'finance@votreentreprise.com',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requis';
                            if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) return 'Format invalide';
                            return null;
                          },
                        ).animate().fadeIn(delay: 700.ms).slideX(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneCtrl,
                          label: 'Ligne Téléphonique *',
                          hint: '+243 ...',
                          prefixIcon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ).animate().fadeIn(delay: 800.ms).slideX(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _addressCtrl,
                          label: 'Siège Social *',
                          hint: 'Bukavu, Av. Maniema...',
                          prefixIcon: Icons.location_on_rounded,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ).animate().fadeIn(delay: 900.ms).slideX(),

                        const SizedBox(height: 40),

                        // ── LÉGAL ─────────────────────────────────────────────
                        _sectionTitle('INFORMATIONS LÉGALES (OPTIONNEL)', isDark),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _rccmCtrl,
                          label: 'Numéro RCCM',
                          hint: 'ex: CD/BKV/RCCM/20-B-0001',
                          prefixIcon: Icons.assignment_rounded,
                        ).animate().fadeIn(delay: 950.ms).slideX(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _idNationalCtrl,
                          label: 'ID National',
                          hint: 'ex: 01-123-N45678Q',
                          prefixIcon: Icons.fingerprint_rounded,
                        ).animate().fadeIn(delay: 1.seconds).slideX(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _registrationCtrl,
                          label: 'Certificat d\'enregistrement',
                          hint: 'Numéro du certificat...',
                          prefixIcon: Icons.verified_user_rounded,
                        ).animate().fadeIn(delay: 1.05.seconds).slideX(),

                        const SizedBox(height: 40),

                        // ── FINANCE ───────────────────────────────────────────
                        _sectionTitle('PRÉFÉRENCES & CONDITIONS', isDark),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _defaultNotesCtrl,
                          label: 'Notes & Conditions par défaut',
                          hint: 'ex: Coordonnées bancaires, délais de paiement...',
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ).animate().fadeIn(delay: 1.05.seconds).slideX(),
                        const SizedBox(height: 24),
                        _buildCurrencySelector().animate().fadeIn(delay: 1.1.seconds),

                        const SizedBox(height: 50),

                        // ── ACTIONS ─────────────────────────────
                        PrimaryButton(
                          label: isEditing ? 'METTRE À JOUR' : 'CRÉER MON ESPACE',
                          icon: Icons.check_rounded,
                          isLoading: _isSaving,
                          onPressed: _submit,
                        ).animate().fadeIn(delay: 1.1.seconds).scale(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoSelector() {
    return GestureDetector(
      onTap: _pickLogo,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppTheme.primary.withAlpha(50), width: 2),
        ),
        child: _logoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Image.file(File(_logoPath!), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primary),
                  const SizedBox(height: 8),
                  Text('AJOUTER LOGO',
                      style: TextStyle(
                          color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _currencies.map((currency) {
            final isSelected = _selectedCurrency == currency;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(currency),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCurrency = currency),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.primary),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? Colors.white70 : AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }
}
