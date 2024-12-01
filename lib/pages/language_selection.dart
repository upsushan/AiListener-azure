import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/const/app_images_const.dart';
import 'package:voiceassistant/models/flag_provider.dart';
import 'package:voiceassistant/models/user_repository.dart';
import 'package:voiceassistant/pages/settings.dart';
import 'package:voiceassistant/pages/subscription_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelection extends StatefulWidget {
  const LanguageSelection({Key? key}) : super(key: key);
  @override
  State<LanguageSelection> createState() => _LanguageSelectionState();
}

class _LanguageSelectionState extends State<LanguageSelection> {
  late SharedPreferences prefs;
  bool prefInitialized = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? selectedLanguage;
  Locale _currentLocale = const Locale('en', 'US');
  @override
  void initState() {
    super.initState();
    selectedLanguage = getLanguage();
    if (selectedLanguage == null ||
        selectedLanguage!.isEmpty ||
        selectedLanguage != "English" ||
        selectedLanguage != "Spanish" ||
        selectedLanguage != "German") {
      selectedLanguage = "English";
    }
    getPremiumStatus();
  }

  Future<void> getPremiumStatus() async {
    prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('lang') ?? "English";
    setState(() {
      prefInitialized = true;
    });
    // Return false if the value is not found
  }

  String? getLanguage() {
    User? user = _auth.currentUser;
    return user?.photoURL;
  }

  @override
  Widget build(BuildContext context) {
    log(selectedLanguage.toString());
    TextStyle settingsStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: black.withOpacity(0.5),
    );
    final flagImageProvider =
        Provider.of<FlagImageProvider>(context, listen: false);
    return SafeArea(
      child: Scaffold(
        backgroundColor: secondaryColor,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 5.h,
              ),
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
                        height: 25.h,
                        width: 25.w,
                        color: white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Change Language".tr(),
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: black.withOpacity(0.5), fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              ListTile(
                  leading: Image.asset(
                    AppImagesConst.kusaFlag,
                    height: 25,
                  ),
                  title: Text(
                    'English'.tr(),
                    style: settingsStyle,
                  ),
                  trailing: selectedLanguage == "English"
                      ? Icon(Icons.check, color: mainColor)
                      : null,
                  onTap: () {
                    prefs.setString('lang',"English");
                    setState(() {
                      selectedLanguage = 'English';
                    });
                    const newLocale = Locale('en', 'US');
                    EasyLocalization.of(context)?.setLocale(newLocale);
                    setState(() {
                      _currentLocale = newLocale;
                    });
                    flagImageProvider.setImagePath(AppImagesConst.kusaFlag);
                  }),
              const Divider(),
              ListTile(
                leading: Image.asset(
                  AppImagesConst.kspainFlag,
                  height: 25,
                ),
                title: Text(
                  'Spanish'.tr(),
                  style: settingsStyle,
                ),
                trailing: selectedLanguage == "Spanish"
                    ? Icon(Icons.check, color: mainColor)
                    : null,
                onTap: () {
                  prefs.setString('lang',"Spanish");
                  setState(() {
                    selectedLanguage = 'Spanish';
                  });
                  const newLocale = Locale('es', 'ES');
                  EasyLocalization.of(context)?.setLocale(newLocale);
                  setState(() {
                    _currentLocale = newLocale;
                  });
                  flagImageProvider.setImagePath(AppImagesConst.kspainFlag);
                },
              ),
              const Divider(),
              ListTile(
                leading: Image.asset(
                  AppImagesConst.kgermanyFlag,
                  height: 25,
                ),
                title: Text(
                  'German'.tr(),
                  style: settingsStyle,
                ),
                trailing: selectedLanguage == "German"
                    ? Icon(Icons.check, color: mainColor)
                    : null,
                onTap: () {
                  prefs.setString('lang',"German");
                  setState(() {
                    selectedLanguage = 'German';
                  });
                  const newLocale = Locale('de', 'DE');
                  EasyLocalization.of(context)?.setLocale(newLocale);
                  setState(() {
                    _currentLocale = newLocale;
                  });
                  flagImageProvider.setImagePath(AppImagesConst.kgermanyFlag);
                },
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
