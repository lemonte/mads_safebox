import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/views/registration.dart';
import 'package:mads_safebox/widgets/custom_snack_bar.dart';
import 'package:mads_safebox/widgets/loading.dart';

// import '../models/user.dart';
// import '../riverpod/loggeduserprovider.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService auth = AuthService();

  final formkey = GlobalKey<FormState>();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    loading = false;
    obscurePassword = true;
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: mainColor,
        centerTitle: true,
        title: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: Colors.orange, size: 30),
              SizedBox(width: 8),
              Text(
                'SafeBoX',
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: !loading ? SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Login',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFF003366)),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: formkey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      validator: (val) => val!.isEmpty ? 'Insert an email' : null,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      validator: (val) => val!.isEmpty ? 'Insert a password' : null,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          String oldpass = passwordController.text.trim();//guarda a password escrita
                          try {
                            passwordController.text = '111111';//password "fake" para passar a validação
                            if(formkey.currentState!.validate()){//verifica que um email foi escrito
                              await auth.resetPassword(emailController.text.trim());
                              passwordController.text = oldpass;//retorna a password antiga
                              if(!context.mounted) return;
                              showCustomSnackBar(context, 'Email de redefinição de password enviado');
                              return;
                            }
                            passwordController.text = oldpass;
                          } on Exception catch (e) {
                            debugPrint("Error: $e");
                            passwordController.text = oldpass;
                            if(!context.mounted) return;
                            showCustomSnackBar(context, 'Error sending password reset email: $e');
                          }
//retorna a password antiga
                        },
                        child: const Text('Forgot your password', style: TextStyle(color: Color(0xFF003366))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formkey.currentState!.validate()) {
                          return;
                        }
                        setState(() {
                          loading = true;
                        });

                        try {
                          await auth.signInWithEmail(emailController.text.trim(), passwordController.text.trim());
                          //ref.read(userProvider.notifier).state = user;
                        } on Exception {
                          if(!context.mounted) return;
                          showCustomSnackBar(context, 'Invalid credentials');
                        }
                        if(context.mounted) {
                          setState(() {
                            loading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Login', style: TextStyle(color: mainTextColor),),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey.shade300),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("Or Login with", style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey.shade300),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              loading = true;
                            });

                            try {
                              await auth.nativeGoogleSignIn();
                              // ref.read(userProvider.notifier).state = user;
                            } on Exception catch (e) {
                              debugPrint("Error: $e");
                              if(context.mounted){
                                showCustomSnackBar(context, 'Error signing in with Google $e');
                                setState(() {
                                  loading = false;
                                });
                              }
                            }
                            if(context.mounted) {
                              setState(() {
                                loading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(FontAwesomeIcons.google, color: mainTextColor),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              loading = true;
                            });

                            try {
                              await auth.signInWithFacebook();
                              // ref.read(userProvider.notifier).state = user;
                            } on Exception catch (e) {
                              debugPrint("Error: $e");

                              if(context.mounted){
                                showCustomSnackBar(context, 'Error signing in with Facebook $e');
                                setState(() {
                                  loading = false;
                                });
                              }
                            }
                            if(context.mounted) {
                              setState(() {
                                loading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(FontAwesomeIcons.facebookF, color: mainTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("You don’t have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                                MaterialPageRoute(builder: (context) => const RegistrationPage()),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      )
      : const Center(
        child: Loading(),
      ),
    );
  }
}

