import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/GradientBorder_container.dart';
import 'package:flutterbhz/widgets/MyColors.dart';
import 'package:flutterbhz/widgets/Text_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: MyColors.paige,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/unnamed.png", width: 180, height: 180),
              const Text(
                'مدرسة الكاروز',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Text(
                  'قم بتسجيل دخولك للمتابعة',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              GradientBorderContainer(
                height: 350,
                width: size.width * 0.85, // Responsive width
                widget: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const MyTextField(
                          label: 'البريد الإلكتروني',
                          icon: Icons.email_outlined,
                          errorText: "برجاء إدخال البريد الإلكتروني",
                        ),
                        const SizedBox(height: 20),
                        MyTextField(
                          label: 'كلمة السر',
                          icon: Icons.lock_outline,
                          errorText: "برجاء ادخال كلمة السر",
                          obscureText: _isPasswordHidden,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                              color: MyColors.lightBrown,
                            ),
                            onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.brown)),
                          ),
                        ),
                        const Spacer(),
                        _buildLoginButton(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: 220,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.brown, MyColors.lightBrown]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "تسجيل الدخول",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}