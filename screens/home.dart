import 'package:mentahan_google/provider/pro_app_setting.dart';
import 'package:mentahan_google/provider/pro_user.dart';

import '../cmn.dart';

class HomePage extends StatefulWidget {
  final Map<String, String> query;
  const HomePage({Key? key, this.query = const {}}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  MoUserProfile? _moUserProfile;

  setLoading([bool? val]) {
    _isLoading = val ?? !_isLoading;
    setS();
  }

  setS() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.query.containsKey("token")) {
      if (kDebugMode) print("initState home page query has token");
      checkMe();
    }
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.containsKey("token") || widget.query.containsKey("token")) {
      if (kDebugMode) print("didUpdateWidget home page query has token");
      checkMe();
    }
  }

  void checkMe({String form = "home.dart"}) async {
    await changeWindowHref("/", redirect: true);
    print("  void checkMe($form)");
    if (widget.query.containsKey("token") && widget.query["token"]!.isNotEmpty) {
      String token = widget.query["token"] ?? "";
      await _proUser!.tokenMe(token, proApp: _appState, shouldNotify: false);
      _moUserProfile = await _proUser!.readMoUser(shouldNotify: false);
      setS();
    }
  }

  ProAppSettings? _appState;
  ProUser? _proUser;

  void _loadProvider(BuildContext ctx) async {
    if (_appState != null && _proUser != null) return;
    setLoading(true);
    _appState ??= Provider.of<ProAppSettings>(ctx);
    _proUser ??= Provider.of<ProUser>(ctx, listen: false);
    _moUserProfile = await _proUser!.readMoUser(shouldNotify: false);
    setLoading(false);
  }
@override
Widget build(BuildContext context) {
  _loadProvider(context);
  return Scaffold(
    appBar: AppBar(
      title: const Text('Home Page'), 
      actions: [
        IconButton(
          onPressed: () async {
            await _appState!.logout();
          },
          icon: const Icon(Icons.logout)
        )
      ]
    ),
    body: _isLoading
      ? const Center(child: CircularProgressIndicator.adaptive())
      : _moUserProfile == null
        ? const Center(child: Text("No data"))
        : Container(
            alignment: Alignment.center,
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _moUserProfile?.photoURL != null
                            ? NetworkImage(_moUserProfile!.photoURL!)
                            : null,
                          child: _moUserProfile?.photoURL == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _moUserProfile?.displayName ?? "User",
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_moUserProfile?.email ?? "Email tidak tersedia"),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Informasi User",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text("ID: ${_moUserProfile?.id ?? 'N/A'}"),
                                const SizedBox(height: 5),
                                Text("Login terakhir: ${DateTime.now().toString()}"),
                                const SizedBox(height: 5),
                                Text("Provider: Google"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

  _smallString({String? text = "", int len = 20, String pre = "", String post = ""}) {
    if (text == null || text.isEmpty) return "";
    if (len < 0) return pre + text + post;
    return "$pre${text.length <= len ? text : text.substring(0, len)}$post...";
  }
}
