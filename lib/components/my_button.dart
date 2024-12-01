import 'package:flutter/material.dart';
import 'package:voiceassistant/components/constants.dart';

class MyButton extends StatelessWidget {
  final String buttonName;

  const MyButton({super.key, required this.buttonName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        height: 57,
        width: 320,
        decoration: BoxDecoration(
          color:mainColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child:Center(
          child: Text(
            buttonName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}