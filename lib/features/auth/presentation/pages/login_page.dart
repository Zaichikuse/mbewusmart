import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLogin = true;
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _confirmPinController = TextEditingController();
  UserRole _selectedRole = UserRole.farmer;

  @override
  Widget build(BuildContext context) {
    final isChichewa = context.watch<SettingsBloc>().state is SettingsLoaded
        ? (context.watch<SettingsBloc>().state as SettingsLoaded).languageCode == 'ny'
        : true;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.eco,
                  size: 80,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  AppUtils.getGreeting(context, isChichewa),
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'MbewuSmart',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLanguageChip(isChichewa, 'ny', isChichewa ? 'Chichewa' : 'Chichewa'),
                    const SizedBox(width: 8),
                    _buildLanguageChip(!isChichewa, 'en', isChichewa ? 'English' : 'English'),
                  ],
                ),
                const SizedBox(height: 32),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: isChichewa ? 'Dzina Lonse' : 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isChichewa ? 'Fani ili yofunika' : 'This field is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      labelText: isChichewa ? 'Sankha Umodzi Wanu' : 'Select Your Role',
                      prefixIcon: const Icon(Icons.work),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(isChichewa ? role.displayNameChichewa : role.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nationalIdController,
                    decoration: InputDecoration(
                      labelText: isChichewa ? 'ID Yoyenera (Osiya)' : 'National ID (Optional)',
                      prefixIcon: const Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isChichewa ? 'Nambala Ya Fonu' : 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isChichewa ? 'Fani ili yofunika' : 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isChichewa 
                        ? (_isLogin ? 'Lowa PIN' : 'PIN (Osiya)')
                        : (_isLogin ? 'Enter PIN' : 'PIN (Optional)'),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isChichewa ? 'Confirm PIN' : 'Confirm PIN',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (_pinController.text.isNotEmpty && value != _pinController.text) {
                        return isChichewa ? 'PIN zosiyana' : 'PINs do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state.status == AuthStatus.error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.errorMessage ?? 'Error')),
                      );
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == AuthStatus.loading ? null : _submit,
                      child: state.status == AuthStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin 
                              ? (isChichewa ? 'Lowani' : 'Login')
                              : (isChichewa ? 'Lembani' : 'Sign Up')),
                    );
                  },
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? (isChichewa ? 'Palibe account? Lembani' : "Don't have an account? Sign Up")
                        : (isChichewa ? 'Mali account? Lowani' : 'Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(bool selected, String code, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        context.read<SettingsBloc>().add(SettingsLanguageChanged(code));
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryGreen : AppTheme.textDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        context.read<AuthBloc>().add(AuthLoginRequested(
          phoneNumber: _phoneController.text,
          pin: _pinController.text.isNotEmpty ? _pinController.text : null,
        ));
      } else {
        context.read<AuthBloc>().add(AuthRegisterRequested(
          fullName: _fullNameController.text,
          phoneNumber: _phoneController.text,
          nationalId: _nationalIdController.text.isNotEmpty ? _nationalIdController.text : null,
          role: _selectedRole,
          pin: _pinController.text.isNotEmpty ? _pinController.text : null,
        ));
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
