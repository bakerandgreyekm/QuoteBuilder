import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/project.dart';
import '../models/line_item.dart';
import '../theme.dart';
import '../utils.dart';

// ---------------------------------------------------------------------------
// PNG — render QuoteDocumentWidget off-screen via OverlayEntry and capture
// ---------------------------------------------------------------------------

Future<Uint8List?> _loadLogo() async {
  try {
    return (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

Future<Uint8List> captureQuoteAsPng(
  OverlayState overlay, {
  required Project project,
  required List<String> systems,
  required List<LineItem> items,
}) async {
  final logoBytes = await _loadLogo();
  final repaintKey = GlobalKey();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -9999,
      top: 0,
      width: 390,
      child: Material(
        color: Colors.white,
        child: RepaintBoundary(
          key: repaintKey,
          child: QuoteDocumentWidget(
            project: project,
            systems: systems,
            items: items,
            logoBytes: logoBytes,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  await Future.delayed(const Duration(milliseconds: 300));

  try {
    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}

// ---------------------------------------------------------------------------
// PDF — build document using the pdf package
// ---------------------------------------------------------------------------

Future<Uint8List> generateQuotePdf({
  required Project project,
  required List<String> systems,
  required List<LineItem> items,
}) async {
  final logoBytes = await _loadLogo();
  final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

  final totalExGST = items.fold(0.0, (s, i) => s + i.amount);
  final gst = totalExGST * 0.18;
  final grandTotal = totalExGST + gst;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      build: (ctx) => [
        _pdfHeader(logo, project),
        pw.SizedBox(height: 14),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 12),
        _pdfClientInfo(project),
        pw.SizedBox(height: 18),
        _pdfItemsTable(systems, items),
        pw.SizedBox(height: 18),
        _pdfTotals(totalExGST, gst, grandTotal),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _pdfHeader(pw.MemoryImage? logo, Project project) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (logo != null) pw.Image(logo, width: 100) else pw.SizedBox(width: 100),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('QUOTATION',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Ref: ${project.refNumber}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          pw.Text(_pdfDate(DateTime.now()),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        ],
      ),
    ],
  );
}

pw.Widget _pdfClientInfo(Project project) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('CLIENT',
          style: const pw.TextStyle(
              fontSize: 9, color: PdfColors.grey500, letterSpacing: 1)),
      pw.SizedBox(height: 4),
      pw.Text(project.clientName,
          style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.Text(project.name,
          style: const pw.TextStyle(fontSize: 12)),
      pw.Text(project.location,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
    ],
  );
}

pw.Widget _pdfItemsTable(List<String> systems, List<LineItem> items) {
  final rows = <pw.TableRow>[];

  rows.add(pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
    children: [
      _th('#'),
      _th('Product'),
      _th('Qty', right: true),
      _th('Unit'),
      _th('Rate', right: true),
      _th('Amount', right: true),
    ],
  ));

  int sl = 0;
  for (final sys in systems) {
    final sysItems = items.where((i) => i.systemType == sys).toList();
    if (sysItems.isEmpty) continue;

    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _sysCell(''),
        _sysCell(sys.toUpperCase()),
        _sysCell(''),
        _sysCell(''),
        _sysCell(''),
        _sysCell(''),
      ],
    ));

    for (final item in sysItems) {
      sl++;
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          border: const pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
        ),
        children: [
          _td('$sl'),
          _td('${item.productName}\n${item.brand}', fontSize: 10),
          _td('${item.quantity}', right: true),
          _td(item.unit),
          _td(formatINR(item.rate), right: true),
          _td(formatINR(item.amount), right: true),
        ],
      ));
    }
  }

  return pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(22),
      1: pw.FlexColumnWidth(),
      2: pw.FixedColumnWidth(28),
      3: pw.FixedColumnWidth(36),
      4: pw.FixedColumnWidth(72),
      5: pw.FixedColumnWidth(78),
    },
    children: rows,
  );
}

pw.Widget _th(String text, {bool right = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );

pw.Widget _td(String text, {bool right = false, double fontSize = 11}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(fontSize: fontSize)),
    );

pw.Widget _sysCell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700)),
    );

pw.Widget _pdfTotals(double exGST, double gst, double grandTotal) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      _pdfTotalRow('Total (ex. GST)', formatINR(exGST)),
      pw.Divider(color: PdfColors.grey200, thickness: 0.5),
      _pdfTotalRow('GST @ 18%', formatINR(gst)),
      pw.Divider(color: PdfColors.grey400, thickness: 0.8),
      _pdfTotalRow('Grand Total', formatINR(grandTotal),
          bold: true, large: true),
    ],
  );
}

pw.Widget _pdfTotalRow(String label, String value,
    {bool bold = false, bool large = false}) {
  final size = large ? 14.0 : 11.0;
  final weight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: size, fontWeight: weight)),
        pw.SizedBox(width: 20),
        pw.SizedBox(
          width: 100,
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: size, fontWeight: weight)),
        ),
      ],
    ),
  );
}

String _pdfDate(DateTime dt) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}

// ---------------------------------------------------------------------------
// Flutter widget rendered off-screen for PNG capture
// ---------------------------------------------------------------------------

class QuoteDocumentWidget extends StatelessWidget {
  final Project project;
  final List<String> systems;
  final List<LineItem> items;
  final Uint8List? logoBytes;

  const QuoteDocumentWidget({
    super.key,
    required this.project,
    required this.systems,
    required this.items,
    required this.logoBytes,
  });

  @override
  Widget build(BuildContext context) {
    final totalExGST = items.fold(0.0, (s, i) => s + i.amount);
    final gst = totalExGST * 0.18;
    final grandTotal = totalExGST + gst;

    int sl = 0;
    final rows = <Widget>[];
    for (final sys in systems) {
      final sysItems = items.where((i) => i.systemType == sys).toList();
      if (sysItems.isEmpty) continue;
      rows.add(_sysHeader(sys));
      for (final item in sysItems) {
        sl++;
        rows.add(_itemRow(sl, item));
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (logoBytes != null) Image.memory(logoBytes!, width: 90) else const SizedBox(width: 90),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('QUOTATION',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827))),
                  const SizedBox(height: 3),
                  Text('Ref: ${project.refNumber}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF6B7280))),
                  Text(_docDate(DateTime.now()),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          // Client
          Text('CLIENT',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.8)),
          const SizedBox(height: 5),
          Text(project.clientName,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827))),
          Text(project.name,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF374151))),
          Text(project.location,
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          // Table header
          Container(
            color: const Color(0xFFF9FAFB),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 24,
                    child: Text('#', style: _headerStyle())),
                Expanded(
                    child: Text('Product', style: _headerStyle())),
                SizedBox(
                    width: 30,
                    child: Text('Qty',
                        style: _headerStyle(),
                        textAlign: TextAlign.right)),
                SizedBox(
                    width: 38,
                    child: Text('Unit',
                        style: _headerStyle(),
                        textAlign: TextAlign.center)),
                SizedBox(
                    width: 74,
                    child: Text('Rate',
                        style: _headerStyle(),
                        textAlign: TextAlign.right)),
                SizedBox(
                    width: 78,
                    child: Text('Amount',
                        style: _headerStyle(),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...rows,
          const SizedBox(height: 16),
          // Totals
          _totalRow('Total (ex. GST)', formatINR(totalExGST)),
          const Divider(color: Color(0xFFE5E7EB), height: 16),
          _totalRow('GST @ 18%', formatINR(gst)),
          const Divider(color: Color(0xFF9CA3AF), height: 16),
          _totalRow('Grand Total', formatINR(grandTotal), bold: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sysHeader(String sys) => Container(
        color: const Color(0xFFF3F4F6),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(sys.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.6)),
      );

  Widget _itemRow(int sl, LineItem item) => Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: Color(0xFFF3F4F6), width: 0.5)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 24,
                child: Text('$sl',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF)))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF111827))),
                  Text(item.brand,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF6B7280))),
                ],
              ),
            ),
            SizedBox(
                width: 30,
                child: Text('${item.quantity}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF374151)),
                    textAlign: TextAlign.right)),
            SizedBox(
                width: 38,
                child: Text(item.unit,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF374151)),
                    textAlign: TextAlign.center)),
            SizedBox(
                width: 74,
                child: Text(formatINR(item.rate),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF374151)),
                    textAlign: TextAlign.right)),
            SizedBox(
                width: 78,
                child: Text(formatINR(item.amount),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827)),
                    textAlign: TextAlign.right)),
          ],
        ),
      );

  Widget _totalRow(String label, String value, {bool bold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: bold ? 14 : 12,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280))),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: bold ? 16 : 12,
                    fontWeight: FontWeight.w700,
                    color: bold
                        ? AppColors.primary
                        : const Color(0xFF111827))),
          ),
        ],
      );

  TextStyle _headerStyle() => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6B7280));

  String _docDate(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}
