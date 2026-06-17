import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/project.dart';
import '../models/line_item.dart';
import '../utils.dart';

// ---------------------------------------------------------------------------
// Brand constants — Flutter
// ---------------------------------------------------------------------------

const _kRed = Color(0xFFC1272D);
const _kDark = Color(0xFF1F2937);
const _kGray50 = Color(0xFFF9FAFB);
const _kGray100 = Color(0xFFF3F4F6);
const _kGray200 = Color(0xFFE5E7EB);
const _kGray500 = Color(0xFF6B7280);
const _kText = Color(0xFF374151);

// ---------------------------------------------------------------------------
// Brand constants — PDF
// ---------------------------------------------------------------------------

final _pdfRed = PdfColor.fromHex('#C1272D');
final _pdfDark = PdfColor.fromHex('#1F2937');
final _pdfGray50 = PdfColor.fromHex('#F9FAFB');
final _pdfGray100 = PdfColor.fromHex('#F3F4F6');
final _pdfGray200 = PdfColor.fromHex('#E5E7EB');
final _pdfGray500 = PdfColor.fromHex('#9CA3AF');

// ---------------------------------------------------------------------------
// Company info
// ---------------------------------------------------------------------------

const _kWeb = 'www.bakerandgrey.com';
const _kCorp = 'Corporate: PSRA 81B, Karippilil Lane, Padivattom, Edappally, Kochi - 24';
const _kRegd = 'Regd: VII/1032 E, Baker Square, Pattimattom Junction, Ernakulam - 683 562';
const _kPh = 'Ph: +91 9562 44 99 00 / +91 9562 66 99 00  |  info@bakerandgrey.com';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Future<Uint8List?> _loadLogo() async {
  try {
    return (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

String _fmtDate(DateTime dt) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}

// ---------------------------------------------------------------------------
// PNG — render QuoteDocumentWidget off-screen and capture
// ---------------------------------------------------------------------------

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
      width: 500,
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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

  final regularData = await rootBundle.load('assets/fonts/Inter_18pt-Regular.ttf');
  final boldData = await rootBundle.load('assets/fonts/Inter_18pt-Bold.ttf');
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regularData),
    bold: pw.Font.ttf(boldData),
  );

  final exGST = items.fold(0.0, (s, i) => s + i.amount);
  final gst = exGST * 0.18;
  final grandTotal = exGST + gst;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.fromLTRB(36, 24, 36, 36),
      build: (ctx) => [
        _pdfLetterhead(logo),
        pw.Container(height: 2.5, color: _pdfRed),
        pw.SizedBox(height: 8),
        _pdfTitleBar(),
        _pdfClientInfo(project),
        pw.SizedBox(height: 10),
        _pdfItemsTable(systems, items),
        pw.SizedBox(height: 12),
        _pdfTotals(exGST, gst, grandTotal),
        pw.SizedBox(height: 14),
        _pdfBottomLine(project),
      ],
    ),
  );

  return doc.save();
}

// -- PDF sections --

pw.Widget _pdfLetterhead(pw.MemoryImage? logo) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        logo != null
            ? pw.Image(logo, height: 38)
            : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BAKER & GREY',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold, color: _pdfRed)),
                pw.Text('Technology Solution Integrators',
                    style: pw.TextStyle(fontSize: 8, color: _pdfGray500)),
              ]),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(_kWeb,
                style: pw.TextStyle(
                    fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _pdfRed)),
            pw.SizedBox(height: 2),
            pw.Text(_kCorp, style: pw.TextStyle(fontSize: 7.5, color: _pdfGray500)),
            pw.Text(_kRegd, style: pw.TextStyle(fontSize: 7.5, color: _pdfGray500)),
            pw.Text(_kPh, style: pw.TextStyle(fontSize: 7.5, color: _pdfGray500)),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _pdfTitleBar() => pw.Container(
      width: double.infinity,
      color: _pdfDark,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: pw.Text(
        'BILL OF QUOTES',
        style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 0.5),
      ),
    );

pw.Widget _pdfClientInfo(Project project) => pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
      border: pw.TableBorder.all(color: _pdfGray200, width: 0.5),
      children: [
        pw.TableRow(children: [
          _pdfCCell('Client', project.clientName),
          _pdfCCell('Ref. No.', project.refNumber),
        ]),
        pw.TableRow(children: [
          _pdfCCell('Site', project.location),
          _pdfCCell('Date', _fmtDate(DateTime.now())),
        ]),
      ],
    );

pw.Widget _pdfCCell(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 45,
          child: pw.Text(label,
              style: pw.TextStyle(fontSize: 9, color: _pdfGray500)),
        ),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ]),
    );

pw.Widget _pdfItemsTable(List<String> systems, List<LineItem> items) {
  final rows = <pw.TableRow>[];

  rows.add(pw.TableRow(
    decoration: pw.BoxDecoration(color: _pdfDark),
    children: [
      _pdfTH('No.'),
      _pdfTH('Item Description'),
      _pdfTH('Qty', right: true),
      _pdfTH('Unit'),
      _pdfTH('Rate (₹)', right: true),
      _pdfTH('Amount (₹)', right: true),
    ],
  ));

  int sl = 0;

  void addSectionHeader(String label) {
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(color: _pdfGray100),
      children: [
        pw.SizedBox(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Row(children: [
            pw.Container(width: 3, height: 10, color: _pdfRed),
            pw.SizedBox(width: 6),
            pw.Text(label.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.6)),
          ]),
        ),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
      ],
    ));
  }

  void addItemRow(LineItem item) {
    sl++;
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: _pdfGray200, width: 0.5)),
      ),
      children: [
        _pdfTD('$sl'),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(item.productName,
                  style: const pw.TextStyle(fontSize: 10)),
              if (item.brand.isNotEmpty)
                pw.Text(item.brand,
                    style: pw.TextStyle(fontSize: 9, color: _pdfGray500)),
            ],
          ),
        ),
        _pdfTD('${item.quantity}', right: true),
        _pdfTD(item.unit),
        _pdfTD(formatINR(item.rate), right: true),
        _pdfTD(formatINR(item.amount), right: true, bold: true),
      ],
    ));
  }

  for (final sys in systems) {
    final sysItems = items
        .where((i) =>
            i.systemType == sys &&
            !(i.systemType == 'Service' && i.category == 'Installation'))
        .toList();
    if (sysItems.isEmpty) continue;
    addSectionHeader(sys);
    for (final item in sysItems) {
      addItemRow(item);
    }
  }

  final installationItems = items
      .where((i) => i.systemType == 'Service' && i.category == 'Installation')
      .toList();
  if (installationItems.isNotEmpty) {
    addSectionHeader('Service');
    for (final item in installationItems) {
      addItemRow(item);
    }
  }

  return pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(36),
      1: pw.FlexColumnWidth(),
      2: pw.FixedColumnWidth(36),
      3: pw.FixedColumnWidth(38),
      4: pw.FixedColumnWidth(75),
      5: pw.FixedColumnWidth(80),
    },
    children: rows,
  );
}

pw.Widget _pdfTH(String text, {bool right = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white)),
    );

pw.Widget _pdfTD(String text,
        {bool right = false, bool bold = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );

pw.Widget _pdfTotals(double exGST, double gst, double grandTotal) =>
    pw.Container(
      color: _pdfGray50,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _pdfTotalRow('Total (ex. GST)', formatINR(exGST)),
          pw.SizedBox(height: 4),
          _pdfTotalRow('GST @ 18%', formatINR(gst)),
          pw.Divider(color: _pdfGray200, thickness: 0.5),
          _pdfTotalRow('Grand Total', formatINR(grandTotal), isGrand: true),
        ],
      ),
    );

pw.Widget _pdfTotalRow(String label, String value, {bool isGrand = false}) =>
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: isGrand ? 12 : 10,
                fontWeight:
                    isGrand ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isGrand ? _pdfDark : _pdfGray500)),
        pw.SizedBox(width: 16),
        pw.SizedBox(
          width: 100,
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: isGrand ? 13 : 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isGrand ? _pdfRed : _pdfDark)),
        ),
      ],
    );

pw.Widget _pdfBottomLine(Project project) => pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: _pdfGray200, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Ref: ${project.refNumber}',
              style: pw.TextStyle(fontSize: 8, color: _pdfGray500)),
          pw.Text(_kWeb,
              style: pw.TextStyle(fontSize: 8, color: _pdfGray500)),
        ],
      ),
    );

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
    final exGST = items.fold(0.0, (s, i) => s + i.amount);
    final gst = exGST * 0.18;
    final grandTotal = exGST + gst;

    int sl = 0;
    final tableRows = <Widget>[_tableHeader()];
    for (final sys in systems) {
      final sysItems = items
          .where((i) =>
              i.systemType == sys &&
              !(i.systemType == 'Service' && i.category == 'Installation'))
          .toList();
      if (sysItems.isEmpty) continue;
      tableRows.add(_sysRow(sys));
      for (final item in sysItems) {
        sl++;
        tableRows.add(_itemRow(sl, item));
      }
    }
    final installationItems = items
        .where(
            (i) => i.systemType == 'Service' && i.category == 'Installation')
        .toList();
    if (installationItems.isNotEmpty) {
      tableRows.add(_sysRow('Service'));
      for (final item in installationItems) {
        sl++;
        tableRows.add(_itemRow(sl, item));
      }
    }

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _letterhead(),
          Container(height: 2.5, color: _kRed),
          _titleBar(),
          _clientInfo(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tableRows,
          ),
          _totals(exGST, gst, grandTotal),
          _footer(),
        ],
      ),
    );
  }

  Widget _letterhead() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logoBytes != null)
              Image.memory(logoBytes!, height: 42)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BAKER & GREY',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kRed)),
                  Text('Technology Solution Integrators',
                      style: GoogleFonts.inter(
                          fontSize: 8, color: _kGray500)),
                ],
              ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_kWeb,
                    style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _kRed)),
                const SizedBox(height: 2),
                Text(_kCorp,
                    style: GoogleFonts.inter(
                        fontSize: 7.5, color: _kGray500)),
                Text(_kRegd,
                    style: GoogleFonts.inter(
                        fontSize: 7.5, color: _kGray500)),
                Text(_kPh,
                    style: GoogleFonts.inter(
                        fontSize: 7.5, color: _kGray500)),
              ],
            ),
          ],
        ),
      );

  Widget _titleBar() => Container(
        color: _kDark,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Text(
          'BILL OF QUOTES',
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5),
        ),
      );

  Widget _clientInfo() => Table(
        defaultColumnWidth: const FlexColumnWidth(),
        border: TableBorder.all(color: _kGray200, width: 0.5),
        children: [
          TableRow(children: [
            _cCell('Client', project.clientName),
            _cCell('Ref. No.', project.refNumber),
          ]),
          TableRow(children: [
            _cCell('Site', project.location),
            _cCell('Date', _fmtDate(DateTime.now())),
          ]),
        ],
      );

  Widget _cCell(String label, String value) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          SizedBox(
            width: 54,
            child: Text(label,
                style:
                    GoogleFonts.inter(fontSize: 10, color: _kGray500)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kDark)),
          ),
        ]),
      );

  Widget _tableHeader() => Container(
        color: _kDark,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          SizedBox(width: 26, child: Text('No.', style: _th())),
          Expanded(child: Text('Item Description', style: _th())),
          SizedBox(
              width: 32,
              child:
                  Text('Qty', style: _th(), textAlign: TextAlign.right)),
          SizedBox(
              width: 44,
              child: Text('Unit', style: _th(), textAlign: TextAlign.center)),
          SizedBox(
              width: 80,
              child: Text('Rate (₹)', style: _th(), textAlign: TextAlign.right)),
          SizedBox(
              width: 84,
              child: Text('Amount (₹)',
                  style: _th(), textAlign: TextAlign.right)),
        ]),
      );

  Widget _sysRow(String sys) => Container(
        color: _kGray100,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(children: [
          Container(width: 3, height: 11, color: _kRed),
          const SizedBox(width: 8),
          Text(sys.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                  letterSpacing: 0.6)),
        ]),
      );

  Widget _itemRow(int sl, LineItem item) => Container(
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: _kGray100))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 26,
                child: Text('$sl',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: _kGray500))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _kText)),
                  if (item.brand.isNotEmpty)
                    Text(item.brand,
                        style: GoogleFonts.inter(
                            fontSize: 9, color: _kGray500)),
                ],
              ),
            ),
            SizedBox(
                width: 32,
                child: Text('${item.quantity}',
                    style: GoogleFonts.inter(fontSize: 11, color: _kText),
                    textAlign: TextAlign.right)),
            SizedBox(
                width: 44,
                child: Text(item.unit,
                    style: GoogleFonts.inter(fontSize: 11, color: _kText),
                    textAlign: TextAlign.center)),
            SizedBox(
                width: 80,
                child: Text(formatINR(item.rate),
                    style: GoogleFonts.inter(fontSize: 11, color: _kText),
                    textAlign: TextAlign.right)),
            SizedBox(
                width: 84,
                child: Text(formatINR(item.amount),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kDark),
                    textAlign: TextAlign.right)),
          ],
        ),
      );

  Widget _totals(double exGST, double gst, double grandTotal) =>
      Container(
        color: _kGray50,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _totalRow('Total (ex. GST)', formatINR(exGST)),
            const SizedBox(height: 4),
            _totalRow('GST @ 18%', formatINR(gst)),
            const Divider(color: _kGray200),
            _totalRow('Grand Total', formatINR(grandTotal),
                isGrand: true),
          ],
        ),
      );

  Widget _totalRow(String label, String value,
          {bool isGrand = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: isGrand ? 13 : 11,
                  fontWeight: isGrand ? FontWeight.w700 : FontWeight.w400,
                  color: isGrand ? _kDark : _kGray500)),
          SizedBox(
            width: 110,
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: isGrand ? 14 : 11,
                    fontWeight: FontWeight.w700,
                    color: isGrand ? _kRed : _kDark)),
          ),
        ],
      );

  Widget _footer() => Container(
        color: _kDark,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ref: ${project.refNumber}',
                style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: Colors.white.withValues(alpha: 0.7))),
            Text(_kWeb,
                style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      );

  TextStyle _th() => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Colors.white);
}
