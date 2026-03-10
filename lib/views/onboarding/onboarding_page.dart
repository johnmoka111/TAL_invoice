// views/onboarding/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../shared/app_theme.dart';
import 'onboarding_svgs.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Facturation Rapide',
      description: 'Créez des factures professionnelles en quelques secondes directement depuis votre mobile.',
      svg: OnboardingSVGs.invoice,
    ),
    OnboardingItem(
      title: 'Gestion Clients',
      description: 'Gardez un œil sur tous vos contacts commerciaux et leur historique de paiement.',
      svg: OnboardingSVGs.clients,
    ),
    OnboardingItem(
      title: 'Suivi des Revenus',
      description: 'Visualisez la croissance de votre activité avec des statistiques claires et précises.',
      svg: OnboardingSVGs.stats,
    ),
    OnboardingItem(
      title: 'Zéro Transition',
      description: 'Un design moderne qui s’adapte à votre style, avec un support complet du mode sombre.',
      svg: OnboardingSVGs.pro,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _items.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('IGNORER', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _buildPage(_items[index]);
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(
            item.svg,
            height: 250,
          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 50),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryDark,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 20),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicateurs
          Row(
            children: List.generate(
              _items.length,
              (index) => AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppTheme.primary : Colors.grey.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          // Bouton
          ElevatedButton(
            onPressed: () {
              if (_currentPage == _items.length - 1) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              minimumSize: const Size(120, 50),
            ),
            child: Text(
              _currentPage == _items.length - 1 ? 'COMMENCER' : 'SUIVANT',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String svg;
  OnboardingItem({required this.title, required this.description, required this.svg});
}
