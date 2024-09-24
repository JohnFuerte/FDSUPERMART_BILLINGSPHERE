import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Constants {
  // static String baseUrl = 'https://fd-super-mart-backend-render.onrender.com/api';
  static String baseUrl = 'https://15.206.104.143/api';

  static Widget loadingIndicator = Lottie.asset(
    'assets/lottie/loader.json',
    width: 120,
    height: 120,
    fit: BoxFit.cover,
  );
}
