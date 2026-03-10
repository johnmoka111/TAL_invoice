// logic/auth/auth_state.dart
// États du AuthBloc

import 'package:equatable/equatable.dart';
import '../../models/company_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// État initial, avant toute vérification
class CompanyInitial extends AuthState {
  const CompanyInitial();
}

/// Chargement en cours (vérification DB)
class CompanyLoading extends AuthState {
  const CompanyLoading();
}

/// Profil trouvé et chargé
class CompanyLoaded extends AuthState {
  final CompanyModel company;
  const CompanyLoaded(this.company);
  @override
  List<Object?> get props => [company];
}

/// Aucun profil trouvé → rediriger vers ProfileSetupPage
class CompanyNotFound extends AuthState {
  const CompanyNotFound();
}

/// Sauvegarde en cours
class CompanySaving extends AuthState {
  const CompanySaving();
}

/// Sauvegarde réussie
class CompanySaved extends AuthState {
  final CompanyModel company;
  const CompanySaved(this.company);
  @override
  List<Object?> get props => [company];
}

/// Erreur survenue
class CompanyError extends AuthState {
  final String message;
  const CompanyError(this.message);
  @override
  List<Object?> get props => [message];
}
