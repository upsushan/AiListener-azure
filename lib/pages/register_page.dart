import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/components/language_dropdown.dart';
import 'package:voiceassistant/components/username_textfield.dart';
import 'package:voiceassistant/const/app_images_const.dart';
import 'package:voiceassistant/models/flag_provider.dart';
import 'package:voiceassistant/components/constants.dart';
import '../components/email_textfield.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/tile.dart';
import '../models/user_repository.dart';

class RegisterPage extends StatefulWidget {
  final String? email;
  final String? password;
  const RegisterPage({super.key, required this.email, required this.password});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<RegisterPage> {
  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final languageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (emailController.text.isEmpty) {
      setState(() {
        emailController.text = widget.email.toString();
      });
    } else {
      emailController.text = "";
    }
    if (passwordController.text.isEmpty) {
      setState(() {
        passwordController.text = widget.password.toString();
      });
    } else {
      passwordController.text = "";
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    languageController.dispose();
    super.dispose();
  }

  Locale _currentLocale = const Locale('en', 'US');



  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);
    final flagImageProvider =
        Provider.of<FlagImageProvider>(context, listen: false);

    if(user.status == Status.Authenticated){
      Future.delayed(const Duration(seconds: 1)).then((val) {
        Navigator.pop(context);
      });

    }

    return Center(
      child: Scaffold(
        backgroundColor: secondaryColor,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          backgroundColor: mainColor,
                          radius: 20,
                          child: Image.asset(
                            'assets/images/left.png',
                            height: 25,
                            width: 25,
                            color: white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Sign up".tr(),
                        style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            color: black.withOpacity(0.5), fontSize: 24),
                      ),
                    ],
                  ),

                  SizedBox(height: 50,),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Container(
                        child: Image.asset(
                          'assets/images/echoassist.png',
                          width: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  UserNameTextField(
                    controller: usernameController,
                    hintText: 'Full Name'.tr(),
                    validator: (value) =>
                        (value!.isEmpty) ? "Please Enter UserName".tr() : null,
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  EmailTextField(
                    controller: emailController,
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
                  LanguageTextField(
                    validator: (value) =>
                        (value!.isEmpty) ? "Please Select Language".tr() : null,
                    controller: languageController,
                    dropdownItems: [
                      'English'.tr(),
                      'Spanish'.tr(),
                      'German'.tr()
                    ],
                    dropdownValue: 'English'.tr(),
                    itemIcons: {
                      'English'.tr(): AppImagesConst.kusaFlag,
                      'Spanish'.tr(): AppImagesConst.kspainFlag,
                      'German'.tr(): AppImagesConst.kgermanyFlag,
                    },
                    onChanged: (String? value) {
                      languageController.text = value!;
                    },
                  ),
                  const SizedBox(height: 40),
                  user.status == Status.Authenticating
                      ?  Center(
                          child: CircularProgressIndicator(color: mainColor,),
                        )
                      : InkWell(
                          onTap: () async {

                            if (languageController.text.isEmpty) {
                              setState(() {
                                languageController.text = "English".tr();
                              });
                            }
                            log(languageController.text);
                            if (languageController.text == "English".tr()) {
                              const newLocale = Locale('en', 'US');
                              EasyLocalization.of(context)
                                  ?.setLocale(newLocale);
                              setState(() {
                                _currentLocale = newLocale;
                              });
                              flagImageProvider
                                  .setImagePath(AppImagesConst.kusaFlag);
                            } else if (languageController.text == "Spanish".tr()) {
                              const newLocale = Locale('es', 'ES');
                              EasyLocalization.of(context)
                                  ?.setLocale(newLocale);
                              setState(() {
                                _currentLocale = newLocale;
                              });
                              flagImageProvider
                                  .setImagePath(AppImagesConst.kspainFlag);
                            } else if (languageController.text == "German".tr())  {
                              const newLocale = Locale('de', 'DE');
                              EasyLocalization.of(context)
                                  ?.setLocale(newLocale);
                              setState(() {
                                _currentLocale = newLocale;
                              });
                              flagImageProvider
                                  .setImagePath(AppImagesConst.kgermanyFlag);
                            }

                            if (_formKey.currentState!.validate()) {



                              if (!await user.signUp(
                                  context,
                                  usernameController.text,
                                  emailController.text,
                                  passwordController.text,
                                  languageController.text)) {}
                            }
                          },
                          child: MyButton(
                            buttonName: "Sign up".tr(),
                          ),
                        ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
