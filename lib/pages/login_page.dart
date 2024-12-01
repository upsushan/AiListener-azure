import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:onepref/onepref.dart';
import 'package:provider/provider.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/pages/forgotpassword.dart';
import 'package:voiceassistant/pages/register_page.dart';
import 'package:voiceassistant/pages/speaking_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/email_textfield.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/tile.dart';
import '../models/user_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool googleTapped = false;
  bool appleTapped = false;

  IApEngine iApEngine = IApEngine();

  @override
  void initState() {
    super.initState();
    iApEngine.inAppPurchase.restorePurchases();
    iApEngine.inAppPurchase.purchaseStream.listen((list) async {
      if (list.isNotEmpty) {
        int i = 0;
        for (var element in list) {
          log(list[i].verificationData.localVerificationData);
          i++;
        }
        OnePref.setPremium(true);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('premium', true);
      } else {
        OnePref.setPremium(false);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('premium', false);
      }
    });
  }

  void restoreSub() {
    iApEngine.inAppPurchase.restorePurchases();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);
    final user1 = Provider.of<UserRepository>(context);
    return Center(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: secondaryColor,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 100.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Container(
                      child: Image.asset(
                        'assets/images/echoassist.png',
                        width: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  EmailTextField(
                    controller: usernameController,
                    hintText: 'Email'.tr(),
                    validator: (value) =>
                        (value!.isEmpty) ? "Please Enter Email".tr() : null,
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  PasswordTextField(
                    validator: (value) =>
                        (value!.isEmpty) ? "Please Enter Password".tr() : null,
                    controller: passwordController,
                    hintText: 'Password'.tr(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 25.0, right: 40),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const ForgotPassword()));
                        },
                        child: Text(
                          'Forgot Password?'.tr(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  user.status == Status.Authenticating
                      ?  Center(
                          child: CircularProgressIndicator(color: mainColor,),
                        )
                      : InkWell(
                          onTap: () async {
                            if (_formKey.currentState!.validate()) {
                              if (!await user.signIn(
                                  context,
                                  usernameController.text,
                                  passwordController.text)) {}
                            }
                          },
                          child: MyButton(
                            buttonName: "Sign in".tr(),
                          ),
                        ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New User? ".tr(), style: TextStyle(color: Colors.grey[600])),
                            GestureDetector(
                              onTap: (){
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => const RegisterPage(email: "", password: "",)));
                              },
                              child:
                              Text("Sign up".tr(), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),

                            ),
                          ],
                        ),

                        GestureDetector(
                            onTap: ()async{
                              await user.signIn(
                                  context,
                                  "guest@gmail.com",
                                  "passwd#.");
                            },
                            child: Text("Guest Login".tr(), style: TextStyle(color: Colors.grey[600]))),

                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with'.tr(),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        child:
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity: googleTapped ? 0.2 : 1,
                                    child: const Tile(imagePath: 'assets/images/google.png')),

                                  if(googleTapped)
                                  SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      color: mainColor,
                                    ),
                                  )
                              ],
                            ),
                        onTap: () async {

                          setState(() {
                            googleTapped = true;
                          });
                          if (!await user.signInWithGoogle(context)) {

                            setState(() {
                              googleTapped = false;
                            });

                          }
                        },
                      ),
                      const SizedBox(width: 25),
                      InkWell(
                        child: Opacity(
                            opacity: appleTapped ? 0.2 : 1,
                            child: const Tile(imagePath: 'assets/images/apple.png')),

                        onTap: () async {

                          setState(() {
                            appleTapped = true;
                          });
                          if (!await user.signInWithApple(context: context)) {

                            setState(() {
                              appleTapped = false;
                            });

                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
