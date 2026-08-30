const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

const COMPANY = {
  name: 'YOUR DREAM CARS',
  address: 'Clover Hills Plaza, NIBM, Pune',
};

const LOGO_PATH = path.join(__dirname, '../../assets/ydc_logo_round.png');

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

function buildDeliveryNotePdf(note) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 48, autoFirstPage: true });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const marginLeft = doc.page.margins.left;
    const marginTop = doc.page.margins.top;
    const marginBottom = doc.page.margins.bottom;
    const pageW = doc.page.width - marginLeft - doc.page.margins.right;

    const contentBottom = () => doc.page.height - marginBottom - 36;

    let y = marginTop;

    const ensureSpace = (needed, cursor) => {
      let pos = cursor ?? y;
      if (pos + needed > contentBottom()) {
        doc.addPage();
        pos = marginTop;
      }
      return pos;
    };

    const rowHeight = (label, value, width) => {
      const labelW = width * 0.32;
      const valueW = width * 0.68;
      const valueText = val(value);
      doc.font('Helvetica').fontSize(9);
      const labelH = doc.heightOfString(label, { width: labelW });
      doc.font('Helvetica-Bold').fontSize(10);
      const valueH = doc.heightOfString(valueText, { width: valueW });
      return Math.max(labelH, valueH, 12) + 10;
    };

    const drawField = (label, value, x, startY, width) => {
      const labelW = width * 0.32;
      const valueW = width * 0.68;
      const valueText = val(value);
      const h = rowHeight(label, value, width);
      const rowY = ensureSpace(h, startY);
      doc.font('Helvetica').fontSize(9).fillColor('#475569').text(label, x, rowY, { width: labelW });
      doc
        .font('Helvetica-Bold')
        .fontSize(10)
        .fillColor('#0F172A')
        .text(valueText, x + labelW, rowY, { width: valueW });
      return rowY + h;
    };

    const drawFieldsRow = (fields) => {
      const maxH = Math.max(...fields.map((f) => rowHeight(f.label, f.value, f.width)));
      y = ensureSpace(maxH, y);
      const rowY = y;
      let nextY = rowY;
      for (const f of fields) {
        const endY = drawField(f.label, f.value, f.x, rowY, f.width);
        nextY = Math.max(nextY, endY);
      }
      y = nextY;
    };

    const sectionTitle = (title) => {
      y = ensureSpace(32, y);
      doc.roundedRect(marginLeft, y, pageW, 22, 4).fill('#EEF2FF');
      doc
        .font('Helvetica-Bold')
        .fontSize(10)
        .fillColor('#031273')
        .text(title, marginLeft + 10, y + 6);
      y += 32;
    };

    const half = pageW / 2 - 8;
    const quarter = pageW / 4 - 8;
    const isBuy = note.noteType === 'buy';
    const docTitle = isBuy ? 'VEHICLE PURCHASE NOTE' : 'VEHICLE DELIVERY NOTE';
    const partySection = isBuy ? 'Seller Details' : 'Customer Details';
    const partyLabel = isBuy ? 'Seller Name' : 'Customer Name';
    const sigLabel = isBuy ? 'Seller Signature' : 'Customer Signature';
    const sigNameLabel = isBuy ? 'Seller Name' : 'Customer Name';

    // Header with brand logo
    y = ensureSpace(78, y);
    doc.save();
    doc.rect(marginLeft, y, pageW, 64).fill('#031273');
    if (fs.existsSync(LOGO_PATH)) {
      doc.image(LOGO_PATH, marginLeft + pageW - 58, y + 8, { width: 48, height: 48 });
    }
    doc.fillColor('#FFFFFF');
    doc.font('Helvetica-Bold').fontSize(20).text(COMPANY.name, marginLeft + 12, y + 14);
    doc.font('Helvetica').fontSize(10).text(COMPANY.address, marginLeft + 12, y + 40);
    doc.restore();
    y += 78;

    y = ensureSpace(28, y);
    doc
      .font('Helvetica-Bold')
      .fontSize(15)
      .fillColor('#031273')
      .text(docTitle, marginLeft, y, { width: pageW, align: 'center' });
    y += 28;

    y = drawField('Note Type', isBuy ? 'Buy (from customer)' : 'Sell (to customer)', marginLeft, y, pageW);
    y = drawField('Delivery Note No.', note.deliveryNoteNo, marginLeft, y, pageW);
    drawFieldsRow([
      { label: 'Date', value: fmtDate(note.deliveryDate), x: marginLeft, width: half },
      {
        label: 'Delivery Time',
        value: note.deliveryTime,
        x: marginLeft + pageW / 2 + 8,
        width: half,
      },
    ]);
    y += 4;

    sectionTitle(partySection);
    y = drawField(partyLabel, note.customerName, marginLeft, y, pageW);
    y = drawField('Address', note.customerAddress, marginLeft, y, pageW);
    drawFieldsRow([
      { label: 'Mobile No.', value: note.customerMobile, x: marginLeft, width: half },
      { label: 'ID Proof', value: note.idProofType, x: marginLeft + pageW / 2 + 8, width: quarter },
      { label: 'ID No.', value: note.idProofNo, x: marginLeft + pageW * 0.75 + 4, width: quarter },
    ]);
    y += 4;

    sectionTitle('Vehicle Details');
    drawFieldsRow([
      { label: 'Make / Brand', value: note.vehicleBrand, x: marginLeft, width: half },
      { label: 'Model / Variant', value: note.vehicleModel, x: marginLeft + pageW / 2 + 8, width: half },
    ]);
    drawFieldsRow([
      { label: 'Registration No.', value: note.registrationNo, x: marginLeft, width: half },
      {
        label: 'Year of Manufacture',
        value: note.yearOfManufacture,
        x: marginLeft + pageW / 2 + 8,
        width: half,
      },
    ]);
    drawFieldsRow([
      { label: 'Colour', value: note.colour, x: marginLeft, width: half },
      { label: 'Fuel Type', value: note.fuelType, x: marginLeft + pageW / 2 + 8, width: half },
    ]);
    y = drawField('Chassis No.', note.chassisNo, marginLeft, y, pageW);
    y = drawField('Engine No.', note.engineNo, marginLeft, y, pageW);
    y = drawField('Odometer Reading (KM)', note.odometerKm, marginLeft, y, half);
    y += 4;

    sectionTitle('Payment Details');
    y = drawField('Total Vehicle Price', fmtInr(note.totalPrice), marginLeft, y, pageW);
    y = drawField('Amount Received', fmtInr(note.amountReceived), marginLeft, y, pageW);
    y = drawField('Balance Amount (if any)', fmtInr(note.balanceAmount), marginLeft, y, pageW);
    y = drawField('Payment Mode', note.paymentMode, marginLeft, y, pageW);
    y += 4;

    sectionTitle('Documents / Items Handed Over');
    const docsText =
      val(note.documentsHandedOver) ||
      'RC / Insurance / PUC / Service Records / Keys / Spare Key / Other';
    doc.font('Helvetica').fontSize(10).fillColor('#0F172A');
    const docsH = doc.heightOfString(docsText, { width: pageW, lineGap: 2 });
    y = ensureSpace(docsH + 8, y);
    doc.text(docsText, marginLeft, y, { width: pageW, lineGap: 2 });
    y += docsH + 12;

    sectionTitle(isBuy ? 'Purchase Declaration' : 'Delivery Declaration');
    const declName = val(note.declarationCustomerName || note.customerName);
    const declaration = isBuy
      ? `I, ${declName}, confirm that I have sold the above-mentioned vehicle to Your Dream Cars and have handed over physical possession of the vehicle, keys and documents/items listed above in the condition mutually agreed upon.\n\n` +
        'I acknowledge receipt of payment as stated above. Any pending documentation, ownership transfer, or other commitment shall be completed according to the separately agreed terms.'
      : `I, ${declName}, confirm that I have inspected the above-mentioned vehicle and have taken physical delivery of it from Your Dream Cars in the condition mutually agreed upon.\n\n` +
        'I acknowledge receipt of the vehicle, keys and documents/items mentioned above. Any pending documentation, ownership transfer, payment or other commitment, if applicable, shall be completed according to the separately agreed terms.';
    doc.font('Helvetica').fontSize(9.5).fillColor('#334155');
    const declH = doc.heightOfString(declaration, { width: pageW, lineGap: 3 });
    y = ensureSpace(declH + 12, y);
    doc.text(declaration, marginLeft, y, { width: pageW, lineGap: 3 });
    y += declH + 16;

    y = ensureSpace(110, y);
    const sigY = y;
    doc.moveTo(marginLeft, sigY + 36).lineTo(marginLeft + pageW * 0.42, sigY + 36).stroke('#CBD5E1');
    doc
      .moveTo(marginLeft + pageW * 0.55, sigY + 36)
      .lineTo(marginLeft + pageW, sigY + 36)
      .stroke('#CBD5E1');
    doc.font('Helvetica-Bold').fontSize(9).fillColor('#031273').text(sigLabel, marginLeft, sigY + 42);
    doc.text('For YOUR DREAM CARS — Authorized Signature', marginLeft + pageW * 0.55, sigY + 42);
    y = sigY + 62;

    drawFieldsRow([
      {
        label: sigNameLabel,
        value: note.customerSignatureName || note.customerName,
        x: marginLeft,
        width: half,
      },
      {
        label: 'Date & Time',
        value: note.signedAt ? `${fmtDate(note.signedAt)} ${note.deliveryTime || ''}`.trim() : '—',
        x: marginLeft + pageW / 2 + 8,
        width: half,
      },
    ]);
    y = drawField('Authorized Name', note.authorizedSignatoryName, marginLeft, y, half);
    y = drawField('Vehicle Handed Over By', note.vehicleHandedOverBy, marginLeft, y, pageW);

    const footerText = isBuy
      ? 'Keep two signed copies — one for the seller and one for Your Dream Cars. This purchase note supplements your sale agreement/receipt and RTO transfer documents.'
      : 'Keep two signed copies — one for the customer and one for Your Dream Cars. This delivery note supplements your sale agreement/receipt and RTO transfer documents.';
    doc.font('Helvetica').fontSize(8).fillColor('#94A3B8');
    const footerH = doc.heightOfString(footerText, { width: pageW, align: 'center' });
    y = ensureSpace(footerH + 12, y + 16);
    doc.text(footerText, marginLeft, y, { width: pageW, align: 'center' });

    doc.end();
  });
}

module.exports = { buildDeliveryNotePdf };
