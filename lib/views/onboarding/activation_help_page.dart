// views/onboarding/activation_help_page.dart
// ──────────────────────────────────────────────────────────────────────────────
// Page d'aide et contact développeur pour l'activation.
// Affichée après plusieurs tentatives infructueuses.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/app_theme.dart';

class ActivationHelpPage extends StatelessWidget {
  const ActivationHelpPage({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Besoin d\'aide ?'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ── LOGO TAL COMMUNITIES ──────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/logo_talhub.png', 
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            const Text(
              'TAL COMMUNITIES',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 40),

            // ── CONTACT DEVELOPPEUR ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withAlpha(5),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CONTACTEZ LE DÉVELOPPEUR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Photo de John Moka
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/john.jpg'),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(),

                    const SizedBox(height: 16),

                    const Text(
                      'JOHN MOKA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const Text(
                      'Développeur Principal & CEO',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Actions de contact
                    _buildContactButton(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Nous contacter sur WhatsApp',
                      color: const Color(0xFF25D366),
                      onPressed: () => _launchURL('https://wa.me/243981430687'),
                    ).animate().fadeIn(delay: 600.ms).slideX(),

                    const SizedBox(height: 12),

                    _buildContactButton(
                      icon: Icons.alternate_email_rounded,
                      label: 'Envoyer un Email',
                      color: AppTheme.primary,
                      onPressed: () => _launchURL('mailto:johnmoka2024@gmail.com'),
                    ).animate().fadeIn(delay: 800.ms).slideX(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Votre clé d\'activation est unique et liée à votre licence. Si vous ne l\'avez pas reçue, veuillez contacter notre équipe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
    );
  }
}
