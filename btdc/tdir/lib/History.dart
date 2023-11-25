// ignore_for_file: library_private_types_in_public_api, avoid_print, use_key_in_widget_constructors, file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class History extends StatefulWidget {
  const History({Key? key});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, String>> historyRecords = [];
  String? username; // Declare a variable to store the username

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the username from the arguments when the page is pushed
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      username = arguments['username'];
    }

    // Fetch history records for the username
    if (username != null) {
      _fetchHistoryRecords();
    }
  }

  Future<void> _fetchHistoryRecords() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:2819/history?username=$username'), // Replace with your API URL
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        setState(() {
          historyRecords = data.map((record) {
            if (record is Map<String, dynamic>) {
              return {
                'date': record['date']?.toString().toUpperCase() ?? '',
                'time': record['time']?.toString().toUpperCase() ?? '',
                'result': record['result']?.toString().toUpperCase() ?? '',
              };
            } else {
              return {
                'date': '',
                'time': '',
                'result': '',
              };
            }
          }).toList();
        });
      } else if (response.statusCode == 204) {
        // Handle the 204 status code by setting historyRecords to an empty list
        setState(() {
          historyRecords = [];
        });
      } else {
        // Handle other error cases
        print('Failed to fetch history records. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other errors
      print('Error fetching history records: $e');
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('History'),
    ),
    body: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        dataTextStyle: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
        columnSpacing: 20.0,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Result')),
        ],
        rows: historyRecords.isNotEmpty
            ? historyRecords.map((record) {
                return DataRow(cells: [
                  DataCell(Text(record['date']!)),
                  DataCell(Text(record['time']!)),
                  DataCell(Text(record['result']!)),
                ]);
              }).toList()
            : [], // Return an empty list of rows if historyRecords is empty
      ),
    ),
  );
}
}