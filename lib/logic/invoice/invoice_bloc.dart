// logic/invoice/invoice_bloc.dart
// ──────────────────────────────────────────────────────────────────────────────
// InvoiceBloc — Gestion CRUD des factures
//
// Flux de données:
//   UI (InvoiceListPage / InvoiceCreatePage)
//     → InvoiceEvent
//       → InvoiceBloc
//         → DatabaseHelper (transaction atomique insert/update)
//           → InvoiceState → UI rebuild
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import '../../models/invoice_model.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final DatabaseHelper _db;

  InvoiceBloc({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        super(const InvoiceInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<FilterInvoices>(_onFilterInvoices);
    on<CreateInvoice>(_onCreateInvoice);
    on<UpdateInvoice>(_onUpdateInvoice);
    on<DeleteInvoice>(_onDeleteInvoice);
    on<ChangeInvoiceStatus>(_onChangeInvoiceStatus);
  }

  // ── Handler: LoadInvoices ────────────────────────────────────────────────────
  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    try {
      final invoices = await _db.getAllInvoices();
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      emit(InvoiceError('Erreur de chargement: ${e.toString()}'));
    }
  }

  // ── Handler: FilterInvoices ──────────────────────────────────────────────────
  /// Filtre la liste en mémoire selon le statut (pas de requête DB supplémentaire).
  Future<void> _onFilterInvoices(
    FilterInvoices event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    try {
      final allInvoices = await _db.getAllInvoices();
      final filtered = event.status == null
          ? allInvoices
          : allInvoices
              .where((inv) => inv.status == event.status)
              .toList();
      emit(InvoiceLoaded(filtered, activeFilter: event.status));
    } catch (e) {
      emit(InvoiceError('Erreur de filtrage: ${e.toString()}'));
    }
  }

  // ── Handler: CreateInvoice ───────────────────────────────────────────────────
  /// Insère en DB via transaction atomique (facture + articles).
  Future<void> _onCreateInvoice(
    CreateInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    try {
      await _db.insertInvoice(event.invoice);
      final updatedList = await _db.getAllInvoices();
      emit(InvoiceOperationSuccess(
        message: 'Facture créée avec succès',
        invoices: updatedList,
      ));
    } catch (e) {
      emit(InvoiceError('Erreur de création: ${e.toString()}'));
    }
  }

  // ── Handler: UpdateInvoice ───────────────────────────────────────────────────
  Future<void> _onUpdateInvoice(
    UpdateInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    try {
      await _db.updateInvoice(event.invoice);
      final updatedList = await _db.getAllInvoices();
      emit(InvoiceOperationSuccess(
        message: 'Facture mise à jour',
        invoices: updatedList,
      ));
    } catch (e) {
      emit(InvoiceError('Erreur de mise à jour: ${e.toString()}'));
    }
  }

  // ── Handler: DeleteInvoice ───────────────────────────────────────────────────
  Future<void> _onDeleteInvoice(
    DeleteInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    try {
      await _db.deleteInvoice(event.invoiceId);
      final updatedList = await _db.getAllInvoices();
      emit(InvoiceOperationSuccess(
        message: 'Facture supprimée',
        invoices: updatedList,
      ));
    } catch (e) {
      emit(InvoiceError('Erreur de suppression: ${e.toString()}'));
    }
  }

  // ── Handler: ChangeInvoiceStatus ─────────────────────────────────────────────
  /// Met à jour uniquement le statut (draft → sent → paid).
  Future<void> _onChangeInvoiceStatus(
    ChangeInvoiceStatus event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    try {
      await _db.updateInvoiceStatus(event.invoiceId, event.newStatus);
      final updatedList = await _db.getAllInvoices();
      emit(InvoiceOperationSuccess(
        message: 'Statut mis à jour: ${event.newStatus.label}',
        invoices: updatedList,
      ));
    } catch (e) {
      emit(InvoiceError('Erreur: ${e.toString()}'));
    }
  }
}
