import 'package:excel/excel.dart';
import 'dart:io';
import 'database_helper.dart';

Future<void> readExcelFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found');
    }
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    for (final table in excel.tables.keys) {
      for (final row in excel.tables[table]!.rows) {
        if (row.length >= 4) {
          final contact = {
            'name': row[0]?.value ?? '',
            'last_name': row[1]?.value ?? '',
            'school': row[2]?.value ?? '',
            'phone_number': row[3]?.value ?? '',
          };
          await DatabaseHelper().insertContact(contact);
        } else {
          print('Skipping row with insufficient data');
        }
      }
    }
  } on IOException catch (e) {
    print('Error reading Excel file: $e');
  } on ExcelException catch (e) {
    print('Error parsing Excel file: $e');
  } catch (e) {
    print('An error occurred: $e');
  }
}
