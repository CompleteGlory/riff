import 'package:flutter/material.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
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
       String token = await SharedPrefHelper.getString(SharedPrefKeys.userToken);
        print("User Token: $token");
        }, text: "Log Out", isWhite:false),
    );
  }
}