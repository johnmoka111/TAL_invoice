import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';
import 'data/database_helper.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/client/client_bloc.dart';
import 'logic/invoice/invoice_bloc.dart';
import 'logic/theme/theme_cubit.dart';
import 'views/shared/app_theme.dart';

void main() async {
  // Garantit que les bindings Flutter sont initialisés avant de lancer l'app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de la localisation pour Bukavu (fr_FR)
  await initializeDateFormatting('fr_FR', null);

  final dbHelper = DatabaseHelper.instance;

  // On tente d'initialiser la DB mais on ne bloque pas l'application
  // si on est sur Web (sqflite non supporté nativement)
  if (!kIsWeb) {
    try {
      await dbHelper.database;
    } catch (e) {
      debugPrint("Erreur initialisation DB: $e");
    }
  }

  runApp(TALInvoiceApp(dbHelper: dbHelper));
}

class TALInvoiceApp extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const TALInvoiceApp({super.key, required this.dbHelper});

  @override
  State<TALInvoiceApp> createState() => _TALInvoiceAppState();
}

class _TALInvoiceAppState extends State<TALInvoiceApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  Widget build(BuildContext context) {
    // ── Injection des BLoC au sommet de l'arborescence ────────────────────────
    // Cela permet d'accéder aux données (Clients, Factures, Profil) de n'importe
    // quel écran dans l'application.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc(db: widget.dbHelper)),
        BlocProvider(create: (context) => ClientBloc(db: widget.dbHelper)),
        BlocProvider(create: (context) => InvoiceBloc(db: widget.dbHelper)),
        BlocProvider(create: (context) => ThemeCubit()), // Theme Support
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'TAL Invoice',
            debugShowCheckedModeBanner: false,

            // Configuration du Theme Indigo/Blanc avec support Dark Mode
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            // Configuration du routage avec go_router
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
