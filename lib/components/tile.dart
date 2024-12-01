import 'package:flutter/material.dart';
import 'package:voiceassistant/components/constants.dart';

class Tile extends StatelessWidget {
  final String imagePath;
  const Tile({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color:white),
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: Image.asset(
        imagePath,
        height: 40,
      ),
    );
  }
}