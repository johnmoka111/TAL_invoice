// logic/client/client_event.dart
// Événements du ClientBloc — CRUD clients

import 'package:equatable/equatable.dart';
import '../../models/client_model.dart';

abstract class ClientEvent extends Equatable {
  const ClientEvent();
  @override
  List<Object?> get props => [];
}

/// Chargement de la liste complète des clients
class LoadClients extends ClientEvent {
  const LoadClients();
}

/// Recherche par nom
class SearchClients extends ClientEvent {
  final String query;
  const SearchClients(this.query);
  @override
  List<Object?> get props => [query];
}

/// Création d'un nouveau client
class AddClient extends ClientEvent {
  final ClientModel client;
  const AddClient(this.client);
  @override
  List<Object?> get props => [client];
}

/// Mise à jour d'un client existant
class UpdateClient extends ClientEvent {
  final ClientModel client;
  const UpdateClient(this.client);
  @override
  List<Object?> get props => [client];
}

/// Suppression d'un client
class DeleteClient extends ClientEvent {
  final int clientId;
  const DeleteClient(this.clientId);
  @override
  List<Object?> get props => [clientId];
}
