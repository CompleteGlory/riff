import 'package:flutter/material.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/riff_app.dart';
import 'core/routing/app_router.dart';
import 'core/di/dependency_injection.dart';
import 'core/helpers/shared_pref_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUpGetIt();

  final isLoggedIn = await checkIfLoggedIn();

  runApp(RiffApp(
    appRouter: AppRouter(),
    startAtHome: isLoggedIn,
  ));
}

/// Returns true if both access token and refresh token exist
Future<bool> checkIfLoggedIn() async {
  final userToken = await SharedPrefHelper.getString(SharedPrefKeys.userToken);
  final refreshToken = await SharedPrefHelper.getString(SharedPrefKeys.refreshToken);

  return userToken != null &&
      userToken.isNotEmpty &&
      refreshToken != null &&
      refreshToken.isNotEmpty;
}
