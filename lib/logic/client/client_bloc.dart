// logic/client/client_bloc.dart
// ──────────────────────────────────────────────────────────────────────────────
// ClientBloc — Gestion CRUD des clients
//
// Flux de données:
//   UI (ClientListPage / ClientFormPage)
//     → ClientEvent
//       → ClientBloc
//         → DatabaseHelper.insertClient / getAllClients / updateClient / deleteClient
//           → ClientState émis → Rebuild UI
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import 'client_event.dart';
import 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final DatabaseHelper _db;

  ClientBloc({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        super(const ClientInitial()) {
    on<LoadClients>(_onLoadClients);
    on<SearchClients>(_onSearchClients);
    on<AddClient>(_onAddClient);
    on<UpdateClient>(_onUpdateClient);
    on<DeleteClient>(_onDeleteClient);
  }

  // ── Handler: LoadClients ─────────────────────────────────────────────────────
  Future<void> _onLoadClients(
    LoadClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    try {
      final clients = await _db.getAllClients();
      emit(ClientLoaded(clients));
    } catch (e) {
      emit(ClientError('Erreur de chargement: ${e.toString()}'));
    }
  }

  // ── Handler: SearchClients ───────────────────────────────────────────────────
  Future<void> _onSearchClients(
    SearchClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    try {
      final clients = event.query.trim().isEmpty
          ? await _db.getAllClients()
          : await _db.searchClients(event.query.trim());
      emit(ClientLoaded(clients));
    } catch (e) {
      emit(ClientError('Erreur de recherche: ${e.toString()}'));
    }
  }

  // ── Handler: AddClient ───────────────────────────────────────────────────────
  /// Insère le client, puis recharge la liste complète pour maintenir la
  /// cohérence entre le state et la DB.
  Future<void> _onAddClient(
    AddClient event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    try {
      await _db.insertClient(event.client);
      final updatedList = await _db.getAllClients();
      emit(ClientOperationSuccess(
        message: 'Client ajouté avec succès',
        clients: updatedList,
      ));
    } catch (e) {
      emit(ClientError('Erreur d\'ajout: ${e.toString()}'));
    }
  }

  // ── Handler: UpdateClient ────────────────────────────────────────────────────
  Future<void> _onUpdateClient(
    UpdateClient event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    try {
      await _db.updateClient(event.client);
      final updatedList = await _db.getAllClients();
      emit(ClientOperationSuccess(
        message: 'Client mis à jour',
        clients: updatedList,
      ));
    } catch (e) {
      emit(ClientError('Erreur de mise à jour: ${e.toString()}'));
    }
  }

  // ── Handler: DeleteClient ────────────────────────────────────────────────────
  /// Supprime le client. L'opération peut échouer si des factures lui
  /// sont associées (FK RESTRICT dans SQLite).
  Future<void> _onDeleteClient(
    DeleteClient event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    try {
      await _db.deleteClient(event.clientId);
      final updatedList = await _db.getAllClients();
      emit(ClientOperationSuccess(
        message: 'Client supprimé',
        clients: updatedList,
      ));
    } catch (e) {
      // Cas typique: contrainte FK — factures associées existent encore
      emit(ClientError(
          'Impossible de supprimer: ce client a des factures associées.'));
    }
  }
}
