import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:onepref/onepref.dart';
import 'package:provider/provider.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/const/app_images_const.dart';
import 'package:voiceassistant/models/flag_provider.dart';
import 'package:voiceassistant/models/user_repository.dart';
import 'package:voiceassistant/pages/language_selection.dart';
import 'package:voiceassistant/pages/login_page.dart';
import 'package:voiceassistant/pages/other-pages.dart';
import 'package:voiceassistant/pages/speaking_page.dart';
import 'package:voiceassistant/pages/subscription_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class settings extends StatefulWidget {
  const settings({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<settings> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SharedPreferences prefs;
  bool prefInitialized = false;

  String? getUsername() {
    User? user = _auth.currentUser;
    return user?.displayName;
  }

  bool premium = false;
  String selectedLanguage = "English";
  int wordCount  = 0;
  @override
  void initState() {
    getPremiumStatus();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  Future<void> getPremiumStatus() async {
     prefs = await SharedPreferences.getInstance();
    setState(() {
      prefInitialized = true;
    });
    // Return false if the value is not found
  }

  @override
  Widget build(BuildContext context) {

    if(prefInitialized) {
      premium = prefs.getBool('premium') ?? false;
      selectedLanguage = prefs.getString('lang') ?? "English";
      wordCount = prefs.getInt('leftWords') ?? 500;
    }

    TextStyle settingsStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: black.withOpacity(0.5),
    );
    final flagImageProvider =
        Provider.of<FlagImageProvider>(context, listen: false);

    // Get the image path
    final usaFlagImagePath = flagImageProvider.imagePath;

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
                    "Settings".tr(),
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: black.withOpacity(0.5), fontSize: 24),
                  ),
                ],
              ),
              SizedBox(
                height: 20.h,
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: mainColor,
                      radius: 30,
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          'assets/images/profileimg.png',
                          height: 35.h,
                          width: 35.w,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getUsername() ?? "",
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(color: mainColor, fontSize: 24),
                        ),
                        Text(
                          premium
                              ? "${'Premium Account'.tr()} | ${'Unlimited'.tr()} ${'Words'.tr()}"
                              : "${'Demo Account'.tr()} | $wordCount ${'Words'.tr()}",
                          style: TextStyle(
                              color: mainColor.withOpacity(0.9), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Text("General Settings".tr(),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      color: black.withOpacity(0.5),
                      fontSize: 18,
                      fontWeight: FontWeight.w400)),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: mainColor,
                ),
                title: Text(
                  'Change Language'.tr(),
                  style: settingsStyle,
                ),
                trailing: selectedLanguage != "English"
                    ? Image.asset(
                  selectedLanguage == "Spanish" ? AppImagesConst.kspainFlag : AppImagesConst.kgermanyFlag,
                        height: 25,
                      )
                    : Image.asset(
                        AppImagesConst.kusaFlag,
                        height: 25,
                      ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LanguageSelection()));
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.money,
                  color: mainColor,
                ),
                title: Text(
                  'Manage Subscription'.tr(),
                  style: settingsStyle,
                ),
                trailing: Image.asset(
                  'assets/images/next.png',
                  height: 25,
                  color: black.withOpacity(0.2),
                ),
                onTap: () {
                  // Navigate to subscription management screen or implement subscription logic
                  if(!premium) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const subscription()));
                  }else{
                    Fluttertoast.showToast(msg: "You are currently subscribed!".tr());
                  }
                },
              ),
              const Divider(),
              const SizedBox(
                height: 20,
              ),
              Text("Others".tr(),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      color: black.withOpacity(0.5),
                      fontSize: 18,
                      fontWeight: FontWeight.w400)),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                leading: Icon(Icons.list, color: mainColor),
                title: Text(
                  'Terms and Conditions'.tr(),
                  style: settingsStyle,
                ),
                trailing: Image.asset(
                  'assets/images/next.png',
                  height: 25,
                  color: black.withOpacity(0.2),
                ),
                onTap: () {

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  OtherPages(pagename: "Terms and Conditions",)));

                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.add_box, color: mainColor),
                title: Text(
                  'Privacy Policy'.tr(),
                  style: settingsStyle,
                ),
                trailing: Image.asset(
                  'assets/images/next.png',
                  height: 25,
                  color: black.withOpacity(0.2),
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>  OtherPages(pagename: "Privacy Policy",)));

                },
              ),
              // const Divider(),
              // ListTile(
              //   leading: Icon(Icons.star, color: mainColor),
              //   title: Text(
              //     'Rate the App'.tr(),
              //     style: settingsStyle,
              //   ),
              //   trailing: Image.asset(
              //     'assets/images/next.png',
              //     height: 25,
              //     color: black.withOpacity(0.2),
              //   ),
              //   onTap: () {
              //     // Open app store for rating or implement your own rating logic
              //     // Example: launch('https://play.google.com/store/apps/details?id=com.your.app.package');
              //   },
              // ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: mainColor),
                title: Text(
                  'Sign Out'.tr(),
                  style: settingsStyle,
                ),
                trailing: Image.asset(
                  'assets/images/next.png',
                  height: 25,
                  color: black.withOpacity(0.2),
                ),
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Are You Sure You Want to Sign Out?'.tr()),
                        titleTextStyle: const TextStyle(
                            fontSize: 18, color: Color(0xff222222)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                  false); // Close the dialog and return false
                            },
                            child: Text('No'.tr()),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Perform sign out action
                              await Provider.of<UserRepository>(context,
                                      listen: false).signOut();

                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text('Yes'.tr()),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.cancel, color: mainColor),
                title: Text(
                  'Delete Account'.tr(),
                  style: settingsStyle,
                ),
                trailing: Image.asset(
                  'assets/images/next.png',
                  height: 25,
                  color: black.withOpacity(0.2),
                ),
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Are You Sure You Want to Delete your Account?'.tr()),
                        titleTextStyle: const TextStyle(
                            fontSize: 18, color: Color(0xff222222)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                  false); // Close the dialog and return false
                            },
                            child: Text('No'.tr()),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Perform sign out action
                              await Provider.of<UserRepository>(context,
                                  listen: false).deleteAccount();

                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text('Yes'.tr()),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.resumed){
      setState(() {});
    }
  }

}
