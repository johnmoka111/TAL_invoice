// views/clients/client_form_page.dart
// Formulaire d'ajout / modification d'un client.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/database_helper.dart';
import '../../logic/client/client_bloc.dart';
import '../../logic/client/client_event.dart';
import '../../logic/client/client_state.dart';
import '../../models/client_model.dart';
import '../shared/app_theme.dart';
import '../shared/custom_text_field.dart';
import '../shared/primary_button.dart';

class ClientFormPage extends StatefulWidget {
  final int? clientId; // null = création

  const ClientFormPage({super.key, this.clientId});

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isLoading = false;
  ClientModel? _existingClient;

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) _loadClient();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);
    final client =
        await DatabaseHelper.instance.getClientById(widget.clientId!);
    if (client != null && mounted) {
      setState(() {
        _existingClient = client;
        _nameCtrl.text = client.name;
        _emailCtrl.text = client.email ?? '';
        _phoneCtrl.text = client.phone ?? '';
        _addressCtrl.text = client.address ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final client = ClientModel(
      id: _existingClient?.id,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      createdAt: _existingClient?.createdAt ?? DateTime.now(),
    );

    if (_existingClient != null) {
      context.read<ClientBloc>().add(UpdateClient(client));
    } else {
      context.read<ClientBloc>().add(AddClient(client));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientBloc, ClientState>(
      listener: (context, state) {
        if (state is ClientOperationSuccess) {
          context.pop();
        } else if (state is ClientError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.error,
          ));
        }
      },
      builder: (context, state) {
        final isSaving = state is ClientLoading;
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
                _existingClient != null ? 'Modifier le client' : 'Nouveau client'),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingMD),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _nameCtrl,
                          label: 'Nom complet *',
                          prefixIcon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Le nom est requis'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$')
                                  .hasMatch(v)) {
                                return 'Email invalide';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _phoneCtrl,
                          label: 'Téléphone',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _addressCtrl,
                          label: 'Adresse',
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: _existingClient != null
                              ? 'Modifier'
                              : 'Ajouter le client',
                          icon: Icons.check,
                          isLoading: isSaving,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
