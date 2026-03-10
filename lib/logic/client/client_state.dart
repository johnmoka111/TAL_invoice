// logic/client/client_state.dart
// États du ClientBloc

import 'package:equatable/equatable.dart';
import '../../models/client_model.dart';

abstract class ClientState extends Equatable {
  const ClientState();
  @override
  List<Object?> get props => [];
}

class ClientInitial extends ClientState {
  const ClientInitial();
}

class ClientLoading extends ClientState {
  const ClientLoading();
}

/// Liste chargée avec succès
class ClientLoaded extends ClientState {
  final List<ClientModel> clients;
  const ClientLoaded(this.clients);
  @override
  List<Object?> get props => [clients];
}

/// Opération (Add/Update/Delete) réussie — liste mise à jour incluse
class ClientOperationSuccess extends ClientState {
  final String message;
  final List<ClientModel> clients;
  const ClientOperationSuccess({required this.message, required this.clients});
  @override
  List<Object?> get props => [message, clients];
}

class ClientError extends ClientState {
  final String message;
  const ClientError(this.message);
  @override
  List<Object?> get props => [message];
}
