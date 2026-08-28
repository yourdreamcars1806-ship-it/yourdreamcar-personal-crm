const PDFDocument = require('pdfkit');

const COMPANY = {
  name: 'YOUR DREAM CARS',
  address: 'Clover Hills Plaza, NIBM, Pune',
};

function fmtDate(d) {
  if (!d) return '—';
  const dt = d instanceof Date ? d : new Date(d);
  if (Number.isNaN(dt.getTime())) return '—';
  const dd = String(dt.getDate()).padStart(2, '0');
  const mm = String(dt.getMonth() + 1).padStart(2, '0');
  const yyyy = dt.getFullYear();
  return `${dd} / ${mm} / ${yyyy}`;
}

function fmtInr(n) {
  if (n == null || !Number.isFinite(Number(n))) return '—';
  return `₹${Number(n).toLocaleString('en-IN')}`;
}

function val(v) {
  const s = v == null ? '' : String(v).trim();
  return s || '—';
}

function fieldRow(doc, label, value, x, y, width) {
  doc
    .font('Helvetica')
    .fontSize(9)
    .fillColor('#475569')
    .text(label, x, y, { width: width * 0.32 });
  doc
    .font('Helvetica-Bold')
    .fontSize(10)
    .fillColor('#0F172A')
    .text(val(value), x + width * 0.32, y, { width: width * 0.68 });
  return y + 22;
}

function sectionTitle(doc, title, x, y, width) {
  doc
    .roundedRect(x, y, width, 22, 4)
    .fill('#EEF2FF');
  doc
    .font('Helvetica-Bold')
    .fontSize(10)
    .fillColor('#031273')
    .text(title, x + 10, y + 6);
  return y + 32;
}

function buildDeliveryNotePdf(note) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 48, bufferPages: true });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const pageW = doc.page.width - 96;
    let y = 48;

    doc.save();
    doc.rect(48, y, pageW, 64).fill('#031273');
    doc.fillColor('#FFFFFF');
    doc.font('Helvetica-Bold').fontSize(20).text(COMPANY.name, 60, y + 14);
    doc.font('Helvetica').fontSize(10).text(COMPANY.address, 60, y + 40);
    doc.restore();
    y += 78;

    doc
      .font('Helvetica-Bold')
      .fontSize(15)
      .fillColor('#031273')
      .text('VEHICLE DELIVERY NOTE', 48, y, { width: pageW, align: 'center' });
    y += 28;

    y = fieldRow(doc, 'Delivery Note No.', note.deliveryNoteNo, 48, y, pageW);
    y = fieldRow(doc, 'Date', fmtDate(note.deliveryDate), 48, y, pageW / 2 - 8);
    y = fieldRow(doc, 'Delivery Time', note.deliveryTime, 48 + pageW / 2 + 8, y - 22, pageW / 2 - 8);
    y += 8;

    y = sectionTitle(doc, 'Customer Details', 48, y, pageW);
    y = fieldRow(doc, 'Customer Name', note.customerName, 48, y, pageW);
    y = fieldRow(doc, 'Address', note.customerAddress, 48, y, pageW);
    y = fieldRow(doc, 'Mobile No.', note.customerMobile, 48, y, pageW / 2 - 8);
    y = fieldRow(doc, 'ID Proof', note.idProofType, 48 + pageW / 2 + 8, y - 22, pageW / 4 - 8);
    y = fieldRow(doc, 'ID No.', note.idProofNo, 48 + pageW * 0.75 + 4, y - 22, pageW / 4 - 8);
    y += 8;

    y = sectionTitle(doc, 'Vehicle Details', 48, y, pageW);
    y = fieldRow(doc, 'Make / Brand', note.vehicleBrand, 48, y, pageW / 2 - 8);
    y = fieldRow(doc, 'Model / Variant', note.vehicleModel, 48 + pageW / 2 + 8, y - 22, pageW / 2 - 8);
    y = fieldRow(doc, 'Registration No.', note.registrationNo, 48, y, pageW / 2 - 8);
    y = fieldRow(
      doc,
      'Year of Manufacture',
      note.yearOfManufacture,
      48 + pageW / 2 + 8,
      y - 22,
      pageW / 2 - 8,
    );
    y = fieldRow(doc, 'Colour', note.colour, 48, y, pageW / 2 - 8);
    y = fieldRow(doc, 'Fuel Type', note.fuelType, 48 + pageW / 2 + 8, y - 22, pageW / 2 - 8);
    y = fieldRow(doc, 'Chassis No.', note.chassisNo, 48, y, pageW);
    y = fieldRow(doc, 'Engine No.', note.engineNo, 48, y, pageW);
    y = fieldRow(doc, 'Odometer Reading (KM)', note.odometerKm, 48, y, pageW / 2 - 8);
    y += 8;

    y = sectionTitle(doc, 'Payment Details', 48, y, pageW);
    y = fieldRow(doc, 'Total Vehicle Price', fmtInr(note.totalPrice), 48, y, pageW);
    y = fieldRow(doc, 'Amount Received', fmtInr(note.amountReceived), 48, y, pageW);
    y = fieldRow(doc, 'Balance Amount (if any)', fmtInr(note.balanceAmount), 48, y, pageW);
    y = fieldRow(doc, 'Payment Mode', note.paymentMode, 48, y, pageW);
    y += 8;

    y = sectionTitle(doc, 'Documents / Items Handed Over', 48, y, pageW);
    doc
      .font('Helvetica')
      .fontSize(10)
      .fillColor('#0F172A')
      .text(
        val(note.documentsHandedOver) ||
          'RC / Insurance / PUC / Service Records / Keys / Spare Key / Other',
        48,
        y,
        { width: pageW },
      );
    y += 36;

    y = sectionTitle(doc, 'Delivery Declaration', 48, y, pageW);
    const declName = val(note.declarationCustomerName || note.customerName);
    const declaration =
      `I, ${declName}, confirm that I have inspected the above-mentioned vehicle and have taken physical delivery of it from Your Dream Cars in the condition mutually agreed upon.\n\n` +
      'I acknowledge receipt of the vehicle, keys and documents/items mentioned above. Any pending documentation, ownership transfer, payment or other commitment, if applicable, shall be completed according to the separately agreed terms.';
    doc.font('Helvetica').fontSize(9.5).fillColor('#334155').text(declaration, 48, y, {
      width: pageW,
      lineGap: 3,
    });
    y += 88;

    const sigY = y;
    doc.moveTo(48, sigY + 36).lineTo(48 + pageW * 0.42, sigY + 36).stroke('#CBD5E1');
    doc.moveTo(48 + pageW * 0.55, sigY + 36).lineTo(48 + pageW, sigY + 36).stroke('#CBD5E1');
    doc.font('Helvetica-Bold').fontSize(9).fillColor('#031273').text('Customer Signature', 48, sigY + 42);
    doc.text('For YOUR DREAM CARS — Authorized Signature', 48 + pageW * 0.55, sigY + 42);

    y = sigY + 62;
    y = fieldRow(doc, 'Customer Name', note.customerSignatureName || note.customerName, 48, y, pageW / 2 - 8);
    y = fieldRow(
      doc,
      'Date & Time',
      note.signedAt ? `${fmtDate(note.signedAt)} ${note.deliveryTime || ''}`.trim() : '—',
      48 + pageW / 2 + 8,
      y - 22,
      pageW / 2 - 8,
    );
    y = fieldRow(doc, 'Authorized Name', note.authorizedSignatoryName, 48, y, pageW / 2 - 8);
    y = fieldRow(doc, 'Vehicle Handed Over By', note.vehicleHandedOverBy, 48, y, pageW);

    doc
      .font('Helvetica')
      .fontSize(8)
      .fillColor('#94A3B8')
      .text(
        'Keep two signed copies — one for the customer and one for Your Dream Cars. This delivery note supplements your sale agreement/receipt and RTO transfer documents.',
        48,
        doc.page.height - 56,
        { width: pageW, align: 'center' },
      );

    doc.end();
  });
}

module.exports = { buildDeliveryNotePdf };
