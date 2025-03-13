import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/helpers/snackbar_helper.dart';
import '../values/app_regex.dart';
// ignore: directives_ordering
import '../components/app_text_form_field.dart';
import '../resources/resources.dart';
import '../utils/common_widgets/gradient_background.dart';
import '../utils/helpers/navigation_helper.dart';
import '../values/app_constants.dart';
import '../values/app_routes.dart';
import '../values/app_strings.dart';
import '../values/app_theme.dart';
import '../connection/auth/AuthController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> passwordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> fieldValidNotifier = ValueNotifier(false);

  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final AuthController auth = AuthController();
    final Map<String, dynamic> response = await auth.signIn(correo, contrasena);
    return response;
  }

  void initializeControllers() {
    emailController = TextEditingController()..addListener(controllerListener);
    passwordController = TextEditingController()..addListener(controllerListener);
  }

  void disposeControllers() {
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> controllerListener() async {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty && password.isEmpty) return;

    if (AppRegex.emailRegex.hasMatch(email) && AppRegex.passwordRegex.hasMatch(password)) {
      fieldValidNotifier.value = true;
    } else {
      fieldValidNotifier.value = false;
    }
  }

  Future<void> handleLogin() async {
    try {
        final email = emailController.text.trim();
        final password = passwordController.text;

        final response = await login(email, password);

        if (response['success']) {
          
          SnackbarHelper.showSnackBar(AppStrings.loggedIn);
            
          emailController.clear();
          passwordController.clear();

          NavigationHelper.pushReplacementNamed(AppRoutes.bottomNavigationPage); // Cambiar a la ruta correcta
        } else {
          SnackbarHelper.showSnackBar(response['error']);
          }
    } catch (e) {
            SnackbarHelper.showSnackBar("Error inesperado: $e");
      }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
            SizedBox(height: 10),
            Text(
              '¿Desea salir?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          '¿Está seguro que desea salir de la aplicación?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void initState() {
    initializeControllers();
    super.initState();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldPop = await _showExitConfirmationDialog();
        
        if (shouldPop) {
          SystemNavigator.pop(); // This will close the app
        }
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            const GradientBackground(
              children: [
                Text(
                  AppStrings.signInToYourNAccount,
                  style: AppTheme.titleLarge,
                ),
                SizedBox(height: 6),
               // Text(AppStrings.signInToYourAccount, style: AppTheme.bodySmall),
               //probando
              ],
            ),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppTextFormField(
                      controller: emailController,
                      labelText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _formKey.currentState?.validate(),
                      validator: (value) {
                        return value!.isEmpty
                            ? AppStrings.pleaseEnterEmailAddress
                            : AppConstants.emailRegex.hasMatch(value)
                                ? null
                                : AppStrings.invalidEmailAddress;
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: passwordNotifier,
                      builder: (_, passwordObscure, __) {
                        return AppTextFormField(
                          obscureText: passwordObscure,
                          controller: passwordController,
                          labelText: AppStrings.password,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (_) => _formKey.currentState?.validate(),
                          validator: (value) {
                            return value!.isEmpty || !AppConstants.passwordRegex.hasMatch(value)
                                ? AppStrings.pleaseEnterPassword
                                : null;
                          },
                          suffixIcon: IconButton(
                            onPressed: () =>
                                passwordNotifier.value = !passwordObscure,
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(48),
                            ),
                            icon: Icon(
                              passwordObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(AppStrings.forgotPassword),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder(
                      valueListenable: fieldValidNotifier,
                      builder: (_, isValid, __) {
                        return FilledButton(
                          onPressed: isValid ? handleLogin : null,
                          child: const Text(AppStrings.login),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            AppStrings.orLoginWith,
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: SvgPicture.asset(Vectors.google, width: 14),
                            label: const Text(
                              AppStrings.google,
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: SvgPicture.asset(Vectors.facebook, width: 14),
                            label: const Text(
                              AppStrings.facebook,
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.doNotHaveAnAccount,
                  style: AppTheme.bodySmall.copyWith(color: Colors.black),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => NavigationHelper.pushReplacementNamed(
                    AppRoutes.register,
                  ),
                  child: const Text(AppStrings.register),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}