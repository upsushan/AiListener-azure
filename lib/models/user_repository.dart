import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:onepref/onepref.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:voiceassistant/pages/login_page.dart';
import 'package:voiceassistant/pages/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/speaking_page.dart';

enum Status {
  Uninitialized,
  Authenticated,
  Authenticating,
  Authenticating1,
  Authenticating2,
  Unauthenticated
}

class UserRepository with ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  final GoogleSignIn _googleSignIn;
  Status _status = Status.Uninitialized;

  UserRepository.instance()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      // Change to nullable User
      if (firebaseUser != null) {
        _onAuthStateChanged(firebaseUser!); // Call the method with nullable User
      }
    });
  }

  Status get status => _status;
  User? get user => _user;

  Future<bool> signIn(
      BuildContext context,
      String email,
      String password,
      ) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();

      // Sign in with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If signInWithEmailAndPassword succeeds, update status and return true
      return true;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
        ),
      );

      // Update status and return false
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }



  Future<bool> signUp(
    BuildContext context,
    String username,
    String email,
    String password,
    String language,
  ) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();

      // Create user with email and password
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the current user
      User? user = _auth.currentUser;

      // Update user profile with username
      await user?.updateDisplayName(username);
      await user?.updatePhotoURL(language);

      // If createUserWithEmailAndPassword succeeds, update status and return true
      _status = Status.Authenticated;
      notifyListeners();

      // Navigate to the next screen
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => const SpeakNow(),
      //   ),
      // );
      return true;
    } catch (e) {
      // Handle errors
      if (e is FirebaseAuthException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.toString()),
          ),
        );
        log(e.message.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
        log(e.toString());
      }

      // Update status and return false
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
                'Password reset link sent successfully. Please check your email.'
                    .tr()),
            titleTextStyle:
                const TextStyle(fontSize: 17, color: Color(0xff222222)),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const LoginPage(),
                  //   ),
                  // );
                  // Perform sign out action
                },
                child: Text('OK'.tr()),
              ),
            ],
          );
        },
      );
      return true;
    } catch (e) {
      // Handle specific error types
      if (e is FirebaseAuthException) {
        // Handle FirebaseAuthException
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.toString()),
          ),
        );
        log(e.message.toString());
      } else {
        // Handle other types of errors (if any)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }

      // Update status and return false
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      _status = Status.Authenticating1;
      notifyListeners();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => const SpeakNow(),
      //   ),
      // );
      return true;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }


  Future<bool> signInWithApple({ required BuildContext context} ) async {


    try {
            _status = Status.Authenticating2;

            final appleprovider = AppleAuthProvider();

            //shows native UI that asks user to show or hide their real email address
            appleprovider.addScope('email'); //this scope is required

            //pulls the user's full name from their Apple account
            appleprovider.addScope('name'); //this is not required

            final userCredential = await _auth.signInWithProvider(appleprovider);


            final displayName = "${userCredential.additionalUserInfo!.profile!['firstName']} ${userCredential.additionalUserInfo!.profile!['lastName']}";

            // Check if the user is not null
            if (userCredential.user != null) {
              // Accessing the displayName property of the User object
              String? username = userCredential.user!.displayName;

              // Do something with the username, like displaying it
              print('The username is: ${userCredential.user} $displayName');
            } else {
              print('No user is signed in.');
            }

          // Navigator.pushReplacement(
          // context,
          // MaterialPageRoute(
          // builder: (context) => const SpeakNow(),
          // ),
          // );
          return true;
    }catch (e) {
          print(e);
          _status = Status.Unauthenticated;
          notifyListeners();
          return false;
          }
    }

  Future<void> deleteAccount() async {
    try {

      if(_auth.currentUser!.email == "guest@gmail.com"){
        Fluttertoast.showToast(msg: "Sorry, you cannot delete guest account");
      }else {
        if (_auth.currentUser!.providerData[0].providerId == 'google.com') {
          await _googleSignIn.signOut();
        }
        await _auth.currentUser!.delete();

        await _auth.signOut();

        _status = Status.Unauthenticated;
        notifyListeners();

        _user = null; // Clear the user after sign-out

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const LoginPage(),
        //   ), // This condition ensures all routes will be removed
        // );
      }

    } catch (e) {
      print("Error signing out: $e");
      Fluttertoast.showToast(msg: "Deleting account requires a recent login. Please re-login and try again.");
      // Handle any errors that occur during sign-out
    }
  }


  Future<void> signOut() async {
    try {

      if(_auth.currentUser!.providerData[0].providerId == 'google.com'){
        await _googleSignIn.signOut();
      }
     await _auth.signOut();


      _status = Status.Unauthenticated;
      notifyListeners();

      _user = null; // Clear the user after sign-out

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => const LoginPage(),
      //   ), // This condition ensures all routes will be removed
      // );


    } catch (e) {
      print("Error signing out: $e");
      // Handle any errors that occur during sign-out
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      _user = firebaseUser;
      if (_status != Status.Authenticated) {
        _status = Status.Authenticated;
        notifyListeners();
      }
    } else {
      if (_status != Status.Unauthenticated) {
        _status = Status.Unauthenticated;
        notifyListeners();
      }
    }
  }
}