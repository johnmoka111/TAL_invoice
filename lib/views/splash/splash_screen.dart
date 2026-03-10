// views/splash/splash_screen.dart
// ──────────────────────────────────────────────────────────────────────────────
// SplashScreen — Premier écran affiché au démarrage.
//
// Flux de navigation :
//   SplashScreen
//     → [activation requise ?] → ActivationPage
//     → [onboarding vu ?]      → OnboardingPage
//     → [profil entreprise ?]  → DashboardPage OU SetupPage
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/activation/activation_service.dart';
import '../shared/app_theme.dart';
import '../onboarding/activation_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Contrôle l'affichage de l'écran d'activation en overlay
  bool _showActivation = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Délai minimal pour afficher le splash
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // ── Étape 1 : Vérifier l'activation ──────────────────────────────────────
    final isActivated = await ActivationService.isActivated();
    if (!mounted) return;

    if (!isActivated) {
      // Afficher l'écran d'activation (overlay par-dessus le splash)
      setState(() => _showActivation = true);
      return;
    }

    // ── Étape 2 : Vérifier si l'onboarding a été vu ──────────────────────────
    _proceedAfterActivation();
  }

  /// Appelé après activation réussie (ou si déjà activé)
  Future<void> _proceedAfterActivation() async {
    setState(() => _showActivation = false);

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;

    if (!seen) {
      context.go('/onboarding');
    } else {
      context.read<AuthBloc>().add(const LoadCompany());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Corps principal du Splash ──────────────────────────────────────
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is CompanyLoaded) {
                context.go('/dashboard');
              } else if (state is CompanyNotFound) {
                context.go('/setup');
              } else if (state is CompanyError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.error),
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.primary,
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(40),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Image.asset('assets/images/logo_talhub.png',
                                fit: BoxFit.contain),
                          ).animate().scale(
                              duration: 800.ms, curve: Curves.elasticOut),

                          const SizedBox(height: 32),
                          const Text(
                            'TAL Invoice',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 8),
                          const Text(
                            'L\'ART DE FACTURER',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4),
                          ).animate().fadeIn(delay: 800.ms),

                          const SizedBox(height: 60),
                          const CircularProgressIndicator(color: Colors.white)
                              .animate()
                              .fadeIn(delay: 1.2.seconds),
                        ],
                      ),
                    ),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Text('v 1.3.0 | John Moka',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Overlay d'activation (s'affiche par-dessus le splash) ──────────
          if (_showActivation)
            ActivationPage(
              onActivated: _proceedAfterActivation,
            ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

