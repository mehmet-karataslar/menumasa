import '../../business/models/qr_code.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

// Conditional import for web download
import 'pdf_download_stub.dart' if (dart.library.html) 'pdf_download_web.dart';

class PdfService {
  /// Türkçe karakterleri ASCII karşılıklarına çevirir
  static String _sanitizeText(String text) {
    return text
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C');
  }

  /// Downloads table QR codes as a PDF file
  static Future<void> downloadTableQRsPDF({
    required String businessId,
    required String businessName,
    required List<QRCode> tableQRs,
  }) async {
    if (kIsWeb) {
      // Web platform için PDF oluştur ve indir
      await _createAndDownloadPDF(
        businessId: businessId,
        businessName: businessName,
        tableQRs: tableQRs,
      );
    } else {
      // Mobile platform için
      throw UnsupportedError('PDF indirme şu anda sadece web platformunda destekleniyor');
    }
  }

  static Future<void> _createAndDownloadPDF({
    required String businessId,
    required String businessName,
    required List<QRCode> tableQRs,
  }) async {
    // Türkçe karakterler için font yükle
    pw.Font? font;
    try {
      print('🔍 PDF Service: Font yükleme denenecek...');
      final fontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      font = pw.Font.ttf(fontData);
      print('✅ PDF Service: Poppins font başarıyla yüklendi');
    } catch (e) {
      print('❌ PDF Service: Poppins font yüklenemedi: $e');
      // Fallback olarak basit ASCII karakterler kullan
      font = null;
      print('⚠️ PDF Service: Font olmadan devam edilecek (sadece ASCII karakterler)');
    }
    
    final pdf = pw.Document();
    
    // QR kodları 2x3 grid olarak düzenle (sayfa başına 6 QR kod)
    const int qrPerPage = 6;
    const int qrPerRow = 2;
    
    for (int i = 0; i < tableQRs.length; i += qrPerPage) {
      final pageQRs = tableQRs.skip(i).take(qrPerPage).toList();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Başlık
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                                             pw.Text(
                         _sanitizeText(businessName),
                         style: pw.TextStyle(
                           fontSize: 24,
                           fontWeight: pw.FontWeight.bold,
                           color: PdfColors.blue900,
                           font: font,
                         ),
                         textAlign: pw.TextAlign.center,
                       ),
                       pw.SizedBox(height: 8),
                       pw.Text(
                         'Table QR Codes',
                         style: pw.TextStyle(
                           fontSize: 16,
                           color: PdfColors.blue700,
                           font: font,
                         ),
                         textAlign: pw.TextAlign.center,
                       ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                
                                  // QR kodları grid
                  pw.Expanded(
                    child: pw.Column(
                      children: _buildQRGrid(pageQRs, qrPerRow, font: font),
                    ),
                  ),
                
                // Footer
                pw.Container(
                  margin: pw.EdgeInsets.only(top: 20),
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                                     child: pw.Text(
                     'Place QR codes on tables. Customers can scan these codes to access your menu.',
                     style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: font),
                     textAlign: pw.TextAlign.center,
                   ),
                ),
              ],
            );
          },
        ),
      );
    }

    final pdfBytes = await pdf.save();
    
    if (kIsWeb) {
      // Web için indirme
      final sanitizedName = _sanitizeText(businessName);
      PdfDownloadWeb.downloadPdf(Uint8List.fromList(pdfBytes), '${sanitizedName}_Table_QR_Codes.pdf');
    }
  }

  static List<pw.Widget> _buildQRGrid(List<QRCode> qrCodes, int qrPerRow, {pw.Font? font}) {
    final List<pw.Widget> rows = [];
    
    for (int i = 0; i < qrCodes.length; i += qrPerRow) {
      final rowQRs = qrCodes.skip(i).take(qrPerRow).toList();
      
      rows.add(
        pw.Expanded(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: rowQRs.map((qr) => _buildPDFQRCard(qr, font: font)).toList(),
          ),
        ),
      );
      
      if (i + qrPerRow < qrCodes.length) {
        rows.add(pw.SizedBox(height: 20));
      }
    }
    
    return rows;
  }

  static pw.Widget _buildPDFQRCard(QRCode qrCode, {pw.Font? font}) {
    final tableNumber = qrCode.data.tableNumber ?? 1;
    
    return pw.Expanded(
      child: pw.Container(
        margin: pw.EdgeInsets.all(10),
        padding: pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue300, width: 2),
          borderRadius: pw.BorderRadius.circular(15),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            // Masa numarası başlığı
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue600,
                borderRadius: pw.BorderRadius.circular(20),
              ),
                             child: pw.Text(
                 'TABLE $tableNumber',
                 style: pw.TextStyle(
                   fontSize: 16,
                   fontWeight: pw.FontWeight.bold,
                   color: PdfColors.white,
                   font: font,
                 ),
               ),
            ),
            pw.SizedBox(height: 20),
            
            // QR kod
            pw.Container(
              width: 160,
              height: 160,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrCode.url,
                    width: 160,
                    height: 160,
                  ),
                  // QR kodun ortasında masa numarası
                  pw.Container(
                    width: 35,
                    height: 35,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.blue600, width: 2),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '$tableNumber',
                                                 style: pw.TextStyle(
                           fontSize: 14,
                           fontWeight: pw.FontWeight.bold,
                           color: PdfColors.blue900,
                           font: font,
                         ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Alt açıklama
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
                             child: pw.Text(
                 'Scan QR code\nfor menu',
                 style: pw.TextStyle(
                   fontSize: 10,
                   color: PdfColors.grey700,
                   font: font,
                 ),
                 textAlign: pw.TextAlign.center,
               ),
            ),
          ],
        ),
      ),
    );
  }


} 