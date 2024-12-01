import 'package:firebase_core/firebase_core.dart' as pre;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/models/flag_provider.dart';
import 'package:voiceassistant/models/user_repository.dart';
import 'package:voiceassistant/pages/speaking_page.dart';
import 'pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //prefs.remove('premium');
  await pre.Firebase.initializeApp();
  await ScreenUtil.ensureScreenSize();
  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => UserRepository.instance(),
          ),
          ChangeNotifierProvider(
            create: (context) => FlagImageProvider(),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('de', 'DE'),
            Locale('es', 'ES')
          ],
          path: 'assets/translations', // Path to your translation files
          fallbackLocale: const Locale('en', 'US'), // Default language
          child: const MyApp(),
        )),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            primaryColor: Colors.grey[300],
            fontFamily: GoogleFonts.roboto().fontFamily,
            textTheme: TextTheme(
              displayLarge: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.14,
                color: lightBlack,
              ),
              displayMedium: TextStyle(
                fontSize: 15.0,
                color: grey,
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Consumer<UserRepository>(
      builder: (context, user, _) {
        switch (user.status) {
          case Status.Uninitialized:
            return const LoginPage();
          case Status.Unauthenticated:
            return const LoginPage();
          case Status.Authenticating:
            return const LoginPage();
          case Status.Authenticating1:
            return const LoginPage();
          case Status.Authenticating2:
            return const LoginPage();
          case Status.Authenticated:
            return const SpeakNow();
        }
      },
    );
  }
}
