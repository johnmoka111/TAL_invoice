// logic/invoice/invoice_state.dart
// États du InvoiceBloc

import 'package:equatable/equatable.dart';
import '../../models/invoice_model.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceModel> invoices;
  final InvoiceStatus? activeFilter;
  const InvoiceLoaded(this.invoices, {this.activeFilter});
  @override
  List<Object?> get props => [invoices, activeFilter];
}

class InvoiceOperationSuccess extends InvoiceState {
  final String message;
  final List<InvoiceModel> invoices;
  const InvoiceOperationSuccess({required this.message, required this.invoices});
  @override
  List<Object?> get props => [message, invoices];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}
