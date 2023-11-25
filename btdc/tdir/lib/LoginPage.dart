// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously, sort_child_properties_last, avoid_unnecessary_containers, prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // final _emailController =TextEditingController();
  bool _checking = false;

  Future<void> _onLoginPressed() async {
    // Get the username and password from the text fields.
    String username = _usernameController.text;
    String password = _passwordController.text;
    const apiUrl = 'http://127.0.0.1:2819/lgusr'; 
    final response = await http.post(Uri.parse(apiUrl),body: jsonEncode({'username': username,'password': password,}),
    headers: {'Content-Type': 'application/json'},);
    if (response.statusCode == 200) {
  Map<String, dynamic> responseData = json.decode(response.body);

  int resultCode = responseData['status_code'];
  if (resultCode == 430) {
    // Successful login
    String email = responseData['email'];
    // Do something with the email, if needed
    Navigator.pushNamed(context, '/welcome', arguments: {'username': username , 'email':email});
  } else if (resultCode == 428) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User Not Found.'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
        _checking = false;
      });
      _usernameController.clear();
      _passwordController.clear();
  } else if (resultCode == 429) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid username or password.'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
        _checking = false;
      });
      _usernameController.clear();
      _passwordController.clear();
  }
}
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      
      body: Container(
    // decoration: BoxDecoration(
    //     image: DecorationImage(
    //       image: AssetImage('assets/lb.jpg'),
    //       fit: BoxFit.cover,
    //      ),
    //     ),
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
              image: AssetImage('assets/lb2.jpg'),
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
                      decoration: const BoxDecoration(),
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                          labelStyle: TextStyle(fontSize: 20,
                            color: Color.fromARGB(255, 0, 0, 0), ),
                            floatingLabelAlignment: FloatingLabelAlignment.center
                            
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Password
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 18.0, bottom: 16.0),
                          labelStyle: TextStyle(fontSize: 20,
                            color: Color.fromARGB(255, 0, 0, 0),),
                            floatingLabelAlignment: FloatingLabelAlignment.center
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.bold)
                      ),
                    ),
                    Container(padding: const EdgeInsets.all(12.0)),
                    // Login button
                    MaterialButton(
                      onPressed: () async {
                        String username = _usernameController.text;
                        String password = _passwordController.text;
                        // Check if the username and password are valid.
                        if (username.isEmpty || password.isEmpty) {
                          // The username or password is empty.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a username and password.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _checking = true;
                        });

                        // Simulate a delay of 2 seconds
                        await Future.delayed(Duration(seconds: 1));
                        _onLoginPressed();
                      },
                      child: const Text('Login', style: TextStyle(fontSize: 20)),
                      color: const Color.fromARGB(255, 67, 250, 241),
                      height: 50,
                      minWidth: 120,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      // Increase the font size of the button
                    ),
                    // Text to redirect to signup UI
                    const SizedBox(height: 8, width: 20,),
                    TextButton(
                      onPressed: () {
                        // Redirect to signup screen
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('Don\'t have an account? Signup', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 255, 251))),
                    ),
                    if (_checking)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            ),
          ],
          // Divider between the two sides
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // 1:2 ratio for the two sides
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    );
  }
}