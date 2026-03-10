// logic/auth/auth_bloc.dart
// ──────────────────────────────────────────────────────────────────────────────
// AuthBloc — Gestion du profil entreprise
//
// Flux de données:
//   UI (SplashScreen/ProfileSetupPage)
//     → AuthEvent (LoadCompany / SaveCompany)
//       → AuthBloc (logique métier)
//         → DatabaseHelper (DB SQLite)
//           → AuthState émis → UI réagit
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import '../../models/company_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DatabaseHelper _db;

  AuthBloc({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        super(const CompanyInitial()) {
    // Enregistrement des handlers d'événements
    on<LoadCompany>(_onLoadCompany);
    on<SaveCompany>(_onSaveCompany);
    on<ResetApp>(_onResetApp);
  }

  // ── Handler: ResetApp ────────────────────────────────────────────────────────
  Future<void> _onResetApp(
    ResetApp event,
    Emitter<AuthState> emit,
  ) async {
    emit(const CompanySaving()); // On réutilise CompanySaving pour l'état d'attente
    try {
      await _db.resetDatabase();
      emit(const CompanyNotFound());
    } catch (e) {
      emit(CompanyError('Réinitialisation échouée: ${e.toString()}'));
    }
  }

  // ── Handler: LoadCompany ─────────────────────────────────────────────────────
  /// Vérifie en DB si un profil entreprise existe.
  /// → CompanyLoaded si trouvé, CompanyNotFound sinon.
  Future<void> _onLoadCompany(
    LoadCompany event,
    Emitter<AuthState> emit,
  ) async {
    emit(const CompanyLoading());
    try {
      final company = await _db.getCompany();
      if (company != null) {
        emit(CompanyLoaded(company));
      } else {
        emit(const CompanyNotFound());
      }
    } catch (e) {
      emit(CompanyError('Erreur de chargement: ${e.toString()}'));
    }
  }

  // ── Handler: SaveCompany ─────────────────────────────────────────────────────
  /// Sauvegarde le profil entreprise.
  /// Si l'entreprise a déjà un id → UPDATE, sinon → INSERT.
  Future<void> _onSaveCompany(
    SaveCompany event,
    Emitter<AuthState> emit,
  ) async {
    emit(const CompanySaving());
    try {
      final CompanyModel company;
      if (event.company.id != null) {
        // Mise à jour d'un profil existant
        await _db.updateCompany(event.company);
        company = event.company;
      } else {
        // Première création du profil
        final id = await _db.saveCompany(event.company);
        company = event.company.copyWith(id: id);
      }
      emit(CompanySaved(company));
      emit(CompanyLoaded(company));
    } catch (e) {
      emit(CompanyError('Erreur de sauvegarde: ${e.toString()}'));
    }
  }
}
