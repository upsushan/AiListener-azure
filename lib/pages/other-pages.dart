import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OtherPages extends StatelessWidget {
  final String? pagename;
  const OtherPages({super.key, required this.pagename});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
       backgroundColor: secondaryColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              SizedBox(height: 10,),
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
                   pagename!,
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: black.withOpacity(0.5), fontSize: 24),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Expanded(
                child: WebView(
                initialUrl: pagename == "Privacy Policy"  ? "http://echoassist.net/privacy.html"  : "http://echoassist.net/terms.html", // URL of the webpage to display
                javascriptMode: JavascriptMode.unrestricted, // Enable JavaScript
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}