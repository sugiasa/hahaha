import 'package:flutter/material.dart';
import 'package:mentahan_google/provider/pro_app_setting.dart';
import 'package:mentahan_google/provider/pro_user.dart';

import '../cmn.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, String> query;
  const LoginScreen({Key? key, this.query = const {}}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  
  setLoading([bool? val]) {
    _isLoading = val ?? !_isLoading;
    setS();
  }

  setS() {
    if (mounted) setState(() {});
  }

  ProUser? _proUser;
  ProAppSettings? _appSettings;

  @override
  void initState() {
    super.initState();
    changeWindowHref("/");
  }

  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    changeWindowHref("/");
    if (oldWidget.query != widget.query) checkMe();
  }

  void checkMe() async {
    if (widget.query.containsKey("token") && widget.query["token"]!.isNotEmpty) {
      String token = widget.query["token"] ?? "";
      await _proUser!.tokenMe(token, proApp: _appSettings);
    }
  }

  void _loadProvider(BuildContext ctx) async {
    _proUser ??= Provider.of<ProUser>(ctx);
    _appSettings ??= Provider.of<ProAppSettings>(ctx);
  }

  @override
  Widget build(BuildContext context) {
    _loadProvider(context);
    return Scaffold(
      body: Center(
        child: _isLoading 
          ? const CircularProgressIndicator.adaptive()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Login dengan Google",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    try {
                      _proUser?.oAuthLogIn("google");
                    } catch (e) {
                      if (kDebugMode) print(e);
                    }
                  },
                  icon: const Icon(IonIcons.logo_google),
                  label: const Text("Login dengan Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}