import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class Utils{

  Future<void> showToastMessage(String message, BuildContext context) async {
    showToast(
      message,
      context: context,
      animation: StyledToastAnimation.slideFromBottom,
      reverseAnimation: StyledToastAnimation.slideToBottom,
      position: StyledToastPosition.bottom,
      animDuration: Duration(milliseconds: 400),
      duration: Duration(seconds: 2),
      curve: Curves.elasticOut,
      reverseCurve: Curves.elasticIn,
    );
  }

  String getCurrentUserUID() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // The user is logged in
      return user.uid;
    } else {
      // No user is logged in
      return ""; // Return an empty string or null to indicate no user is logged in
    }
  }

  Future<String?> getCurrentUserEmail() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      // User is signed in
      return user.email;
    } else {
      // No user is signed in
      return null;
    }
  }

}