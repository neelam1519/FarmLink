import 'package:farmlink/Home.dart';
import 'package:farmlink/Login/register.dart';
import 'package:farmlink/details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //_initializeHERESDK();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      builder: EasyLoading.init(), // Initialize EasyLoading
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  bool isTransporter = false; // Initialize isTransporter to false

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading indicator while checking authentication state
        } else if (snapshot.hasData) {
          return Home(isTransporter: isTransporter); // Pass the isTransporter value to the Home widget
        } else {
          return LoginPage(); // If no user is logged in, show the login page
        }
      },
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool isTransporter=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _handleEmailSignIn(_emailController.text, _passwordController.text);
                },
                child: const Text('Submit'),
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Add logic for creating an account
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => RegisterUserPage()), // Replace Home() with your home page widget
                        );
                      },
                      child: Text(
                        'Create Account',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Add logic for forgot password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Add space between buttons and "or" text
                Text(
                  'or',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _handleGoogleSignIn();
                },
                icon: Icon(Icons.account_circle),
                label: Text('Sign in with Google'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      EasyLoading.show(status: 'Signing in...'); // Show loading indicator
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        // Successfully signed in with Google
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = authResult.user;

        // Check if the user is new or existing
        final bool isNewUser = authResult.additionalUserInfo!.isNewUser;

        if (isNewUser) {
          // This is a new user
          print('New user signed in with Google: ${user?.displayName}');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginDetails()), // Replace Home() with your home page widget
          );
        } else {
          // This is an existing user
          print('Existing user signed in with Google: ${user?.displayName}');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Home(isTransporter: isTransporter)), // Replace Home() with your home page widget
          );
        }
      } else {
        // User canceled the sign-in
        print('Google Sign in canceled.');
      }
    } catch (error) {
      print('Error signing in with Google: $error');
    } finally {
      // Dismiss the loading dialog after sign-in operation completes
      EasyLoading.dismiss();
    }
  }

  void _handleEmailSignIn(String email, String password) async {
    try {
      EasyLoading.show(status: 'Signing in...'); // Show loading indicator
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Authentication successful, user is signed in
      User? user = userCredential.user;
      print('User signed in: ${user!.uid}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginDetails()), // Replace Home() with your home page widget
      );
      // Navigate to the home page or perform any other actions
    } catch (error) {
      // Handle authentication failure
      print('Error signing in with email and password: $error');
      // You can display an error message to the user or handle the error in other ways
    } finally {
      // Dismiss the loading dialog after sign-in operation completes
      EasyLoading.dismiss();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
