import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_store.dart';
import 'business_mode_screen.dart';
import 'pro_workspace_screen.dart';

class BusinessWorkspaceScreen extends StatefulWidget {
  const BusinessWorkspaceScreen({
    super.key,
    required this.account,
    this.startWithProductForm = false,
  });

  final LocalAccount account;
  final bool startWithProductForm;

  @override
  State<BusinessWorkspaceScreen> createState() =>
      _BusinessWorkspaceScreenState();
}

class _BusinessWorkspaceScreenState extends State<BusinessWorkspaceScreen> {
  String? _businessTypeOverride;

  String get _businessType =>
      _businessTypeOverride ?? widget.account.businessType;

  String get _storageKey =>
      'business_type_${widget.account.phoneNumber.replaceAll('+', '')}';

  @override
  void initState() {
    super.initState();
    _restoreBusinessType();
  }

  Future<void> _restoreBusinessType() async {
    final value = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (!mounted || value == null || value.trim().isEmpty) return;
    setState(() => _businessTypeOverride = value);
  }

  Future<void> _openBusinessMode() async {
    final selectedType = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BusinessModeScreen(
          businessName: widget.account.businessName,
          initialBusinessType: _businessType,
        ),
      ),
    );
    if (selectedType == null || !mounted) return;
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      selectedType,
    );
    if (!mounted) return;
    setState(() => _businessTypeOverride = selectedType);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Activité configurée : $selectedType')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ProWorkspaceScreen(
                account: widget.account,
                startWithProductForm: widget.startWithProductForm,
              ),
            ),
            Positioned(
              right: 14,
              bottom: 88,
              child: SafeArea(
                top: false,
                child: Material(
                  elevation: 5,
                  color: const Color(0xff176b45),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    key: const Key('businessActivityShortcut'),
                    borderRadius: BorderRadius.circular(22),
                    onTap: _openBusinessMode,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Mon activité',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
