import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:voiceassistant/components/constants.dart';
import 'package:voiceassistant/pages/settings.dart';
import 'package:voiceassistant/pages/speaking_page.dart';
import 'package:onepref/onepref.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class subscription extends StatefulWidget {
  const subscription({super.key});

  @override
  State<subscription> createState() => _subscriptionState();
}

class _subscriptionState extends State<subscription> {
  final List<ProductDetails> _products = <ProductDetails>[];
  final List<ProductId> _productIds = <ProductId>[
    ProductId(id: "monthly", isConsumable: false),
    ProductId(id: "trimonthly", isConsumable: false),
    ProductId(id: "yearly", isConsumable: false),
  ];

  IApEngine iApEngine = IApEngine();
  bool isSubscribed = false;



  @override
  void initState() {
    super.initState();

    iApEngine.inAppPurchase.purchaseStream.listen((listOfPurchaseDetails) {

      listenPurchases(listOfPurchaseDetails);
    });
    getProducts();
    isSubscribed = OnePref.getPremium() ?? false;
  }

  Future<void> listenPurchases(List<PurchaseDetails> list) async {
    if (list.isNotEmpty) {
      for (PurchaseDetails purchaseDetails in list) {
        if (purchaseDetails.status == PurchaseStatus.restored ||
            purchaseDetails.status == PurchaseStatus.purchased) {
          log(purchaseDetails.verificationData.localVerificationData);
          log("hello");
          Map purchaseData = json
              .decode(purchaseDetails.verificationData.localVerificationData);
          if (purchaseData["acknowledged"]) {
            log("logg restore purchase");
            setState(() {
              isSubscribed = true;
              OnePref.setPremium(isSubscribed);
            });
          } else {
            log("first time purchase");
            //android consumer
            if (Platform.isAndroid) {
              final InAppPurchaseAndroidPlatformAddition
                  androidPlatformAddition = iApEngine.inAppPurchase
                      .getPlatformAddition<
                          InAppPurchaseAndroidPlatformAddition>();
              await androidPlatformAddition
                  .consumePurchase(purchaseDetails)
                  .then((value) {
                setState(() {
                  isSubscribed = true;
                  log("logg test2");
                  OnePref.setPremium(isSubscribed);
                });
              });
            }

            //complete
            if (purchaseDetails.pendingCompletePurchase) {
              await iApEngine.inAppPurchase
                  .completePurchase(purchaseDetails)
                  .then((value) {
                updateIsSub(true);
              });
            }
          }
        }
      }
    } else {
      updateIsSub(false);
    }
  }

  void updateIsSub(bool value) {
    print("logg purchase done");
    setState(() {
      isSubscribed = value;
      OnePref.setPremium(isSubscribed);
    });
  }

  void getProducts() async {

    bool avail = await iApEngine.inAppPurchase.isAvailable();
//    Fluttertoast.showToast(msg: avail.toString());


    await iApEngine.getIsAvailable().then((value) async {
      if (value) {
        await iApEngine.queryProducts(_productIds).then((res) {
          log(res.notFoundIDs.toString());
      //    Fluttertoast.showToast(msg: res.notFoundIDs.toString());
          log("hello3");
          print(res.productDetails);
          log("hello3");
          _products.clear();
          setState(() {
            _products.addAll(res.productDetails);
          });
        });
      }
    });
  }

  ProductDetails? _selectedProduct;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: secondaryColor,
        body: Column(
          children: [
            SizedBox(
              height: 5.h,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
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
                    "Subscription".tr(),
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: black.withOpacity(0.5), fontSize: 24),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/subscribe.png',
                    height: 150.h,
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  Text(
                    'Upgrade to Premium'.tr(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                  SizedBox(
                    height: 5.h,
                  ),
                  Text(
                    'Unlimited Voice to Text Transfer!'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: black.withOpacity(0.4),
                    ),
                  ),
                  SizedBox(
                    height: 30.h,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _products.asMap().entries.map((entry) {
                        ProductDetails product = entry.value;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedProduct = product;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 5), // Add some space between items
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: mainColor.withAlpha(180),
                                width: _selectedProduct != null &&
                                        _selectedProduct == product
                                    ? 2
                                    : 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: mainColor,
                                    borderRadius: BorderRadius.only(topRight: Radius.circular(8),topLeft: Radius.circular(8)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1, vertical: 2),
                                    child: Text(
                                      product.id.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.price,
                                  style: TextStyle(
                                    color: black.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 102.w,
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    product.description,
                                    style: TextStyle(
                                      color: black.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(
                    height: 20.h,
                  ),

                  InkWell(
                    onTap: () {
                      iApEngine.handlePurchase(_selectedProduct!, _productIds);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          _selectedProduct != null
                              ? '${'Get'.tr()} ${_selectedProduct!.description} ${'for'.tr()} ${_selectedProduct!.price}'
                              : 'Please Select Subscription Plan'.tr(),
                          style: TextStyle(
                            color: white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 35,
                  ),
                  Text(
                    'Does my Subscription Auto Renew?'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: black.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Yes. But, you can disable this at anytime with just one tap in the app store'
                        .tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: black.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
