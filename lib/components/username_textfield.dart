import 'package:flutter/material.dart';
import 'package:voiceassistant/components/constants.dart';

class UserNameTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final FormFieldValidator<String>? validator; // Add validator parameter

  const UserNameTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.validator, // Update constructor to accept validator
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 320,
      child: Column(
        children: [
          SizedBox(
            height: 57,
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator, // Pass validator to TextFormField
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.person),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: white),
                  borderRadius: BorderRadius.circular(25),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor),
                  borderRadius: BorderRadius.circular(25),
                ),
                fillColor: Colors.grey.shade200,
                filled: true,
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
