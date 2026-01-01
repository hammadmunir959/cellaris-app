import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndPrintPO(PurchaseOrder po) async {
    final pdf = pw.Document();

    // Load fonts or image assets if needed here. 
    // For now using standard fonts.

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(po),
            pw.SizedBox(height: 20),
            _buildVendorAndShipTo(po),
            pw.SizedBox(height: 20),
            _buildPOTable(po),
            pw.SizedBox(height: 10),
            _buildTotals(po),
            pw.SizedBox(height: 40),
            _buildFooter(po),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PO_${po.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}',
    );
  }

  static pw.Widget _buildHeader(PurchaseOrder po) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('COMPANY NAME', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('123 Business Road, Tech City'),
            pw.Text('Phone: +92 300 1234567'),
            pw.Text('Email: info@company.com'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('PURCHASE ORDER', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('PO #: ${(po.id.length > 8 ? po.id.substring(0, 8) : po.id).toUpperCase()}'),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(po.createdAt)}'),
            pw.Text('Status: ${po.status.name.toUpperCase()}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildVendorAndShipTo(PurchaseOrder po) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('VENDOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(po.supplierName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('(Supplier Details Here)'),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SHIP TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text('Our Warehouse'),
                pw.Text('123 Business Road'),
                pw.Text('Tech City, Pakistan'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPOTable(PurchaseOrder po) {
    return pw.TableHelper.fromTextArray(
      headers: ['Item Description', 'Qty', 'Unit Price', 'Total'],
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
      data: po.items.map((item) {
        return [
          item.productName,
          item.quantity.toString(),
          item.costPrice.toStringAsFixed(2),
          (item.quantity * item.costPrice).toStringAsFixed(2),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildTotals(PurchaseOrder po) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(children: [pw.Text('Subtotal: '), pw.Text(po.totalCost.toStringAsFixed(2))]),
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text(po.totalCost.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(PurchaseOrder po) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text('Comments / Special Instructions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(po.notes ?? 'None'),
        pw.SizedBox(height: 40),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
             pw.Column(
               children: [
                 pw.Container(width: 150, height: 1, color: PdfColors.black),
                 pw.SizedBox(height: 5),
                 pw.Text('Authorized Signature'),
               ]
             ),
             pw.Column(
               children: [
                 pw.Container(width: 150, height: 1, color: PdfColors.black),
                 pw.SizedBox(height: 5),
                 pw.Text('Date'),
               ]
             ),
          ],
        )
      ],
    );
  }
  static Future<void> generateAndPrintRepairTicket(RepairTicket ticket) async {
    final pdf = pw.Document();
    
    // Load professional font for Unicode support and premium look
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontItalic = await PdfGoogleFonts.poppinsItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return [
            _buildRepairHeader(ticket),
            pw.SizedBox(height: 20),
            _buildRepairCustomerInfo(ticket),
            pw.SizedBox(height: 20),
            _buildRepairDetails(ticket),
            pw.SizedBox(height: 40),
            _buildRepairFooter(ticket),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Repair_${ticket.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}',
    );
  }

  static pw.Widget _buildRepairHeader(RepairTicket ticket) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('MBM SOLUTIONS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('High-Tech Device Repair Center'),
            pw.Text('123 Business Road, Tech City'),
            pw.Text('Phone: +92 300 1234567'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('REPAIR TOKEN', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const pw.BoxDecoration(color: PdfColors.orange50),
              child: pw.Text('ID: ${ticket.id.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(ticket.createdAt)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRepairCustomerInfo(RepairTicket ticket) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CUSTOMER INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 8),
              pw.Text(ticket.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Contact: ${ticket.customerContact}'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('EXPECTED COLLECTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 8),
              pw.Text(
                ticket.expectedReturnDate != null 
                  ? DateFormat('MMM dd, yyyy').format(ticket.expectedReturnDate!)
                  : 'TBD',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
              ),
              pw.Text(ticket.expectedReturnDate != null 
                ? DateFormat('hh:mm a').format(ticket.expectedReturnDate!)
                : ''),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRepairDetails(RepairTicket ticket) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DEVICE & SERVICE DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Device Model', 'Primary Issue', 'Estimated Cost'],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellHeight: 30,
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
          },
          data: [
            [
              ticket.deviceModel,
              ticket.issueDescription,
              'Rs. ${ticket.estimatedCost.toStringAsFixed(0)}',
            ]
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRepairNotes(RepairTicket ticket) {
    if (ticket.notes.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('REPAIR LOG / NOTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: ticket.notes.map((note) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(child: pw.Text(note, style: const pw.TextStyle(fontSize: 9))),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRepairFooter(RepairTicket ticket) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.SizedBox(height: 5),
              pw.Text('1. Customer data must be backed up by owner; we are not liable for data loss.', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('2. Standard diagnosis fee applies even if the device is unrepairable.', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('3. 30-day storage policy applies. Unclaimed devices will be recycled.', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('4. Warranty (if any) is only valid on the specific parts replaced.', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.SizedBox(height: 50),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
             pw.Column(
               children: [
                 pw.Container(width: 160, height: 1, color: PdfColors.grey400),
                 pw.SizedBox(height: 5),
                 pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 10)),
               ]
             ),
             pw.Column(
               children: [
                 pw.Container(width: 160, height: 1, color: PdfColors.grey400),
                 pw.SizedBox(height: 5),
                 pw.Text('Authorized Technician', style: const pw.TextStyle(fontSize: 10)),
               ]
             ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text('Thank you for choosing MBM SOLUTIONS', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
        ),
      ],
    );
  }
}
