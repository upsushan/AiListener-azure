import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:voiceassistant/components/constants.dart';

class LanguageTextField extends StatelessWidget {
  final TextEditingController controller;

  final List<String> dropdownItems; // List of dropdown items
  final String? dropdownValue; // Selected dropdown value
  final ValueSetter<String?>? onChanged; // Dropdown value change callback
  final FormFieldValidator<String>? validator;
  final Map<String, String>? itemIcons; // Image paths for dropdown items

  const LanguageTextField({
    Key? key,
    required this.controller,
    required this.dropdownItems,
    required this.dropdownValue,
    required this.onChanged,
    this.validator,
    this.itemIcons, // Update itemIcons property to accept image paths
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Adjust height to accommodate dropdown
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 57,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.grey.shade200,
              border: Border.all(color: white),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonFormField<String>(
                  value: dropdownValue,
                  onChanged: onChanged,
                  items: dropdownItems.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          if (itemIcons != null &&
                              itemIcons![value] !=
                                  null) // Check if item has an associated icon
                            Image.asset(
                              itemIcons![value]!,
                              height: 15,
                              fit: BoxFit.fill,
                            ), // Use associated image
                          const SizedBox(
                              width: 10), // Add spacing between image and text
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: InputBorder.none, // Remove border
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
