// views/invoices/pdf_invoice_api.dart
// ──────────────────────────────────────────────────────────────────────────────
// Service de génération PDF pour les factures TAL Invoice.
// Utilise les packages 'pdf' et 'printing' pour créer un document Premium.
//
// FONCTIONNALITÉS :
//  - Logo entreprise en en-tête ET en filigrane (opacité 5%)
//  - Signature numérique en bas de facture
//  - Nom + Poste du responsable sous la signature
//  - Optimisation mémoire : images redimensionnées avant injection PDF
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/invoice_model.dart';
import '../../models/company_model.dart';
import '../../models/client_model.dart';

class PdfInvoiceApi {
  // ── Redimensionne une image brute en PNG compressé ──────────────────────────
  // Essentiel pour éviter les erreurs Out of Memory sur mobile.
  static Future<Uint8List?> _resizeImage(
    Uint8List bytes, {
    int maxWidth = 300,
    int maxHeight = 300,
    int quality = 75,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      img.dispose();
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ── Charge une image depuis un chemin fichier local ─────────────────────────
  static Future<pw.MemoryImage?> _loadLocalImage(
    String? path, {
    int maxWidth = 300,
    int maxHeight = 300,
    int quality = 80,
  }) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final rawBytes = await file.readAsBytes();
      final resized = await _resizeImage(rawBytes,
          maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);
      return resized != null ? pw.MemoryImage(resized) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> generateAndPrint({
    required InvoiceModel invoice,
    required CompanyModel company,
    required ClientModel client,
  }) async {
    try {
      final pdf = pw.Document(compress: true);

      // ── 1. Chargement + COMPRESSION du logo entreprise ─────────────────────
      // Priorité : logo de l'entreprise (modifiable dans paramètres).
      // Fallback : logo TAL Hub depuis les assets.
      pw.MemoryImage? logoImage = await _loadLocalImage(
        company.logoPath,
        maxWidth: 150,
        maxHeight: 150,
        quality: 70,
      );

      // Si pas de logo entreprise → logo TAL Hub par défaut
      if (logoImage == null) {
        try {
          final talLogoData = await rootBundle.load('assets/images/logo_talhub.png');
          final rawBytes = talLogoData.buffer.asUint8List();
          final resized = await _resizeImage(rawBytes,
              maxWidth: 150, maxHeight: 150, quality: 70);
          if (resized != null) logoImage = pw.MemoryImage(resized);
        } catch (_) {}
      }

      // ── 2. Filigrane : logo de l'entreprise en arrière-plan (opacité 5%) ───
      // On utilise le même logo que l'entreprise, mais à 400x400 pour la page.
      // Si l'entreprise a un logo personnalisé → on l'utilise en filigrane.
      pw.MemoryImage? watermarkImage = await _loadLocalImage(
        company.logoPath,
        maxWidth: 400,
        maxHeight: 400,
        quality: 60,
      );

      // Si pas de logo perso → logo TAL Hub en filigrane
      if (watermarkImage == null) {
        try {
          final talLogoData = await rootBundle.load('assets/images/logo_talhub.png');
          final rawBytes = talLogoData.buffer.asUint8List();
          final resized = await _resizeImage(rawBytes,
              maxWidth: 400, maxHeight: 400, quality: 60);
          if (resized != null) watermarkImage = pw.MemoryImage(resized);
        } catch (_) {}
      }

      // ── 3. Signature numérique du responsable ───────────────────────────────
      final pw.MemoryImage? signatureImage = await _loadLocalImage(
        company.signaturePath,
        maxWidth: 300,
        maxHeight: 120,
        quality: 90,
      );

      final currency = company.currency;
      final dateStr = DateFormat('dd/MM/yyyy').format(invoice.createdAt);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}  •  TAL Invoice',
              style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 7),
            ),
          ),
          header: (context) {
            if (watermarkImage == null) return pw.SizedBox();
            return pw.Container(
              height: 0,
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Positioned(
                    top: 250, // Centrer approximativement sur la page
                    child: pw.Opacity(
                      opacity: 0.18, 
                      child: pw.Image(watermarkImage, width: 600),
                    ),
                  ),
                ],
              ),
            );
          },
          build: (context) => [
            // ── En-tête ────────────────────────────────────────────────────────
            _buildHeaderContent(invoice, company, logoImage, dateStr),

            pw.Divider(thickness: 2, color: PdfColors.indigo900, height: 40),

            // ── Infos Émetteur + Client ────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ÉMETTEUR :',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.Text(company.name,
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.indigo100, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FACTURER À :',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo700)),
                      pw.SizedBox(height: 6),
                      pw.Text(client.name,
                          style: pw.TextStyle(
                              fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      if (client.address != null)
                        pw.Text(client.address!,
                            style: const pw.TextStyle(fontSize: 9)),
                      if (client.phone != null)
                        pw.Text(client.phone!,
                            style: const pw.TextStyle(fontSize: 9)),
                      if (client.email != null)
                        pw.Text(client.email!,
                            style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // ── Tableau des Articles ───────────────────────────────────────────
            pw.TableHelper.fromTextArray(
              headers: ['DESCRIPTION', 'QTÉ', 'PRIX UNIT.', 'TOTAL'],
              data: invoice.items.map((item) {
                final itemCurrency = item.currency == "CDF" ? "FC" : "USD";
                return [
                  item.description,
                  item.quantity.toString(),
                  '${item.unitPrice.toStringAsFixed(2)} $itemCurrency',
                  '${item.total.toStringAsFixed(2)} $itemCurrency',
                ];
              }).toList(),
              border: pw.TableBorder(
                horizontalInside:
                    pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1),
              ),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo900),
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),

            // ── Totaux ────────────────────────────────────────────────────────
            pw.Container(
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.only(top: 20),
              child: pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _buildTotalRow('SOUS-TOTAL', invoice.subtotal, currency),
                    if (invoice.taxRate > 0)
                      _buildTotalRow(
                          'TAXE (${(invoice.taxRate * 100).round()}%)',
                          invoice.taxAmount,
                          currency),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.indigo900,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: _buildTotalRow(
                          'TOTAL GÉNÉRAL', invoice.total, currency,
                          isBold: true, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 40),

            // ── Notes & Signature ─────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Notes (partie gauche)
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (invoice.notes != null) ...[
                        pw.Text('NOTES & CONDITIONS :',
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.notes!,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                // Signature (partie droite)
                pw.Expanded(
                  flex: 1,
                  child: _buildSignatureBlock(
                      signatureImage, company.managerName, company.managerRole),
                ),
              ],
            ),

            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                      "Document généré par TAL Invoice - L'ART DE FACTURER",
                      style: pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey400)),
                  pw.SizedBox(height: 2),
                  pw.Text('tal.communities2025@gmail.com',
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.indigo300,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Facture_${invoice.invoiceNumber}.pdf',
      );
    } on OutOfMemoryError {
      throw Exception(
          'Mémoire insuffisante pour générer le PDF. Réduisez la taille du logo.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Out of Memory') || msg.contains('OutOfMemory')) {
        throw Exception(
            'Mémoire insuffisante pour générer le PDF. Réduisez la taille du logo.');
      }
      rethrow;
    }
  }

  // ── En-tête de la facture (logo + infos société + numéro) ──────────────────
  static pw.Widget _buildHeaderContent(
    InvoiceModel invoice,
    CompanyModel company,
    pw.MemoryImage? logoImage,
    String dateStr,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Container(
                  height: 50,
                  width: 50,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Text(company.name.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900)),
              pw.SizedBox(height: 6),
              pw.Text(company.address,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              pw.Text(company.phone,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              pw.Text(company.email,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              if (company.rccm != null && company.rccm!.isNotEmpty)
                pw.Text('RCCM : ${company.rccm}',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey500)),
              if (company.idNational != null && company.idNational!.isNotEmpty)
                pw.Text('ID NAT : ${company.idNational}',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey500)),
              if (company.registrationCertificate != null &&
                  company.registrationCertificate!.isNotEmpty)
                pw.Text('CERT. : ${company.registrationCertificate}',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey500)),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.indigo900,
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('FACTURE',
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('# ${invoice.invoiceNumber}',
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date : $dateStr',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _getStatusColor(invoice.status),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(invoice.status.label.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Bloc Signature + Nom + Poste du responsable ────────────────────────────
  static pw.Widget _buildSignatureBlock(
    pw.MemoryImage? signatureImage,
    String? managerName,
    String? managerRole,
  ) {
    final hasSignature = signatureImage != null;
    final hasManager = (managerName != null && managerName.isNotEmpty) ||
        (managerRole != null && managerRole.isNotEmpty);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('SIGNATURE & CACHET',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700)),
        pw.SizedBox(height: 8),

        // Image de signature
        if (hasSignature)
          pw.Container(
            height: 60,
            child: pw.Image(signatureImage!, fit: pw.BoxFit.contain),
          )
        else
          pw.SizedBox(height: 40),

        // Ligne de séparation
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),

        // Nom du responsable
        if (managerName != null && managerName.isNotEmpty)
          pw.Text(managerName,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),

        // Poste du responsable
        if (managerRole != null && managerRole.isNotEmpty)
          pw.Text(managerRole,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),

        // Si aucune info → afficher un espace
        if (!hasSignature && !hasManager)
          pw.SizedBox(height: 20),
      ],
    );
  }

  static PdfColor _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColors.green700;
      case InvoiceStatus.sent:
        return PdfColors.orange700;
      case InvoiceStatus.draft:
        return PdfColors.grey700;
    }
  }

  static pw.Widget _buildTotalRow(String label, double amount, String currency,
      {bool isBold = false, PdfColor? color}) {
    final style = pw.TextStyle(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: isBold ? 11 : 9,
      color: color ?? PdfColors.black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('${amount.toStringAsFixed(2)} $currency', style: style),
        ],
      ),
    );
  }

  /// Imprime toutes les factures (6 par page A4)
  static Future<void> generateBulkInvoices({
    required List<InvoiceModel> invoices,
    required CompanyModel company,
    required List<ClientModel> allClients,
  }) async {
    final pdf = pw.Document();
    
    // Charger le logo
    final logoImage = company.logoPath != null && File(company.logoPath!).existsSync()
        ? pw.MemoryImage(File(company.logoPath!).readAsBytesSync())
        : null;

    // Découper par paquets de 6
    for (var i = 0; i < invoices.length; i += 6) {
      final chunk = invoices.skip(i).take(6).toList();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Stack(
            children: [
              if (logoImage != null)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.12, 
                      child: pw.Image(logoImage, width: 450),
                    ),
                  ),
                ),
              pw.GridView(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                children: chunk.map((inv) {
                  final client = allClients.firstWhere((c) => c.id == inv.clientId, 
                      orElse: () => ClientModel(name: 'Client inconnu', email: '', phone: '', address: '', createdAt: DateTime.now()));
                  return _buildMiniInvoice(inv, company, client, logoImage);
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildMiniInvoice(InvoiceModel inv, CompanyModel company, ClientModel client, pw.MemoryImage? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(5),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logo != null) pw.Image(logo, width: 30, height: 30),
              pw.Text(inv.invoiceNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text('Client: ${client.name}', style: const pw.TextStyle(fontSize: 7)),
          pw.Text('Date: ${inv.createdAt.toLocal().toString().split(" ")[0]}', style: const pw.TextStyle(fontSize: 7)),
          pw.Divider(height: 8, thickness: 0.5),
          ...inv.items.take(3).map((it) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(it.description, style: const pw.TextStyle(fontSize: 6), overflow: pw.TextOverflow.clip)),
                pw.Text('${it.total.toStringAsFixed(2)} ${it.currency == "CDF" ? "FC" : "USD"}', 
                    style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
              ],
            ))),
          if (inv.items.length > 3) pw.Text('...', style: const pw.TextStyle(fontSize: 6)),
          pw.Spacer(),
          pw.Divider(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              pw.Text('${inv.total.toStringAsFixed(2)} ${company.currency}', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.indigo900)),
            ],
          ),
        ],
      ),
    );
  }
}
