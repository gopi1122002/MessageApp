import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'register.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim(); // ✅ Make sure this controller exists
    final email = '$mobile@domain.com';

    try {
      UserCredential credential;
      if (_isLogin) {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('User logged in: ${credential.user!.uid}');
      } else {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'mobile': mobile,
          'email': email,
          'username': username, // ✅ Save username at registration
          'isAdmin': mobile == '1234567890',
          'timestamp': Timestamp.now(),
        });
      }

      final docRef =
      FirebaseFirestore.instance.collection('users').doc(credential.user!.uid);
      var doc = await docRef.get();

      if (!doc.exists) {
        //  Always include username
        await docRef.set({
          'uid': credential.user!.uid,
          'mobile': mobile,
          'email': email,
          'username': username, // Fix here
          'isAdmin': mobile == '1234567890',
          'timestamp': Timestamp.now(),
        });
        doc = await docRef.get();
      }

      final data = doc.data()!;
      print('Firestore User Data: $data');

      if (data.containsKey('isAdmin') && data['isAdmin'] == true) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/user');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage('Auth Error: ${e.message}');
    } catch (e, stack) {
      _showMessage('Error: $e');
      print(e);
      print(stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin ? 'MessageApp' : 'MessageApp',
          style: TextStyle(color: Colors.white), // White text color here
        ),
        centerTitle: true,
        backgroundColor: Colors.blue, // Your blue shade
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled, // Show error only after user types
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mobile Number Field
                  TextFormField(

                    cursorColor: Colors.grey[600],
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      labelStyle: TextStyle(color: Colors.grey),
                      floatingLabelStyle: TextStyle(color: Colors.blue),
                      prefixIcon: Icon(Icons.phone_android, color: Colors.black45),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter mobile number';
                      } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Mobile number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    cursorColor: Colors.grey[600],
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey),
                      floatingLabelStyle: TextStyle(color: Colors.blue),
                      prefixIcon: Icon(Icons.lock, color: Colors.black45),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter valid password';
                      } else if (value.length > 8) {
                        return 'Maximum 8 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Login/Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _isLogin ? 'Login' : 'Register',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        backgroundColor: Colors.blue[400],
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Register Redirect
                  RichText(
                    text: TextSpan(
                      text: 'Need an account? ',
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                      children: [
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],

              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }
}
