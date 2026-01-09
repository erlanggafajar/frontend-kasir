import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/kasir_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kasir_provider.dart';
import '../../styles/color_style.dart';

class KasirEditScreen extends StatefulWidget {
  final KasirModel kasir;

  const KasirEditScreen({super.key, required this.kasir});

  @override
  State<KasirEditScreen> createState() => _KasirEditScreenState();
}

class _KasirEditScreenState extends State<KasirEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _email;
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.kasir.name);
    _email = TextEditingController(text: widget.kasir.email);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Akun Kasir'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_name, 'Nama'),
                  _field(_email, 'Email'),
                  _field(
                    _password,
                    'Password Baru (Opsional)',
                    obscure: _obscurePassword,
                    required: false,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Consumer<KasirProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Mohon tunggu sebentar...'),
                              ],
                            );
                          }
                          return const Text('Simpan Perubahan');
                        },
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final success = await context
                            .read<KasirProvider>()
                            .updateKasir(
                              id: widget.kasir.id,
                              name: _name.text,
                              email: _email.text,
                              password: _password.text.isEmpty
                                  ? null
                                  : _password.text,
                              token: token,
                            );

                        if (success && mounted) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Berhasil mengedit data kasir'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool required = true,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (v) {
          if (required && (v == null || v.isEmpty)) {
            return 'Wajib diisi';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
