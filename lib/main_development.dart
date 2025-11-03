import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/riff_app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  setUpGetIt();
  await checkIfLoggedIn();
  runApp(RiffApp(
    appRouter: AppRouter(),
  ));
}

bool isLoggedInUser = false;

checkIfLoggedIn() async { 
  // Check if user is logged in
  String? userToken =
      await SharedPrefHelper.getString(SharedPrefKeys.userToken);
  if (userToken != null && userToken.isNotEmpty) {
    isLoggedInUser = true;
  } else {
    isLoggedInUser = false;
  }
}