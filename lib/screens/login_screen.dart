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

  // Agregar un flag para controlar si el widget está disposed
  bool _isDisposed = false;

  final ValueNotifier<bool> passwordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> fieldValidNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

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
      // Verificar si el widget aún está montado
      if (_isDisposed) return;
      
      isLoadingNotifier.value = true;
      
      final email = emailController.text.trim();
      final password = passwordController.text;

      final response = await login(email, password);

      // Verificar nuevamente si el widget está montado
      if (_isDisposed) return;

      if (response['success']) {
        SnackbarHelper.showSnackBar(AppStrings.loggedIn);
        emailController.clear();
        passwordController.clear();
        NavigationHelper.pushReplacementNamed(AppRoutes.bottomNavigationPage);
      } else {
        SnackbarHelper.showSnackBar(response['error']);
      }
    } catch (e) {
      if (!_isDisposed) {
        SnackbarHelper.showSnackBar("Error inesperado: $e");
      }
    } finally {
      // Verificar antes de actualizar el notifier
      if (!_isDisposed) {
        isLoadingNotifier.value = false;
      }
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
    _isDisposed = true;
    disposeControllers();
    passwordNotifier.dispose();
    fieldValidNotifier.dispose();
    isLoadingNotifier.dispose();
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
          SystemNavigator.pop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const GradientBackground(
                    children: [
                      Text(
                        AppStrings.signInToYourNAccount,
                        style: AppTheme.titleLarge,
                      ),
                      SizedBox(height: 6),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEmailField(),
                          _buildPasswordField(),
                          _buildForgotPassword(),
                          const SizedBox(height: 20),
                          _buildLoginButton(),
                          const SizedBox(height: 20),
                          _buildDivider(),
                          const SizedBox(height: 20),
                          _buildGoogleSignIn(),
                          const SizedBox(height: 20),
                          _buildRegisterLink(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return AppTextFormField(
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
    );
  }

  Widget _buildPasswordField() {
    return ValueListenableBuilder(
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
            onPressed: () => passwordNotifier.value = !passwordObscure,
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
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Implementar recuperación de contraseña
        },
        child: const Text(AppStrings.forgotPassword),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ValueListenableBuilder(
      valueListenable: fieldValidNotifier,
      builder: (_, isValid, __) {
        return ValueListenableBuilder(
          valueListenable: isLoadingNotifier,
          builder: (_, isLoading, __) {
            return ElevatedButton(
              onPressed: (isValid && !isLoading) ? handleLogin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Iniciando sesión...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      AppStrings.login,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'O continuar con',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ],
    );
  }

  Widget _buildGoogleSignIn() {
    return OutlinedButton.icon(
      onPressed: () {
        // Implementar inicio de sesión con Google
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: SvgPicture.asset(Vectors.google, width: 24),
      label: const Text(
        'Continuar con Google',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.doNotHaveAnAccount,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => NavigationHelper.pushReplacementNamed(
            AppRoutes.register,
          ),
          child: const Text(
            AppStrings.register,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return ValueListenableBuilder(
      valueListenable: isLoadingNotifier,
      builder: (_, isLoading, __) {
        if (!isLoading) return const SizedBox.shrink();
        
        return Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                color: Colors.blue.shade900,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}