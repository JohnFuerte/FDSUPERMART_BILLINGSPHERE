import 'package:flutter/material.dart';

class HiddenPassword extends StatefulWidget {
  final TextEditingController controller;

  final String? Function(String?)? validator;
  const HiddenPassword({super.key, required this.controller, this.validator});

  @override
  State<HiddenPassword> createState() => _HiddenppasswordState();
}

class _HiddenppasswordState extends State<HiddenPassword> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 50,
      decoration: const BoxDecoration(
          color: Color.fromRGBO(40, 40, 40, 1),
          borderRadius: BorderRadius.all(Radius.circular(4))),

      child: Center(
        child: TextFormField(
          style: const TextStyle(color: Colors.white),
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: "Password",
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 1, horizontal: 10),
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              child: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
