import 'package:flutter/material.dart';
import 'package:login_register_app/connection/email_service/email_service.dart';
import 'package:login_register_app/utils/helpers/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../connection/auth/AuthController.dart';
import '../components/app_text_form_field.dart';
import '../utils/common_widgets/gradient_background.dart';
import '../values/app_regex.dart';
import '../values/app_routes.dart';
import '../values/app_strings.dart';
import '../values/app_theme.dart';
import '/screens/email_verificator/EmailConfirmationScreen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  final ValueNotifier<bool> passwordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> confirmPasswordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> fieldValidNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isTypingPassword = ValueNotifier(false);

  // Password requirements
  final ValueNotifier<bool> hasMinLength = ValueNotifier(false);
  final ValueNotifier<bool> hasUppercase = ValueNotifier(false);
  final ValueNotifier<bool> hasNumber = ValueNotifier(false);
  final ValueNotifier<bool> hasSpecialChar = ValueNotifier(false);

  late FocusNode passwordFocusNode;
  late FocusNode confirmPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    initializeControllers();

    passwordFocusNode = FocusNode()
      ..addListener(() {
        // Show requirements when focus is gained, hide when lost
        isTypingPassword.value = passwordFocusNode.hasFocus;
      });

    confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    disposeControllers();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void initializeControllers() {
    nameController = TextEditingController()..addListener(controllerListener);
    lastNameController = TextEditingController()
      ..addListener(controllerListener);
    emailController = TextEditingController()..addListener(controllerListener);
    passwordController = TextEditingController()
      ..addListener(() {
        passwordListener();
        isTypingPassword.value = passwordController.text.isNotEmpty;
      });
    confirmPasswordController = TextEditingController()
      ..addListener(controllerListener);
  }

  void disposeControllers() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  void passwordListener() {
    final password = passwordController.text;

    // Update password requirements
    hasMinLength.value = password.length >= 8;
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    controllerListener();
  }

  void controllerListener() {
    final name = nameController.text;
    final lastName = lastNameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      fieldValidNotifier.value = false;
      return;
    }

    if (AppRegex.emailRegex.hasMatch(email) &&
        hasMinLength.value &&
        hasUppercase.value &&
        hasNumber.value &&
        hasSpecialChar.value &&
        password == confirmPassword) {
      fieldValidNotifier.value = true;
    } else {
      fieldValidNotifier.value = false;
    }
  }

  Widget _buildPasswordRequirement(ValueNotifier<bool> notifier, String text) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isValid, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isValid ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isValid ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isValid
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: isValid ? Colors.green.shade700 : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para manejar el registro exitoso
  void _handleSuccessfulRegistration() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.emailConfirmation, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Navegar al login de manera segura
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      },
      child: Scaffold(
        body: ListView(
          children: [
            const GradientBackground(
              children: [
                Text(AppStrings.register, style: AppTheme.titleLarge),
                SizedBox(height: 6),
                Text(
                  AppStrings.createYourAccount,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextFormField(
                      labelText: AppStrings.name,
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                    ),
                    AppTextFormField(
                      labelText: "Apellidos",
                      controller: lastNameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                    ),
                    AppTextFormField(
                      labelText: AppStrings.email,
                      controller: emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Password Requirements
                    ValueListenableBuilder<bool>(
                      valueListenable: isTypingPassword,
                      builder: (context, isTyping, child) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: isTyping
                              ? Container(
                                  key: const ValueKey('password-requirements'),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Requisitos de Contraseña',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildPasswordRequirement(hasMinLength,
                                          'Al menos 8 caracteres'),
                                      _buildPasswordRequirement(
                                          hasUppercase, 'Una letra mayúscula'),
                                      _buildPasswordRequirement(
                                          hasNumber, 'Un número'),
                                      _buildPasswordRequirement(hasSpecialChar,
                                          'Un carácter especial'),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        );
                      },
                    ),

                    // Password Input
                    ValueListenableBuilder<bool>(
                      valueListenable: passwordNotifier,
                      builder: (_, passwordObscure, __) {
                        return AppTextFormField(
                          focusNode: passwordFocusNode,
                          obscureText: passwordObscure,
                          controller: passwordController,
                          labelText: AppStrings.password,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.visiblePassword,
                          suffixIcon: IconButton(
                            icon: Icon(passwordObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () {
                              passwordNotifier.value = !passwordNotifier.value;
                            },
                          ),
                        );
                      },
                    ),

                    // Confirm Password Input
                    ValueListenableBuilder<bool>(
                      valueListenable: confirmPasswordNotifier,
                      builder: (_, confirmPasswordObscure, __) {
                        return AppTextFormField(
                          focusNode: confirmPasswordFocusNode,
                          obscureText: confirmPasswordObscure,
                          controller: confirmPasswordController,
                          labelText: AppStrings.confirmPassword,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.visiblePassword,
                          suffixIcon: IconButton(
                            icon: Icon(confirmPasswordObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () {
                              confirmPasswordNotifier.value =
                                  !confirmPasswordNotifier.value;
                            },
                          ),
                        );
                      },
                    ),

                    // Submit Button
                    const SizedBox(height: 20),
                    ValueListenableBuilder<bool>(
                      valueListenable: fieldValidNotifier,
                      builder: (_, isValid, __) {
                        return ElevatedButton(
                          onPressed: isValid
                              ? () async {
                                  if (_formKey.currentState!.validate()) {
                                    // Obtener los valores de los controladores
                                    final fullName =
                                        "${nameController.text} ${lastNameController.text}";

                                    final email = EmailService();
                                    try {
                                      /*  fullName,
                                          emailController.text,
                                          confirmPasswordController.text);*/
                                      if (email.isUserRegistered(
                                          emailController.text)) {
                                        SnackbarHelper.showSnackBar(
                                            "Este correo ya está en uso");
                                      } else {
                                        // Enviar correo de confirmación
                                        final response = await email
                                            .sendEmail(emailController.text);

                                        if (response['success']) {
                                          SnackbarHelper.showSnackBar(
                                              response['message']);
                                          //pantalla de verificación de correo
                                          _handleSuccessfulRegistration();
                                        } else {
                                          SnackbarHelper.showSnackBar(
                                              response['message']);
                                        }
                                      }
                                    } catch (e) {
                                      SnackbarHelper.showSnackBar("Error $e");
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor:
                                isValid ? Theme.of(context).primaryColor : null,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Registrarse'),
                        );
                      },
                    ),

                    // Login Link
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes una cuenta?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.login);
                          },
                          child: const Text('Iniciar Sesión'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
