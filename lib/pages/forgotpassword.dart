import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/models/user_repository.dart';
import 'package:voiceassistant/pages/login_page.dart';

import '../components/email_textfield.dart';
import '../components/my_button.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<ForgotPassword> {
  // text editing controllers
  final usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);
    return Scaffold(
      backgroundColor: secondaryColor,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
                      "Forgot Password".tr(),
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          color: black.withOpacity(0.5), fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Container(
                    child: Image.asset(
                      'assets/images/resetpassword.png',
                      width: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  "Change your password".tr(),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 5),
                Text("We will send you a link to reset your password".tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium!
                        .copyWith(color: black.withOpacity(0.4))),
                const SizedBox(height: 20),
                EmailTextField(
                  controller: usernameController,
                  hintText: 'Email'.tr(),
                  validator: (value) =>
                      (value!.isEmpty) ? "Please Enter Email".tr() : null,
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                user.status == Status.Authenticating
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : InkWell(
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            if (!await user.resetPassword(
                              context,
                              usernameController.text,
                            )) {}
                          }
                        },
                        child:  MyButton(
                          buttonName: "Send Email".tr(),
                        ),
                      ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
