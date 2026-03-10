import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil Développeur'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // ── AVATAR SECTION ────────────────────────────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withAlpha(50), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 75,
                      backgroundImage: AssetImage('assets/images/john.jpg'),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                  ).animate().fadeIn(delay: 600.ms).scale(),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'JOHN MOKA',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
              const Text(
                'CEO & PASSIONNÉ TECH',
                style: TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 2),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),

              // ── BIO SECTION ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    if (!isDark) BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Vision & Technologie',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Passionné par le développement web, mobile et les nouvelles technologies. '
                      'En tant que CEO de TAL HUB, je m\'efforce de créer des solutions digitales '
                      'qui répondent aux besoins réels de notre communauté à Bukavu et au-delà. '
                      'TAL Invoice est le fruit de cette ambition : simplifier la gestion '
                      'pour les entrepreneurs locaux avec une approche moderne et efficace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.7, color: isDark ? Colors.white70 : Colors.black87, fontSize: 15),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 48),

              // ── HIGHLIGHTS ────────────────────────────────────────────────
              _sectionTitle('POINTS FORTS', isDark),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHighlight('TAL Hub', 'Leadership', Icons.hub_rounded),
                  _buildHighlight('Bukavu', 'Local Dev', Icons.location_city_rounded),
                  _buildHighlight('Flutter', 'Mobile', Icons.bolt_rounded),
                ],
              ),

              const SizedBox(height: 48),

              // ── SOCIAL LINKS ────────────────────────────────────────────────
              _sectionTitle('RÉSEAUX & CONTACTS', isDark),
              const SizedBox(height: 24),
              _buildSocialGrid(),
              
              const SizedBox(height: 60),

              // ── FOOTER BRANDING ─────────────────────────────────────
              Text(
                'TAL Hub Community'.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12, color: Colors.grey),
              ).animate().shimmer(delay: 2.seconds),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset('assets/images/logo_talhub.png', width: 70, height: 70, fit: BoxFit.cover),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlight(String label, String sub, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), shape: BoxShape.circle),
          child: Icon(icon, color: AppTheme.primary, size: 28),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildSocialGrid() {
    final socials = [
      _SocialItem(Icons.business_center_rounded, 'ENTREPRISE', 'mailto:tal.communities2025@gmail.com', const Color(0xFF1A237E)),
      _SocialItem(Icons.alternate_email_rounded, ' John Moka', 'mailto:johnmoka2024@gmail.com', Colors.redAccent),
      _SocialItem(Icons.phone_android_rounded, 'WHATSAPP', 'https://wa.me/243981430687', const Color(0xFF25D366)),
      _SocialItem(Icons.facebook_rounded, 'FACEBOOK', 'https://www.facebook.com/profile.php?id=61575994382181', const Color(0xFF1877F2)),
      _SocialItem(Icons.link_rounded, 'LINKEDIN', 'https://www.linkedin.com/in/global-tech-and-art-company-5bb707362', const Color(0xFF0077B5)),
      _SocialItem(Icons.share_rounded, 'X (TWITTER)', 'https://x.com/JohnMoka2024', Colors.black87),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.3,
      ),
      itemCount: socials.length,
      itemBuilder: (ctx, i) {
        final s = socials[i];
        return InkWell(
          onTap: () => _launchURL(s.url),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: s.color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.color.withAlpha(40), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                  child: Icon(s.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: s.color.withAlpha(200),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 40, height: 1, color: AppTheme.primary.withAlpha(100)),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Container(width: 40, height: 1, color: AppTheme.primary.withAlpha(100)),
      ],
    );
  }
}

class _SocialItem {
  final IconData icon;
  final String label;
  final String url;
  final Color color;
  _SocialItem(this.icon, this.label, this.url, this.color);
}
