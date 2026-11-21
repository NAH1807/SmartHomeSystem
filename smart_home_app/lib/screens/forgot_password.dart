import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _contactController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;
  String? _resetToken;

  @override
  void dispose() {
    _contactController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    final api = context.read<ApiService>();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_step == 0) {
        // BƯỚC 1: Gửi OTP đến email

        final email = _contactController.text.trim();

        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email)) {
          throw Exception('Email không hợp lệ');
        }

        await api.sendResetOtp(email: email);

        if (!mounted) return;

        setState(() {
          _step = 1;
        });
      } else if (_step == 1) {
        // BƯỚC 2: Xác thực OTP

        final result = await api.verifyResetOtp(
          email: _contactController.text.trim(),
          otp: _otpController.text.trim(),
        );

        final token = result['resetToken'];

        if (token == null || token.toString().isEmpty) {
          throw Exception('Không nhận được mã xác thực đặt lại mật khẩu');
        }

        if (!mounted) return;

        setState(() {
          _resetToken = token.toString();
          _step = 2;
        });
      } else if (_step == 2) {
        // BƯỚC 3: Đặt mật khẩu mới

        if (_passwordController.text.length < 8) {
          throw Exception('Mật khẩu phải có ít nhất 8 ký tự');
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception('Mật khẩu xác nhận không khớp');
        }

        if (_resetToken == null) {
          throw Exception('Phiên đặt lại mật khẩu không hợp lệ');
        }

        await api.resetPassword(
          resetToken: _resetToken!,
          newPassword: _passwordController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lại mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
        return;
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _decoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Email hoặc số điện thoại',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              decoration: _decoration(
                'Nhập địa chỉ email đã đăng ký',
                Icons.email_outlined,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Vui lòng nhập email';
                }

                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );

                if (!emailRegex.hasMatch(email)) {
                  return 'Địa chỉ email không hợp lệ';
                }

                return null;
              },
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mã xác thực OTP',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: _decoration(
                'Nhập mã OTP gồm 6 chữ số',
                Icons.password_outlined,
              ),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Vui lòng nhập đủ 6 chữ số OTP';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Mã OTP sẽ được gửi đến thông tin liên hệ đã đăng ký.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mật khẩu mới',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _decoration(
                'Nhập mật khẩu mới',
                Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Mật khẩu phải có ít nhất 8 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Xác nhận mật khẩu',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: _decoration(
                'Nhập lại mật khẩu mới',
                Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
          ],
        );
    }
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Khôi phục mật khẩu';
      case 1:
        return 'Xác thực OTP';
      default:
        return 'Tạo mật khẩu mới';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 75,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(height: 25),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bước ${_step + 1}/3',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 35),

                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: index <= _step
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 35),

                _buildStepContent(),

                const SizedBox(height: 30),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Tiếp tục'),
                  ),
                ),

                if (_step > 0) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _step--;
                      });
                    },
                    child: const Text('Quay lại'),
                  ),
                ],

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
