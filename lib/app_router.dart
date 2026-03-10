// app_router.dart
// ──────────────────────────────────────────────────────────────────────────────
// Configuration de la navigation avec go_router.
//
// Flux d'initialisation:
//   SplashScreen → vérifie DB → ProfileSetupPage (si aucun profil)
//                             → DashboardPage (si profil existant)
// ──────────────────────────────────────────────────────────────────────────────

import 'package:go_router/go_router.dart';
import 'views/splash/splash_screen.dart';
import 'views/setup/profile_setup_page.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/clients/client_list_page.dart';
import 'views/clients/client_form_page.dart';
import 'views/invoices/invoice_list_page.dart';
import 'views/invoices/invoice_create_page.dart';
import 'views/invoices/invoice_detail_page.dart';
import 'views/settings/settings_page.dart';
import 'views/settings/about_page.dart';
import 'views/onboarding/onboarding_page.dart';

/// Constantes des routes pour éviter les chaînes magiques
class AppRoutes {
  static const splash = '/';
  static const setup = '/setup';
  static const dashboard = '/dashboard';
  static const clients = '/clients';
  static const clientNew = '/clients/new';
  static const clientEdit = '/clients/:id/edit';
  static const invoices = '/invoices';
  static const invoiceNew = '/invoices/new';
  static const invoiceDetail = '/invoices/:id';
  static const settings = '/settings';
  static const about = '/settings/about';
  static const onboarding = '/onboarding';

  // Helpers pour les routes paramétrées
  static String clientEditPath(int id) => '/clients/$id/edit';
  static String invoiceDetailPath(int id) => '/invoices/$id';
}

/// Création du routeur principal de l'application.
/// [redirect] est la garde centrale qui vérifie si un profil entreprise existe.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // ── Setup profil ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const ProfileSetupPage(),
      ),

      // ── Dashboard ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),

      // ── Clients ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.clients,
        builder: (context, state) => const ClientListPage(),
      ),
      GoRoute(
        path: AppRoutes.clientNew,
        builder: (context, state) => const ClientFormPage(),
      ),
      GoRoute(
        path: AppRoutes.clientEdit,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ClientFormPage(clientId: id);
        },
      ),

      // ── Factures ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.invoices,
        builder: (context, state) => const InvoiceListPage(),
      ),
      GoRoute(
        path: AppRoutes.invoiceNew,
        builder: (context, state) => const InvoiceCreatePage(),
      ),
      GoRoute(
        path: AppRoutes.invoiceDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InvoiceDetailPage(invoiceId: id);
        },
      ),

      // ── Paramètres ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
}
