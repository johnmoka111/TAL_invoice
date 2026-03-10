// logic/auth/auth_event.dart
// Événements du AuthBloc — gestion du profil entreprise

import 'package:equatable/equatable.dart';
import '../../models/company_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Demande le chargement du profil entreprise depuis la DB au démarrage.
class LoadCompany extends AuthEvent {
  const LoadCompany();
}

/// Demande la sauvegarde (insert ou update) du profil entreprise.
class SaveCompany extends AuthEvent {
  final CompanyModel company;
  const SaveCompany(this.company);
  @override
  List<Object?> get props => [company];
}

/// Demande la réinitialisation complète de l'application (Factory Reset).
class ResetApp extends AuthEvent {
  const ResetApp();
}
