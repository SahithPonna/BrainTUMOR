// ignore_for_file: file_names, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
// import 'package:sqflite/sqflite.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final TextEditingController _apiKeyController = TextEditingController();
  String _predictionResult = '';
  bool _isPredicting = false;
  File? _selectedFile;
  String? username;
  String? email;
  String? apikey;

  @override
  void initState() {
    super.initState();
    // Your other initialization code here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the username and email from ModalRoute here
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      username = arguments['username'];
      email = arguments['email'];
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _isPredicting = false;
        _predictionResult = '';
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _predictImage() async {
    if (_selectedFile == null) {
      _showAlert('No File Selected', 'Please select a file first.');
      return;
    }

    setState(() {
      _isPredicting = true;
      _predictionResult = '';
      _predictionProgress = 0.0;
    });

    // Simulate the delay for API call and result processing (3 seconds in this example)
    await Future.delayed(const Duration(seconds: 3));

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPredicting) {
        timer.cancel();
      }
      setState(() {
        _predictionProgress += 0.01;
      });
    });

    try {
      // Replace the API endpoint with your actual API URL for image upload
      var uri = Uri.parse('http://127.0.0.1:2819/upload'); // Replace with your API URL

      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', _selectedFile!.path));
      if (username != null) {
        request.fields['username'] = username!;
      }
      if(apikey!=null){
        request.headers['Authorization'] = apikey!;
      }
      if(apikey==null)
      {
        request.headers['Authorization'] = "qhLusfHmKhv47SKEoZ0dq09qV9yK8t35";
      }

      var response = await request.send();
      if (response.statusCode == 283) {
      // Handle error code 283 (maximum scan attempts exhausted)
      _showAlert('Scan Attempts Exhausted', 'You have reached the maximum scan attempts. Please contact the admin.');
      setState(() {
        _isPredicting = false;
        _predictionProgress = 0.0;
        _selectedFile = null;
      });
      return;
    }
        if (response.statusCode == 273) {
      // Handle error code 283 (maximum scan attempts exhausted)
      _showAlert('FREE TIER EXHAUSED', 'Free API Key Limit Reached Upgrade');
      setState(() {
        _isPredicting = false;
        _predictionProgress = 0.0;
        _selectedFile = null;
      });
      return;
    }
    if (response.statusCode == 238) {
      // Handle error code 283 (maximum scan attempts exhausted)
      _showAlert('Check API KEY', 'ILLegaL API Key Contact Admin.');
      setState(() {
        _isPredicting = false;
        _predictionProgress = 0.0;
        _selectedFile = null;
      });
      return;
    }
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _predictionResult = responseBody.replaceAll('"', '');
          _isPredicting = false;
          _predictionProgress = 1.0;
          _selectedFile = null;
        });
      } else {
        setState(() {
          _predictionResult = 'Prediction failed.';
          _isPredicting = false;
          _selectedFile = null;
        });
      }
    } on SocketException catch (_) {
      _showAlert('SERVER DOWN', 'API IS NOT UP!!! CHECK YOUR CONNECTIONS');
      _selectedFile = null;
    } catch (e) {
      print('Other Error: $e');
      _showAlert('Error', 'An error occurred during prediction.');
      _selectedFile = null;
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            message,
            style: const TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _predictionProgress = 0.0;
                  _predictionResult = '';
                  _isPredicting = false;
                  _selectedFile = null;
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  void _showApiKeyDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Enter API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Store the API key in the 'apikey' variable and close the dialog
              setState(() {
                apikey = _apiKeyController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes', style: TextStyle(color: Color.fromARGB(255, 255, 0, 0))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      try {
        final response = await http.post(Uri.parse('http://127.0.0.1:2819/delacc'),body: {'username': username},);
        if (response.statusCode == 200) {
          int resultCode = int.parse(response.body);
          if(resultCode==333)
          {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
          else if (resultCode == 334) {
            _showAlert('Error', 'An error occurred during userdeletion.');
          }
        }
        else{
          print("error in deleting acc");
        }
      } catch (e) {
        print('Error deleting account: $e');
      }
    }
  }

  double _predictionProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    String email;
    if (arguments is Map<String, dynamic>) {
      email = arguments['email'];
    } else {
      email = 'Email not available';
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Brain Tumor Classifier'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/avatar.png'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    )
                  ],
                ),
              ),
              ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('API KEY'),
                  onTap: () {
                      _showApiKeyDialog();
                   },
                  ),
              ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                  onTap: () {
                      Navigator.pushNamed(context, '/history', arguments: {'username': username});
                   },
                  ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _logout,
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Account'),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Image.asset(
              'assets/back.jpg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedFile != null)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Image.file(
                        _selectedFile!,
                        height: 200,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openFilePicker,
                    child: const Text(
                      'Select File',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _predictImage,
                    child: const Text(
                      'Predict',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isPredicting)
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: Column(
                        children: [
                          LinearProgressIndicator(value: _predictionProgress),
                          const SizedBox(height: 10),
                          const Text(
                            'Analyzing...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_predictionResult.isNotEmpty)
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: Column(
                        children: [
                          LinearProgressIndicator(value: _predictionProgress),
                          const SizedBox(height: 10),
                          const Text(
                            'Analyzed',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Result: $_predictionResult',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}