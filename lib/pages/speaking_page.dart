import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:azure_speech_recognition/azure_speech_recognition_null_safety.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_speech/config/recognition_config.dart';
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart';
import 'package:onepref/onepref.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_speech/google_speech.dart' as pre;
import 'package:permission_handler/permission_handler.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/const/static-lists.dart';
import 'package:voiceassistant/pages/settings.dart';
import 'package:voiceassistant/pages/subscription_page.dart';
import 'package:wakelock/wakelock.dart';

class SpeakNow extends StatefulWidget {
  const SpeakNow({Key? key}) : super(key: key);
  @override
  State<SpeakNow> createState() => _SpeakNowState();
}

class _SpeakNowState extends State<SpeakNow> with TickerProviderStateMixin {
  late Animation<double> _animation;

  late AnimationController _controller;
  bool startListening = false;
  bool showChats = false;
  int showBubble = 0;
  int wordcount = 0;
  bool stopListening = false;
  List<String> mainSpeech = [];
  List<int> speechTag = [];
  List<String> mainSpeechDisplay = [];
  List<int> speechTagDisplay = [];
  List<Color> chatColors = [blue, green, orange, Colors.deepPurple];
  List<String> chatNames = ["Person 1".tr(), "Person 2".tr(), "Person 3".tr(),"Person 4".tr()];
  List<String> speechLanguages = ["English", "French","German","Spanish", "Italian", "Chinese", "Portuguese", "Japanese","English","English","French","Spanish","English", "English"];
  List<String> flags = ["usa", "france","germany","spain", "italy", "china", "brazil", "japan","uk","australia","canada","mexico","canada","india"];
  String selectedLanguage = "";
  late Color selectedColor;
  TextEditingController _nameController =  TextEditingController();
  bool speechIsEmpty = true;
  late SharedPreferences prefs;
  int wordCount = 0;
  bool prefInitialized = false;
  var totalWordCount = -1;
  bool startCounting = true;
  var text = "";
  bool diarizationSupported = true;

  var _pressedCount = 0;
  bool showLangSelector = false;
  bool showFontSelector = false;

  double _fontSize = 18;


  // For search functionality
  String searchQuery = '';
  List<String> filteredWithTranscript = [];
  List<String> filteredWithoutTranscript = [];
  List<String> filteredWithTranscriptflag = [];
  List<String> filteredWithoutTranscriptflag = [];
  List<String> filteredWithTranscriptcode = [];
  List<String> filteredWithoutTranscriptcode = [];
  TabController? _tabController;


  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    filteredWithTranscript = languageNamesWithTranscript;
    filteredWithTranscriptflag = flagsWithTranscript;
    filteredWithoutTranscript = languageNamesWithoutTranscript;
    filteredWithoutTranscriptflag = flagsWithoutTranscript;
    filteredWithoutTranscriptcode = languageCodesWithoutTranscript;
    filteredWithTranscriptcode = languageCodesWithTranscript;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Change this curve as needed
      ),


    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    _controller.forward();
    getPremiumStatus();
    listenSubscriotion();
    initAzure();
    super.initState();
  }

  Future<void> getPremiumStatus() async {
     prefs = await SharedPreferences.getInstance();

     
      setState(() {
        prefInitialized = true;
        wordCount = prefs.getInt('leftWords') ?? 10000;
      });
    // Return false if the value is not found

    _tabController!.addListener(() {
      if(_tabController!.indexIsChanging){
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool is_Transcribing = false;
  String intermediateText = '';
  List<String> spokenWords = [];
  List<String> personOneSpeechSegments = [];
  void streamingRecognize() async {
    setState(() {
      recognizing = true;
      startListening = false;
    });
    Wakelock.toggle(enable: true);
    await Permission.microphone.request();
    AzureSpeechRecognition.continuousRecording();
  }


    initAzure() async{
      await Future.delayed(Duration(milliseconds: 200));

      String lang = prefs.getString('lang') ?? "en-US";
      diarizationSupported = prefs.getBool('speakerlabel') ?? true;
      selectedLanguage = prefs.getString('langflag') ?? "🇺🇸";

      AzureSpeechRecognition.initialize(
          "9c40deafe2284fdaa2dee4bc0adf8474", "uksouth",
          lang: lang, timeout: '1000');


      AzureSpeechRecognition.differentiateSpeakers(diarizationSupported);
      setState(() {});

      final AzureSpeechRecognition _azureSpeechRecognition = AzureSpeechRecognition();
      _azureSpeechRecognition.setFinalTranscription((val) {
        String currentText = val['argument1'];
        final speakerTag = diarizationSupported ?  extractNumber(val['argument2']) - 1  :  -1;


        if (currentText.isNotEmpty) {

          setState(() {
            mainSpeech.add(currentText);
            speechTag.add(speakerTag);
            speechIsEmpty = false;
            mainSpeechDisplay.clear();
            speechTagDisplay.clear();
            mainSpeechDisplay.addAll(mainSpeech.reversed);
            speechTagDisplay.addAll(speechTag.reversed);
            intermediateText = "";
          });
        }
      });

      _azureSpeechRecognition.setRecognitionResultHandler((text) {
        setState(() {
          intermediateText = text;
          speechIsEmpty = false;
        });
      });


    }


  List<String> personThreeWords = [];
  bool recognizeFinished = false;
  bool recognizing = false;
  void stopRecording() async {

    setState(() {
      recognizing = false;
    });

    Wakelock.toggle(enable: false);

    // mainSpeechDisplay.clear();
    // speechTagDisplay.clear();
    // mainSpeech.clear();
    // speechTag.clear();
     AzureSpeechRecognition.continuousRecording();
  }

  bool premium = false;


  @override
  Widget build(BuildContext context) {

    if(prefInitialized && startCounting){
      RegExp regExp = RegExp(" ");
      if(!premium) {
        int wcount = wordCount - countWordsInList(mainSpeechDisplay);
        if (totalWordCount == -1 || wcount < totalWordCount) {
          totalWordCount = wcount;
          if(totalWordCount <= 0) {
            totalWordCount = 0;
          }
          setIntPref(totalWordCount);
   }

      if(totalWordCount <= 0){
        if(recognizing) {
          Fluttertoast.showToast(msg: "No words left. Please subscribe to continue.".tr());
          stopListening = true;
          stopRecording();
        }
      }
      }
    }


    return WillPopScope(
      onWillPop: ()async{
        if (_pressedCount == 1) {
          return true;
        } else {
          Fluttertoast.showToast(msg: "Press back again to exit app".tr());
          _pressedCount++;
          await Future.delayed(Duration(seconds: 2));
          _pressedCount = 0;
          return false;
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: secondaryColor,
          body: Stack(
            children: [

              Column(
                children: [
                  SizedBox(
                    height: 5.h,
                  ),


                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const subscription()));
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: 30, top: 8),
                                padding: const EdgeInsets.only(
                                    left: 20, right: 5, top: 5, bottom: 5),
                                decoration: BoxDecoration(
                                  color: mainColor.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      premium ? "Subscribed".tr() : "Demo".tr(),
                                      style: TextStyle(color: white),
                                    ),
                                    const SizedBox(
                                      width: 3,
                                    ),
                                    Text(
                                      premium
                                          ? ''
                                          : "$totalWordCount ${'words'.tr()}",
                                      style: TextStyle(
                                        color: white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: mainColor,
                              radius: 23,
                              child: Image.asset(
                                'assets/images/avatar.png',
                                height: 23,
                                width: 23,
                                color: white,
                              ),
                            ),
                          ],
                        ),


                        Row(
                          children: [

                            GestureDetector(
                              onTap: (){
                                setState(() {
                                  showFontSelector = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: mainColor.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Image.asset( 'assets/images/font.png', width: 30, color: white.withOpacity(0.7),),
                              ),
                            ),
                            SizedBox(width: 10,),
                            GestureDetector(
                              onTap: () {
                                if(!recognizing) {
                                  filteredWithTranscript = languageNamesWithTranscript;
                                  filteredWithTranscriptflag = flagsWithTranscript;
                                  filteredWithoutTranscript = languageNamesWithoutTranscript;
                                  filteredWithoutTranscriptflag = flagsWithoutTranscript;
                                  filteredWithoutTranscriptcode = languageCodesWithoutTranscript;
                                  filteredWithTranscriptcode = languageCodesWithTranscript;
                                  setState(() {
                                    showLangSelector = true;
                                  });
                                }else{
                                  Fluttertoast.showToast(msg: "To change language, Please stop the current listening process.".tr());
                                }

                              },
                              child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: mainColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(selectedLanguage, style: TextStyle(fontSize: 30, height: 1),),
                            ),
                            ),

                            SizedBox(width: 18,),

                            GestureDetector(
                              onTap: () {
                                if(recognizing) {
                                  if (!stopListening) {
                                    stopRecording();
                                    setState(() {
                                      stopListening = true;
                                    });
                                  }
                                }
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const settings()));
                              },

                              child: CircleAvatar(
                                backgroundColor: mainColor,
                                radius: 20,
                                child: Image.asset(
                                  'assets/images/setting.png',
                                  height: 25.h,
                                  width: 25.w,
                                  color: white.withOpacity(0.7),
                                ),
                              ),

                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!speechIsEmpty)
                   Container(
                     height: 40,
                     width: MediaQuery.of(context).size.width,
                     margin: EdgeInsets.only(top: 5),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         GestureDetector(
                           onTap: (){

                             showDialog(
                               context: context,
                               builder: (BuildContext context) {
                                 return AlertDialog(
                                   title: Text('Are You Sure You Want to Clear Chat?'.tr()),
                                   titleTextStyle: const TextStyle(
                                       fontSize: 18, color: Color(0xff222222)),
                                   actions: <Widget>[
                                     TextButton(
                                       onPressed: () {
                                         Navigator.of(context).pop(false); // Close the dialog and return false
                                       },
                                       child: Text('No'.tr()),
                                     ),
                                     TextButton(
                                       onPressed: () async {
                                         text = "";
                                         wordCount = prefs.getInt('leftWords') ?? 10000;
                                         mainSpeechDisplay.clear();
                                         speechTagDisplay.clear();
                                         mainSpeech.clear();
                                         speechTag.clear();
                                         intermediateText = "";
                                         speechIsEmpty = true;
                                         stopListening = false;
                                         if(recognizing){
                                           stopRecording();
                                         }
                                         setState(() {});

                                         Navigator.pop(context);
                                       },
                                       child: Text('Yes'.tr()),
                                     ),
                                   ],
                                 );
                               },
                             );




                           },
                           child: Container(
                             margin: EdgeInsets.only(right: 10),
                             padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                             decoration: BoxDecoration(
                               color: mainColor.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(12.0),
                             ),
                             child: Row(
                               children: [
                                 Icon(Icons.clear, color: mainColor, size: 19,),
                                 Text("Clear Chat".tr(), style: TextStyle(color: mainColor)),
                               ],
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),

                  if(intermediateText!="")
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(
                        top: 4,
                        left: 8.0,
                        right: 8.0,
                        bottom: 8.0,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        intermediateText,
                        style: TextStyle(
                          fontSize: 14,
                          color: startListening
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),


                  if (!speechIsEmpty)
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                            ListView.builder(
                                itemCount: mainSpeechDisplay.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    alignment: Alignment.center,
                                    child: Stack(children: [

                                      if(diarizationSupported)
                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        padding:  EdgeInsets.only(
                                          top: diarizationSupported ?  _fontSize + 3 : 8,
                                          left: 8.0,
                                          right: 8.0,
                                          bottom: 8.0,
                                        ),
                                        margin:  EdgeInsets.symmetric(
                                          horizontal:  8.0,
                                          vertical: diarizationSupported ? 12 : 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: white,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          mainSpeechDisplay[index],
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            color: Colors.white
                                          ),
                                        ),
                                      ),

                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        padding:  EdgeInsets.only(
                                          top: diarizationSupported ?  _fontSize + 3 : 8,
                                          left: 8.0,
                                          right: 8.0,
                                          bottom: 8.0,
                                        ),
                                        margin:  EdgeInsets.symmetric(
                                          horizontal:  8.0,
                                          vertical: diarizationSupported ? 12 : 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: diarizationSupported ?  chatColors[speechTagDisplay[index]].withOpacity(0.1) : white,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          mainSpeechDisplay[index],
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            color: diarizationSupported ?  chatColors[speechTagDisplay[index]] : black
                                          ),
                                        ),
                                      ),

                                      if(diarizationSupported)
                                      Positioned(
                                        left: 5,
                                        top: 0,
                                        child: GestureDetector(
                                          onTap: (){
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                selectedColor = chatColors[speechTagDisplay[index]];
                                                //Fluttertoast.showToast(msg: speechTagDisplay[index].toString());
                                                return StatefulBuilder(
                                                    builder: (context, setState) {
                                                      return AlertDialog(
                                                        contentPadding: EdgeInsets.zero,
                                                        content: changeProfileDialog(speechTagDisplay[index]),
                                                      );
                                                    });
                                              },
                                            );
                                          },
                                          child: Container(
                                            height: _fontSize + 12,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: chatColors[speechTagDisplay[index]],
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  spreadRadius: 5,
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Image.asset(
                                                  "assets/images/person.png",
                                                  color: white,
                                                  height: _fontSize + 4,
                                                ),
                                                const SizedBox(
                                                  width: 4,
                                                ),
                                                Text(
                                                  chatNames[speechTagDisplay[index]],
                                                  style: TextStyle(
                                                    fontSize: _fontSize - 2,
                                                    color: white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  );
                                }),



                          Positioned(
                            bottom: -62,
                            child: Container(
                              height: stopListening ? 0.h : 145.h,
                              width: stopListening ? 0.w : 145.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _animation.value,
                                    child: CircleAvatar(
                                      backgroundColor: mainColor.withOpacity(0.2),
                                      radius: 200,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),


                          Positioned(
                            bottom: -50,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (stopListening) {
                                    stopListening = false;
                                    if(totalWordCount != 0 || premium) {
                                      wordCount = totalWordCount;
                                      text = "";
                                      streamingRecognize();
                                    }else{
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const subscription()));
                                    }
                                  } else {
                                    stopListening = true;
                                    stopRecording();
                                  }
                                });
                              },

                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: stopListening ? 100.h : 125.h,
                                width: stopListening ? 100.w : 125.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: black
                                          .withOpacity(0.4), // Shadow color color
                                      offset: const Offset(
                                          0.0, 0.1), // Offset of the shadow
                                      blurRadius: 2.0, // Blur radius
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: mainColor,
                                  radius: 200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: stopListening ? 13.h : 9.h,
                                      ),
                                      if (!stopListening)
                                        AnimatedBuilder(
                                          animation: _animation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: _animation.value,
                                              child: Image.asset(
                                                'assets/images/voice-assistant.png',
                                                color: white,
                                                fit: BoxFit.cover,
                                                width: 60.w,
                                              ),
                                            );
                                          },
                                        ),
                                      if (stopListening)
                                        Image.asset(
                                          'assets/images/microphonee.png',
                                          color: white,
                                          fit: BoxFit.cover,
                                          width: 25.w,
                                        ),
                                      Text(
                                        stopListening
                                            ? "Tap to Start".tr()
                                            : "Listening".tr() + "..",
                                        style: TextStyle(
                                            color: stopListening
                                                ? white.withOpacity(0.7)
                                                : white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Column(
                  //   children: [
                  //     if (recognizeFinished)
                  //       Container(
                  //         width: MediaQuery.of(context).size.width,
                  //         alignment: Alignment.center,
                  //         child: Stack(
                  //           children: [
                  //             Container(
                  //               padding: const EdgeInsets.only(
                  //                 left: 8.0,
                  //                 right: 8.0,
                  //                 bottom: 8.0,
                  //               ),
                  //               margin: const EdgeInsets.symmetric(
                  //                 horizontal: 8.0,
                  //                 vertical: 12,
                  //               ),
                  //               decoration: BoxDecoration(
                  //                 color: white,
                  //                 borderRadius: BorderRadius.circular(12.0),
                  //               ),
                  //               child: SizedBox(
                  //                 height: 100,
                  //                 width: 350,
                  //                 child: ListView(
                  //                   reverse: true,
                  //                   physics: const BouncingScrollPhysics(),
                  //                   scrollDirection: Axis.vertical,
                  //                   children: [
                  //                     Text(
                  //                       personOneText,
                  //                       style: TextStyle(
                  //                         fontSize: 18,
                  //                         color: startListening
                  //                             ? Colors.red
                  //                             : Colors.black,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //             Positioned(
                  //               left: 5,
                  //               top: 0,
                  //               child: Container(
                  //                 height: 30,
                  //                 padding: const EdgeInsets.symmetric(horizontal: 10),
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.teal,
                  //                   borderRadius: BorderRadius.circular(10),
                  //                   boxShadow: [
                  //                     BoxShadow(
                  //                       color: Colors.black.withOpacity(0.2),
                  //                       spreadRadius: 5,
                  //                       blurRadius: 15,
                  //                       offset: const Offset(0, 3),
                  //                     ),
                  //                   ],
                  //                 ),
                  //                 child: Row(
                  //                   children: [
                  //                     Image.asset(
                  //                       "assets/images/person.png",
                  //                       color: white,
                  //                       height: 20,
                  //                     ),
                  //                     Text(
                  //                       "Person One",
                  //                       style: TextStyle(
                  //                         fontSize: 14,
                  //                         color: white,
                  //                         fontWeight: FontWeight.bold,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     if (recognized1)
                  //       Container(
                  //         width: MediaQuery.of(context).size.width,
                  //         alignment: Alignment.center,
                  //         child: Stack(
                  //           children: [
                  //             Container(
                  //               padding: const EdgeInsets.only(
                  //                 left: 8.0,
                  //                 right: 8.0,
                  //                 bottom: 8.0,
                  //               ),
                  //               margin: const EdgeInsets.symmetric(
                  //                 horizontal: 8.0,
                  //                 vertical: 12,
                  //               ),
                  //               decoration: BoxDecoration(
                  //                 color: white,
                  //                 borderRadius: BorderRadius.circular(12.0),
                  //               ),
                  //               child: SizedBox(
                  //                 height: 100,
                  //                 width: 350,
                  //                 child: ListView(
                  //                   reverse: true,
                  //                   physics: const BouncingScrollPhysics(),
                  //                   scrollDirection: Axis.vertical,
                  //                   children: [
                  //                     Text(
                  //                       personTwoText,
                  //                       style: TextStyle(
                  //                         fontSize: 18,
                  //                         color: startListening
                  //                             ? Colors.red
                  //                             : Colors.black,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //             Positioned(
                  //               left: 5,
                  //               top: 0,
                  //               child: Container(
                  //                 height: 30,
                  //                 padding: const EdgeInsets.symmetric(horizontal: 10),
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.deepOrange,
                  //                   borderRadius: BorderRadius.circular(10),
                  //                   boxShadow: [
                  //                     BoxShadow(
                  //                       color: Colors.black.withOpacity(0.2),
                  //                       spreadRadius: 5,
                  //                       blurRadius: 15,
                  //                       offset: const Offset(0, 3),
                  //                     ),
                  //                   ],
                  //                 ),
                  //                 child: Row(
                  //                   children: [
                  //                     Image.asset(
                  //                       "assets/images/person.png",
                  //                       color: white,
                  //                       height: 20,
                  //                     ),
                  //                     Text(
                  //                       "Person Two",
                  //                       style: TextStyle(
                  //                         fontSize: 14,
                  //                         color: white,
                  //                         fontWeight: FontWeight.bold,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     if (recognized2)
                  //       Container(
                  //         width: MediaQuery.of(context).size.width,
                  //         alignment: Alignment.center,
                  //         child: Stack(
                  //           children: [
                  //             Container(
                  //               padding: const EdgeInsets.only(
                  //                 left: 8.0,
                  //                 right: 8.0,
                  //                 bottom: 8.0,
                  //               ),
                  //               margin: const EdgeInsets.symmetric(
                  //                 horizontal: 8.0,
                  //                 vertical: 12,
                  //               ),
                  //               decoration: BoxDecoration(
                  //                 color: white,
                  //                 borderRadius: BorderRadius.circular(12.0),
                  //               ),
                  //               child: SizedBox(
                  //                 height: 100,
                  //                 width: 350,
                  //                 child: ListView(
                  //                   reverse: true,
                  //                   physics: const BouncingScrollPhysics(),
                  //                   scrollDirection: Axis.vertical,
                  //                   children: [
                  //                     Text(
                  //                       personThreeText,
                  //                       style: TextStyle(
                  //                         fontSize: 18,
                  //                         color: startListening
                  //                             ? Colors.red
                  //                             : Colors.black,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //             Positioned(
                  //               left: 5,
                  //               top: 0,
                  //               child: Container(
                  //                 height: 30,
                  //                 padding: const EdgeInsets.symmetric(horizontal: 10),
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.yellow,
                  //                   borderRadius: BorderRadius.circular(10),
                  //                   boxShadow: [
                  //                     BoxShadow(
                  //                       color: Colors.black.withOpacity(0.2),
                  //                       spreadRadius: 5,
                  //                       blurRadius: 15,
                  //                       offset: const Offset(0, 3),
                  //                     ),
                  //                   ],
                  //                 ),
                  //                 child: Row(
                  //                   children: [
                  //                     Image.asset(
                  //                       "assets/images/person.png",
                  //                       color: white,
                  //                       height: 20,
                  //                     ),
                  //                     Text(
                  //                       "Person Three",
                  //                       style: TextStyle(
                  //                         fontSize: 14,
                  //                         color: white,
                  //                         fontWeight: FontWeight.bold,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //   ],
                  // ),

                  if (speechIsEmpty)
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/worldmap.png", ),
                            opacity: 0.5,
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: recognizing
                              ? GestureDetector(
                                  onTap: () {
                                    stopRecording();
                                  },
                                  child: AnimatedBuilder(
                                    animation: _animation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _animation.value,
                                        child: Container(
                                          height: 285.h,
                                          width: 285.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    mainColor, // Shadow color color
                                                offset: const Offset(
                                                    0.0, 0.2), // Offset of the shadow
                                                blurRadius: 10.0, // Blur radius
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor: mainColor,
                                            radius: 200,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/images/voice-assistant.png',
                                                  color: white,
                                                  fit: BoxFit.cover,
                                                  width: 100.w,
                                                ),
                                                SizedBox(
                                                  height: 15.h,
                                                ),
                                                Text("Listening".tr() + "..",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayLarge!
                                                        .copyWith(
                                                            color: white,
                                                            fontSize: 28.sp)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () async {
                                    if(totalWordCount != 0 || premium) {
                                      streamingRecognize();
                                    }else{
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const subscription()));
                                    }
                                  },
                                  child: AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, child) {
                                        return Container(
                                          height: 150.h,
                                          width: 150.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: mainColor,
                                            boxShadow: [
                                              BoxShadow(
                                                color: mainColor, // Shadow color
                                                offset: const Offset(
                                                    0.0, 0.2), // Offset of the shadow
                                                blurRadius: 10.0, // Blur radius
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(30.w),
                                            child: Column(
                                              children: [
                                                Image.asset(
                                                  'assets/images/microphonee.png',
                                                  color: white,
                                                  fit: BoxFit.cover,
                                                  height: 60.h,
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text("Tap to Start".tr(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayLarge!
                                                        .copyWith(
                                                            color: white
                                                                .withOpacity(0.8),
                                                            fontSize: 17.sp)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                        ),
                      ),
                    ),
                ],
              ),

              if(showFontSelector)
                GestureDetector(
                  onTap: (){
                    setState(() {
                      showFontSelector = false;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withOpacity(0.6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                            onTap: (){

                            },
                            child: ChangeFontSize()),
                      ],
                    ),
                  ),
                ),

             if(showLangSelector)
             GestureDetector(
               onTap: (){
                 setState(() {
                   showLangSelector = false;
                 });
               },
               child: Container(
                 width: MediaQuery.of(context).size.width,
                 height: MediaQuery.of(context).size.height,
                 color: Colors.black.withOpacity(0.6),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     GestureDetector(
                       onTap: (){

                       },
                         child: LanguageSelector()),
                   ],
                 ),
               ),
             ),

            ],
          ),
        ),
      ),
    );
  }



  Widget sttLanguageSelector(){
    return Container(
      height: 615,
      width: 300,
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: EdgeInsets.only(top: 15, left: 5,right: 5),
      child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.height / 3.5),
          ),
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 14,
          shrinkWrap: true,

          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: (){

              },
              child: Column(
                children: [
                  Image.asset("assets/languages/${flags[index]}.png", height: 38,),
                  SizedBox(height: 4,),
                  Text(speechLanguages[index], style: TextStyle(fontSize: 16,)),
                ],
              ),
            );
          }
      ),
    );
  }


   setIntPref(int totalWordCount)async{
    await prefs.setInt('leftWords', totalWordCount);
  }

  Widget changeProfileDialog(int index){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20,horizontal: 35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit User'.tr(),
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 20.sp,
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Enter Name'.tr(),
              labelStyle: TextStyle(
                color: const Color.fromARGB(181, 0, 0, 0),
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Color:'.tr(),
                style: TextStyle(
                  color: const Color.fromARGB(181, 0, 0, 0),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColorCircle(blue, 1, index),
              _buildColorCircle(green,2, index),
              _buildColorCircle(orange,3, index),
              _buildColorCircle(Colors.yellow,4, index),
              _buildColorCircle(Colors.pink,5, index),
            ],
          ),

          SizedBox(height:20),
          ElevatedButton(
            onPressed: () {
              // Save the entered name and selected color
              String enteredName = _nameController.text;
              chatNames[index] = enteredName;
              chatColors[index] = selectedColor;
              setState(() {});
              _nameController.text = "";

              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(
              'Save'.tr(),
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void listenSubscriotion() {
    IApEngine iApEngine = IApEngine();
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
     // setState(() {});
    });

  }

  Widget _buildColorCircle(Color color, int index, int mainIndex) {
    return GestureDetector(
      onTap: () {
        if(!chatColors.contains(color)) {
          selectedColor = color;
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      content: changeProfileDialog(mainIndex),
                    );
                  });
            },
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color:selectedColor == color ||  !chatColors.contains(color) ? color : color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          if(selectedColor == color)
            Center(child: Icon(Icons.check_circle_rounded, size: 15, color: Colors.white.withOpacity(0.4),)),
        ],
      ),
    );
  }
  int extractNumber(String input) {
    RegExp regExp = RegExp(r'\d+');
    RegExpMatch match = regExp.firstMatch(input)!;
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 0; // If no number found in the string
  }

  int countWordsInList(List<String> stringsList) {
    int totalWords = 0;
    for (String string in stringsList) {
      List<String> words = string.split(" ");
      totalWords += words.length;
    }
    return totalWords;
  }


  Widget ChangeFontSize(){
    return Container(
      padding: EdgeInsets.all(15.0),
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chat Font Size'.tr(),
            style: TextStyle(
              fontSize: _fontSize,
            ),
          ),
          SizedBox(height: 20.0),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: mainColor.withOpacity(0.7),
              inactiveTrackColor: mainColor.withOpacity(0.3),
              thumbColor: mainColor.withOpacity(0.9),
              overlayColor: Colors.blue.withAlpha(32),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 30.0),
            ),
            child: Slider(
              value: _fontSize,
              min: 16.0,
              max: 28.0,
              divisions: 3,
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _changeFontSize('S'),
                child: Text('S', style: TextStyle(color: mainColor),),
              ),
              TextButton(
                onPressed: () => _changeFontSize('M'),
                child: Text('M',style: TextStyle(color: mainColor),),
              ),
              TextButton(
                onPressed: () => _changeFontSize('L'),
                child: Text('L',style: TextStyle(color: mainColor),),
              ),
              TextButton(
                onPressed: () => _changeFontSize('XL'),
                child: Text('XL',style: TextStyle(color: mainColor),),
              ),
            ],
          ),
        ],
      ),
    );
  }



void _changeFontSize(String value) {
  setState(() {
    switch (value) {
      case 'S':
        _fontSize = 16.0;
        break;
      case 'M':
        _fontSize = 18.0;
        break;
      case 'L':
        _fontSize = 23.0;
        break;
      case 'XL':
        _fontSize = 28.0;
        break;
    }
  });
}


  void updateSearchQuery(String newQuery) {
   // Fluttertoast.showToast(msg: newQuery);
    setState(() {
      searchQuery = newQuery;
      print("cleared");

      if (searchQuery.isNotEmpty) {
        List<String> flags = [];
        List<String> langs = [];

        List<String> flags1  = [];
        List<String> langs1 = [];

        filteredWithTranscript = languageNamesWithTranscript
            .where((lang) {
          bool containsQuery = lang.toLowerCase().contains(searchQuery.toLowerCase());
          if (containsQuery) {
            int index = languageNamesWithTranscript.indexOf(lang);
           // print("Index: ${flagsWithTranscript[index]}");// Find the index of lang within languageNamesWithTranscript
            flags.add(flagsWithTranscript[index]);
           // Fluttertoast.showToast(msg: flagsWithTranscript[index]);
            langs.add(languageCodesWithTranscript[index]);
          }
          return containsQuery;
        })
            .toList();
        
        

        filteredWithoutTranscript = languageNamesWithoutTranscript
            .where((lang) {
          bool containsQuery = lang.toLowerCase().contains(searchQuery.toLowerCase());
          if (containsQuery) {
            int index = languageNamesWithoutTranscript.indexOf(lang); // Find the index of lang within languageNamesWithoutTranscript
            flags1.add(flagsWithoutTranscript[index]);
            langs1.add(languageCodesWithoutTranscript[index]);
          }
          return containsQuery;
        })
            .toList();


        filteredWithTranscriptflag = flags;
        filteredWithoutTranscriptflag = flags1;
        filteredWithTranscriptcode = langs;
        filteredWithoutTranscriptcode = langs1;

      } else {
        filteredWithTranscript = languageNamesWithTranscript;
        filteredWithTranscriptflag = flagsWithTranscript;
        filteredWithoutTranscript = languageNamesWithoutTranscript;
        filteredWithoutTranscriptflag = flagsWithoutTranscript;
        filteredWithoutTranscriptcode = languageCodesWithoutTranscript;
        filteredWithTranscriptcode = languageCodesWithTranscript;
      }
    });
  }

  Widget LanguageSelector(){
    return Container(
      height: 500,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: mainColor,
            tabs: [
              Tab(child:
                Row(
                  children: [
                    Image.asset("assets/images/podcast.png", color: _tabController!.index == 0? mainColor : lightBlack , width: 48,),
                    SizedBox(width: 4,),
                    Text("Identify \nSpeakers".tr(), style: TextStyle(fontSize: 14, height: 1, fontWeight: FontWeight.bold, color: _tabController!.index == 0? mainColor : lightBlack),),
                    SizedBox(width: 4,),
                  ],
                )
                ,),
              Tab(child:
              Row(
                children: [
                  Image.asset("assets/images/mic.png", color: _tabController!.index == 1? mainColor : lightBlack , width: 48,),
                  SizedBox(width: 4,),
                  Text("Speech \nto Text".tr(), style: TextStyle(fontSize: 14, height: 1, fontWeight: FontWeight.bold, color: _tabController!.index == 1? mainColor : lightBlack),),
                  SizedBox(width: 4,),
                ],
              )
                ,),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
            child: SizedBox(

              child:SizedBox(
                height: 44, // Set your desired height here
                child: TextField(
                  onChanged: updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search...'.tr(),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0), // Adjust as needed
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LanguageListTab(0),
                LanguageListTab(1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget LanguageListTab(int tabIndex){

      final languages = tabIndex == 0 ? filteredWithTranscript : filteredWithoutTranscript;
      final flags = tabIndex == 0 ? filteredWithTranscriptflag : filteredWithoutTranscriptflag;
      final language = tabIndex == 0 ? filteredWithTranscriptcode : filteredWithoutTranscriptcode;
      return ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(languages[index]),
            leading: Text(flags[index], style: TextStyle(fontSize: 28),),
            onTap: () {
             print(languages[index]);

              diarizationSupported = tabIndex == 0 ? true : false;
              AzureSpeechRecognition.differentiateSpeakers(diarizationSupported);

              text = "";
              wordCount = prefs.getInt('leftWords') ?? 10000;
              mainSpeechDisplay.clear();
              speechTagDisplay.clear();
              mainSpeech.clear();
              speechTag.clear();
              selectedLanguage = flags[index];
              AzureSpeechRecognition.changeLanguage(language[index]);
              showLangSelector = false;
              prefs.setString('lang',language[index]) ;
              prefs.setBool('speakerlabel', diarizationSupported);
              prefs.setString('langflag', selectedLanguage);
              setState(() {});
            },
          );
        },
      );
  }

  Widget _buildLanguageList(List<String> languages) {
    return ListView.builder(
      itemCount: languages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(languages[index]),
        );
      },
    );
  }




}





