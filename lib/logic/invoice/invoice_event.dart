// logic/invoice/invoice_event.dart
// Événements du InvoiceBloc

import 'package:equatable/equatable.dart';
import '../../models/invoice_model.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {
  const LoadInvoices();
}

class FilterInvoices extends InvoiceEvent {
  final InvoiceStatus? status; // null = toutes
  const FilterInvoices({this.status});
  @override
  List<Object?> get props => [status];
}

class CreateInvoice extends InvoiceEvent {
  final InvoiceModel invoice;
  const CreateInvoice(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class UpdateInvoice extends InvoiceEvent {
  final InvoiceModel invoice;
  const UpdateInvoice(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class DeleteInvoice extends InvoiceEvent {
  final int invoiceId;
  const DeleteInvoice(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class ChangeInvoiceStatus extends InvoiceEvent {
  final int invoiceId;
  final InvoiceStatus newStatus;
  const ChangeInvoiceStatus(this.invoiceId, this.newStatus);
  @override
  List<Object?> get props => [invoiceId, newStatus];
}
