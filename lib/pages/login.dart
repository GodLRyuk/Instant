import 'package:flutter/material.dart';
import 'package:instant/pages/home.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Login")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xfff7d486), Color(0Xffe9b7ce)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 100),
            ),
            Image(
              image: const AssetImage("images/logo.png"),
              width: MediaQuery.of(context).size.width * 2,
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.07,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: SignInButton(
                Buttons.google,
                text: "Sign In with Google",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Homepage(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: SignInButton(
                Buttons.apple,
                text: "Sign In with Apple",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Homepage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
