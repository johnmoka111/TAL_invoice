// views/onboarding/activation_page.dart
// ──────────────────────────────────────────────────────────────────────────────
// Écran d'activation de l'application.
// Affiché au premier lancement si aucune clé valide n'a été saisie.
//
// UX :
//  - Champ de saisie avec format auto XXXX-XXXX (tiret inséré automatiquement)
//  - Bouton "Activer l'application"
//  - Message de succès (vert) ou d'erreur (rouge)
//  - Animation d'entrée premium
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/activation/activation_service.dart';
import '../shared/app_theme.dart';
import 'activation_help_page.dart';

class ActivationPage extends StatefulWidget {
  /// Callback appelé lorsque l'activation est réussie
  final VoidCallback onActivated;

  const ActivationPage({super.key, required this.onActivated});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _keyCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  // Compteur d'essais
  int _failedAttempts = 0;

  @override
  void dispose() {
    _keyCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Tentative d'activation ────────────────────────────────────────────────
  Future<void> _tryActivate() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer une clé d\'activation.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Légère pause pour l'effet de chargement
    await Future.delayed(const Duration(milliseconds: 800));

    final result = await ActivationService.activate(key);

    if (!mounted) return;

    if (result) {
      setState(() {
        _success = true;
        _isLoading = false;
      });
      // Attendre l'animation de succès puis continuer
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) widget.onActivated();
    } else {
      _failedAttempts++;

      if (_failedAttempts >= 2) {
        // Redirection vers la page d'aide
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ActivationHelpPage()),
          );
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Trop de tentatives échouées. Veuillez contacter le support.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Clé d\'activation incorrecte. Veuillez réessayer.';
        });
        // Vibration légère (feedback haptique)
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Indigo 900
              Color(0xFF283593), // Indigo 800
              Color(0xFF3949AB), // Indigo 600
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Logo ────────────────────────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_talhub.png',
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.elasticOut),

                const SizedBox(height: 32),

                // ── Titre ───────────────────────────────────────────────────
                const Text(
                  'Activation de l\'application',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                Text(
                  'Veuillez entrer votre clé d\'activation\npour accéder à l\'application.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 48),

                // ── Carte de saisie ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icône clé
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.vpn_key_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Champ de saisie de la clé
                      TextField(
                        controller: _keyCtrl,
                        focusNode: _focusNode,
                        enabled: !_success,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: AppTheme.primaryDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'XXXX-XXXX',
                          hintStyle: TextStyle(
                            color: Colors.grey[300],
                            letterSpacing: 6,
                            fontWeight: FontWeight.w300,
                            fontSize: 26,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.error, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          suffixIcon: _keyCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      setState(() => _keyCtrl.clear()),
                                )
                              : null,
                        ),
                        inputFormatters: [
                          _ActivationKeyFormatter(),
                        ],
                        onChanged: (_) => setState(() => _errorMessage = null),
                        onSubmitted: (_) => _tryActivate(),
                      ),

                      const SizedBox(height: 16),

                      // ── Message d'erreur ────────────────────────────────
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.error.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppTheme.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.error, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(),

                      // ── Message de succès ───────────────────────────────
                      if (_success)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.success.withAlpha(80)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppTheme.success, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Activation réussie ! Bienvenue sur TAL Invoice.',
                                  style: TextStyle(
                                      color: AppTheme.success, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().scale(),

                      const SizedBox(height: 20),

                      // ── Bouton Activer ──────────────────────────────────
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading || _success ? null : _tryActivate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppTheme.primary.withAlpha(100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : _success
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded),
                                        SizedBox(width: 8),
                                        Text('Activé !',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_open_rounded),
                                        SizedBox(width: 10),
                                        Text(
                                          'Activer l\'application',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // ── Note de contact ─────────────────────────────────────────
                Text(
                  'Vous n\'avez pas de clé ? Contactez\nvotre administrateur TAL Invoice.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── InputFormatter : formate automatiquement la clé XXXX-XXXX ──────────────
class _ActivationKeyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Garder uniquement les caractères alphanumériques et lettres majuscules
    String cleaned = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Limiter à 8 caractères (hors tiret)
    if (cleaned.length > 8) cleaned = cleaned.substring(0, 8);

    // Insérer automatiquement le tiret après 4 caractères
    String formatted = cleaned;
    if (cleaned.length > 4) {
      formatted = '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
