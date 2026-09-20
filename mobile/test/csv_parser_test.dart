import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/core/csv/csv_parser.dart';

void main() {
  group('CsvParser Tests', () {
    test('Parses raw CSV rows with quoted fields and commas correctly', () {
      const sampleCsv = '''id,name,description
1,Paracetamol,"Fever, pain relief"
2,Amlodipine,"Blood pressure, daily dose"''';

      final rows = CsvParser.parseRows(sampleCsv);
      expect(rows.length, equals(3));
      expect(rows[0], equals(['id', 'name', 'description']));
      expect(rows[1][2], equals('Fever, pain relief'));
      expect(rows[2][2], equals('Blood pressure, daily dose'));
    });

    test('Parses medicine catalog CSV into structured medicine maps', () {
      const sampleMedicineCsv = '''medicine_id,canonical_name,brand_name,aliases,strength,dosage_form,manufacturer,ocr_keywords,lookalike_group_id,discriminators,category_use_text,instruction_text,source_reference,updated_at
MED-001,Paracetamol,Crocin 500,paracetamol|crocin|dolo,500 mg,Tablet,GSK,paracetamol|500|mg,LA-PARA,strength,Fever relief,"Take 1 tablet every 4 hours.",Crocin 500 India,2026-09-19''';

      final catalog = CsvParser.parseMedicineCatalogCsv(sampleMedicineCsv);
      expect(catalog.length, equals(1));

      final med = catalog.first;
      expect(med['medicine_id'], equals('MED-001'));
      expect(med['canonical_name'], equals('Paracetamol'));
      expect(med['brand_name'], equals('Crocin 500'));
      expect(med['aliases'], equals(['paracetamol', 'crocin', 'dolo']));
      expect(med['strength'], equals('500 mg'));
      expect(med['dosage_form'], equals('Tablet'));
      expect(med['ocr_keywords'], equals(['paracetamol', '500', 'mg']));
      expect(med['lookalike_group_id'], equals('LA-PARA'));
      expect(med['discriminators'], equals(['strength']));
      expect(med['instruction_text'], equals('Take 1 tablet every 4 hours.'));
    });
  });
}
