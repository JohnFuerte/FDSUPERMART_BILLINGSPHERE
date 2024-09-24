import 'package:billingsphere/auth/providers/login_provider.dart';
import 'package:billingsphere/helper/constants.dart';
import 'package:billingsphere/logic/cubits/user_cubit/user_cubit.dart';
import 'package:billingsphere/logic/cubits/user_cubit/user_state.dart';
import 'package:billingsphere/screens/foundation/Login_screen_resposive.dart/login_widgets.dart/hidden_password.dart';
import 'package:billingsphere/screens/splash/splashScreen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  static const String routeName = "login";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context, listen: true);
    var size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: BlocListener<UserCubit, UserState>(
        listener: (context, state) {
          if (state is UserLoggedInState) {
            Navigator.pushReplacementNamed(context, SplashScreen.routeName);
          }
        },
        child: Scaffold(
          backgroundColor: white,
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildWideScreen(size, provider);
              } else {
                return _buildSmallScreen(size, provider);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideScreen(Size size, LoginProvider provider) {
    return Stack(
      children: [
        // Background image
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/loginbg2.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Container with colored background and icon
        Positioned(
          top: MediaQuery.of(context).size.height /
              4, // Adjust the position as needed
          right: 50,
          width: 380, // Adjust the position as needed
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color.fromRGBO(28, 28, 28, 1), // Adjust opacity if needed
            ),
            child: Form(
              key: provider.formKey,
              child: Column(
                children: [
                  40.heightBox,
                  Text(
                    "Sign In",
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  10.heightBox,
                  Text(
                    "Your FD Super Mart",
                    style: GoogleFonts.lato(
                      color: const Color.fromRGBO(122, 122, 122, 1),
                      fontSize: 14,
                    ),
                  ),
                  20.heightBox,
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: Color.fromRGBO(39, 39, 39, 1))),
                      10.widthBox,
                      Text(
                        "Sign-In with Email",
                        style: GoogleFonts.lato(
                          color: const Color.fromRGBO(92, 92, 92, 1),
                          fontSize: 12,
                        ),
                      ),
                      10.widthBox,
                      const Expanded(
                          child: Divider(color: Color.fromRGBO(39, 39, 39, 1))),
                    ],
                  ),
                  20.heightBox,
                  Container(
                    // height: 40,
                    decoration: const BoxDecoration(
                        color: Color.fromRGBO(40, 40, 40, 1),
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Center(
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Email",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                        ),
                        controller: provider.emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!EmailValidator.validate(value.trim())) {
                            return "Invalid email address";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  20.heightBox,
                  HiddenPassword(
                    controller: provider.passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      } else if (value.length < 6) {
                        return 'Please provide a password with a minimum of six characters.';
                      } else if (value.length > 13) {
                        return 'Your password does not exceed a maximum of 13 characters.';
                      }
                      return null;
                    },
                  ),
                  // Container(
                  //   // height: 40,
                  //   decoration: const BoxDecoration(
                  //       color: Color.fromRGBO(40, 40, 40, 1),
                  //       borderRadius: BorderRadius.all(Radius.circular(4))),
                  //   child: Center(
                  //     child: TextFormField(
                  //       style: const TextStyle(color: Colors.white),
                  //       decoration: const InputDecoration(
                  //         hintText: "Password",
                  //         hintStyle: TextStyle(color: Colors.grey),
                  //         border: OutlineInputBorder(),
                  //         contentPadding:
                  //             EdgeInsets.symmetric(vertical: 1, horizontal: 10),
                  //       ),
                  //       controller: provider.passwordController,
                  //       validator: (value) {
                  //         if (value == null || value.isEmpty) {
                  //           return 'Please enter your password';
                  //         } else if (value.length < 6) {
                  //           return 'Please provide a password with a minimum of six characters.';
                  //         } else if (value.length > 13) {
                  //           return 'Your password does not exceed a maximum of 13 characters.';
                  //         }
                  //         return null;
                  //       },
                  //     ),
                  //   ),
                  // ),

                  20.heightBox,
                  (provider.error != "")
                      ? Text(
                          provider.error,
                          style: const TextStyle(
                              color: red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        )
                      : const SizedBox(),
                  (provider.error != "")
                      ? SizedBox(
                          height: size.height * 0.01,
                        )
                      : const SizedBox(),
                  (provider.isLoading)
                      ? const CircularProgressIndicator(
                          color: white,
                        )
                      : ElevatedButton(
                          onPressed: () {
                            provider.logIn();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(198, 199, 248, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const SizedBox(
                            height: 30,
                            child: Center(
                              child: Text(
                                "Sign In",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                  40.heightBox,
                ],
              ).px32(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreen(Size size, LoginProvider provider) {
    return Stack(
      children: [
        // Background image
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/loginbg2.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Container with colored background and icon
        Positioned(
          top: MediaQuery.of(context).size.height /
              4, // Adjust the position as needed
          right: 50,
          width: 380, // Adjust the position as needed
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color.fromRGBO(28, 28, 28, 1), // Adjust opacity if needed
            ),
            child: Column(
              children: [
                40.heightBox,
                Text(
                  "Sign In",
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                10.heightBox,
                Text(
                  "Your FD Super Mart",
                  style: GoogleFonts.lato(
                    color: const Color.fromRGBO(122, 122, 122, 1),
                    fontSize: 14,
                  ),
                ),
                20.heightBox,
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: Color.fromRGBO(39, 39, 39, 1))),
                    10.widthBox,
                    Text(
                      "Sign-In with Email",
                      style: GoogleFonts.lato(
                        color: const Color.fromRGBO(92, 92, 92, 1),
                        fontSize: 12,
                      ),
                    ),
                    10.widthBox,
                    const Expanded(
                        child: Divider(color: Color.fromRGBO(39, 39, 39, 1))),
                  ],
                ),
                20.heightBox,
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(40, 40, 40, 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Center(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: "Email",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                      ),
                      controller: provider.emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!EmailValidator.validate(value.trim())) {
                          return "Invalid email address";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                20.heightBox,
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(40, 40, 40, 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Center(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: "Password",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 1, horizontal: 10),
                      ),
                      controller: provider.passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        } else if (value.length < 6) {
                          return 'Please provide a password with a minimum of six characters.';
                        } else if (value.length > 13) {
                          return 'Your password does not exceed a maximum of 13 characters.';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                20.heightBox,
                ElevatedButton(
                  onPressed: () {
                    provider.logIn();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(198, 199, 248, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const SizedBox(
                    height: 30,
                    child: Center(
                      child: Text(
                        "Sign In",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                40.heightBox,
              ],
            ).px32(),
          ),
        ),
      ],
    );
  }
}
