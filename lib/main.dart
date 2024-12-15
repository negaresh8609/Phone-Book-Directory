import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';
import 'excel_reader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excel Search App',
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> _results = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request storage permissions
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // Request permission
      await Permission.storage.request();
    }

    // Load data from Excel file after permission is granted
    if (await Permission.storage.isGranted) {
      _loadExcelFile();
    } else {
      // Handle the case when permission is denied
      print("Storage permission denied");
    }
  }

  void _loadExcelFile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await readExcelFile('storage/emulated/0/download/book1.xlsx');
    } catch (e) {
      print('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchContacts(String query) async {
    if (query.length > 2) {
      var results = await DatabaseHelper().searchContacts(query);
      setState(() {
        _results = results;
      });
    } else {
      setState(() {
        _results = [];
      });
    }
  }

  void _makeCall(String phoneNumber) async {
    String url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Contacts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _searchContacts,
              decoration: InputDecoration(
                labelText: 'Search by Name, Last Name, or School',
              ),
            ),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _results.length > 10 ? 10 : _results.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                              '${_results[index]['name']} ${_results[index]['last_name']}'),
                          subtitle: Text('${_results[index]['school']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.call),
                            onPressed: () {
                              _makeCall(_results[index]['phone_number']);
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

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
