/// Utility for parsing CSV files in Dart without external package dependencies.
class CsvParser {
  /// Parses raw CSV string into a list of rows (where each row is a List of string values).
  /// Handles quoted fields containing commas, double quotes, and line breaks.
  static List<List<String>> parseRows(String csvText) {
    final rows = <List<String>>[];
    final sb = StringBuffer();
    var inQuotes = false;
    var currentRow = <String>[];

    for (var i = 0; i < csvText.length; i++) {
      final char = csvText[i];
      if (char == '"') {
        if (inQuotes && i + 1 < csvText.length && csvText[i + 1] == '"') {
          sb.write('"');
          i++; // Skip escaped double-quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(sb.toString().trim());
        sb.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < csvText.length && csvText[i + 1] == '\n') {
          i++; // Consume \n after \r
        }
        currentRow.add(sb.toString().trim());
        sb.clear();
        if (currentRow.isNotEmpty && !(currentRow.length == 1 && currentRow[0].isEmpty)) {
          rows.add(currentRow);
        }
        currentRow = <String>[];
      } else {
        sb.write(char);
      }
    }

    if (sb.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(sb.toString().trim());
      if (currentRow.isNotEmpty && !(currentRow.length == 1 && currentRow[0].isEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  /// Parses CSV catalog text into a list of medicine maps matching MediSathi catalog schema.
  static List<Map<String, dynamic>> parseMedicineCatalogCsv(String csvContent) {
    final rows = parseRows(csvContent);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((h) => h.toLowerCase()).toList();
    final catalog = <Map<String, dynamic>>[];

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty || row.every((val) => val.isEmpty)) continue;

      final map = <String, dynamic>{};
      for (var c = 0; c < headers.length && c < row.length; c++) {
        map[headers[c]] = row[c];
      }

      final aliasesRaw = (map['aliases'] as String?) ?? '';
      final aliases = aliasesRaw.isEmpty
          ? <String>[]
          : aliasesRaw.split('|').map((s) => s.trim().toLowerCase()).toList();

      final keywordsRaw = (map['ocr_keywords'] as String?) ?? '';
      final ocrKeywords = keywordsRaw.isEmpty
          ? <String>[]
          : keywordsRaw.split('|').map((s) => s.trim().toLowerCase()).toList();

      final discriminatorsRaw = (map['discriminators'] as String?) ?? '';
      final discriminators = discriminatorsRaw.isEmpty
          ? <String>[]
          : discriminatorsRaw.split('|').map((s) => s.trim()).toList();

      final lookalikeGroup = (map['lookalike_group_id'] as String?)?.trim();

      catalog.add({
        'medicine_id': map['medicine_id'] ?? 'MED-UNK',
        'canonical_name': map['canonical_name'] ?? 'Unknown Medicine',
        'brand_name': map['brand_name'] ?? 'Generic',
        'aliases': aliases,
        'strength': map['strength'] ?? '',
        'dosage_form': map['dosage_form'] ?? 'Tablet',
        'manufacturer': map['manufacturer'] ?? 'Unknown',
        'ocr_keywords': ocrKeywords,
        'lookalike_group_id': (lookalikeGroup != null && lookalikeGroup.isNotEmpty) ? lookalikeGroup : null,
        'discriminators': discriminators,
        'color_signature': {'hue': 0, 'sat': 0, 'val': 0, 'tol': 30, 'calibrated': false},
        'known_batch_prefixes': [],
        'category_use_text': map['category_use_text'] ?? '',
        'instruction_text': map['instruction_text'] ?? 'As prescribed by doctor.',
        'source_reference': map['source_reference'] ?? 'Offline CSV Catalog',
        'updated_at': map['updated_at'] ?? DateTime.now().toIso8601String().substring(0, 10),
      });
    }

    return catalog;
  }
}
