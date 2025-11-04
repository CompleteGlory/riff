// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/widgets/button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: AppButton(onPressed: ()async{
        await SharedPrefHelper.removeData(SharedPrefKeys.userToken);
        context.pushReplacementNamed(Routes.login);
        }, text: "Log Out", isWhite:false),
    );
  }
}