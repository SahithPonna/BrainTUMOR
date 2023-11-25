// ignore_for_file: library_private_types_in_public_api, file_names, use_build_context_synchronously, sort_child_properties_last, prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, prefer_final_fields

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController(); 
  bool _checking = false; // For the checking animation

  void _clearInputFields() {
    _usernameController.clear();
    _passwordController.clear();
    _emailController.clear();
  }

  void _onLoginPressed() {
    Navigator.pushNamed(context, '/login');
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Container(
        child: Row(
          children: [
            // Left side with image
            Expanded(
              flex: 1,
              child: SizedBox(
                width: 400,
                height: 600,
                child: Image.asset('assets/1.png', fit: BoxFit.cover),
              ),
            ),
            // Right side with data fields
            Expanded(
              flex: 2,
              child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/lb.jpg'),
              fit: BoxFit.cover,
            ),
          ),
              
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    // Username
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                      controller: _usernameController,
                      onChanged: (username) {
                      },
                      decoration: InputDecoration(
                      labelText: 'Username',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                      labelStyle: TextStyle(fontSize: 20, color: Color.fromARGB(255, 255, 255, 255)),
                      floatingLabelAlignment: FloatingLabelAlignment.center
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                    ),
                    // Password (conditionally shown)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                            labelStyle: TextStyle(fontSize: 20,color: Color.fromARGB(255, 255, 255, 255),),
                            floatingLabelAlignment: FloatingLabelAlignment.center
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 255, 255, 255),), 
                        ),
                      ),
                      Container(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: InputBorder.none,
                        contentPadding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                          labelStyle: TextStyle(fontSize: 20,color: Color.fromARGB(255, 255, 255, 255),),
                          floatingLabelAlignment: FloatingLabelAlignment.center
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 255, 255, 255),),
                      ),
                    ),
                    Container(padding: const EdgeInsets.all(12.0)),
                    // Signup button (conditionally enabled)
                    MaterialButton(
                      onPressed: () async {// Get the username and password from the text fields.
                              String username = _usernameController.text;
                              String password = _passwordController.text;
                              String email = _emailController.text;
                              if (username.isEmpty || password.isEmpty) {
                                _showErrorSnackbar('Username and password are required.');
                                return;
                              }
                              if (username.length < 8) {
                                _showErrorSnackbar('Username must be 8 characters long');
                                return;
                              }
                              if (password.length < 8) {
                                _showErrorSnackbar('Password must be 8 characters long');
                                return;
                              }
                              // Show checking animation
                              setState(() {
                                _checking = true;
                              });

                              // Simulate a delay of 2 seconds
                              await Future.delayed(Duration(seconds: 2));

                              // Initialize the database.
                              // 
                              const apiUrl = 'http://127.0.0.1:2819/crtusr'; 
                              final response = await http.post(Uri.parse(apiUrl),body: jsonEncode({'username': username,'password': password,'email': email,}),
                              headers: {'Content-Type': 'application/json',},);

                              // Insert the data into the database.
                              if (response.statusCode == 200) {
                                  int resultCode = int.parse(response.body);
                                if (resultCode == 111) {// Status code 111 indicates successful user creation
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('User successfully signed up!')),
                                );
                                 _clearInputFields();// Navigate to the login screen.
                                  Navigator.pushNamed(context, '/login');
                              } else if (resultCode == 112) {// Status code 112 indicates that the username already exists
                                _clearInputFields();
                                _showErrorSnackbar('Username already taken');
                                setState(() {
                                  _checking = false;
                                });
                              } else if(resultCode==113){
                              // Status code 113 or any other indicates an error
                                _clearInputFields();
                                _showErrorSnackbar('Failed to create user. Please try again.');
                                setState(() {
                                  _checking = false;
                                });
                              }
                              }
                            },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text('Signup', style: TextStyle(fontSize: 20))
                        ],
                      ),
                      color: Color.fromARGB(255, 67, 250, 241),
                      height: 50,
                      minWidth: 120,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    // Text to redirect to login UI
                    const SizedBox(height: 8, width: 20),
                    TextButton(
                      onPressed: () {
                        _onLoginPressed();
                      },
                      child: Column(
                        children: [
                          Text('Already Have Account? Login',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 255, 255, 255))),
                          if (_checking)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    );
  }
}