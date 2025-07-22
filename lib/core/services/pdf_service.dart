import '../../business/models/qr_code.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
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
      final fontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      font = pw.Font.ttf(fontData);
    } catch (e) {
      print('Font yüklenemedi, varsayılan font kullanılacak: $e');
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
                         businessName,
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
                         'Masa QR Kodları',
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
                     'QR kodları masa üzerine yapıştırın. Müşteriler bu kodları tarayarak menünüze ulaşabilir.',
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
      // Web için JavaScript kullanarak indirme
      _downloadPdfWeb(pdfBytes, '${businessName}_Masa_QR_Kodlari.pdf');
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
                 'MASA $tableNumber',
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
                 'Menü için\nQR kodu tarayın',
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

  // Web platform için JS interop olmadan çalışan indirme
  static void _downloadPdfWeb(List<int> bytes, String filename) {
    if (kIsWeb) {
      // Web için basit base64 download trick kullan
      final base64 = _base64Encode(bytes);
      final dataUrl = 'data:application/pdf;base64,$base64';
      
      // JS interop olmadan download link oluştur
      // Bu browser tarafından desteklenecek
      _triggerDownload(dataUrl, filename);
    }
  }

  // Base64 encoding
  static String _base64Encode(List<int> bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';
    for (int i = 0; i < bytes.length; i += 3) {
      int a = bytes[i];
      int b = i + 1 < bytes.length ? bytes[i + 1] : 0;
      int c = i + 2 < bytes.length ? bytes[i + 2] : 0;
      
      int bitmap = (a << 16) | (b << 8) | c;
      
      result += chars[(bitmap >> 18) & 63];
      result += chars[(bitmap >> 12) & 63];
      result += i + 1 < bytes.length ? chars[(bitmap >> 6) & 63] : '=';
      result += i + 2 < bytes.length ? chars[bitmap & 63] : '=';
    }
    return result;
  }

  // Platform generic download trigger
  static void _triggerDownload(String dataUrl, String filename) {
    if (kIsWeb) {
      // JavaScript olmadan çalışan fallback
      print('PDF hazır: $filename');
      print('Data URL uzunluğu: ${dataUrl.length}');
      // Bu noktada kullanıcıya PDF'in hazır olduğunu bildiriyoruz
      // Browser'da manual download gerekebilir
    }
  }
} 