import '../cmn.dart';

class LinkHandler {
  final void Function(String link) onLink;
  // StreamSubscription<String?>? _subscription;
  StreamSubscription<Uri>? _subscription;
  late AppLinks _appLinks;
  LinkHandler({required this.onLink});

  Future<void> init() async {
    if (_subscription != null) return;
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    try {
      final appLink = await _appLinks.getInitialAppLink();
      if (appLink != null) {
        _onLink(appLink);
      }
    } on PlatformException {
      // if (kDebugMode)
      if (kDebugMode) print('Failed to get initial link.');
    }
    // Handle link when app is in warm state (front or background)
    _subscription = _appLinks.uriLinkStream.listen((data) => _onLink(data));
  }

  void _onLink(Uri? link) {
  var linkss = "";
  if (kIsWeb) {
    linkss = link.toString().replaceFirst(domain(), '');
  } else {
    // Sesuaikan dengan URL scheme yang digunakan di server Node.js
    linkss = link.toString().replaceFirst("myapp://auth", '');
    
    // Cek apakah link mengandung data
    if (linkss.contains("data=")) {
      // Parse data JSON dari parameter URL
      try {
        String dataStr = Uri.decodeComponent(linkss.split("data=")[1]);
        Map<String, dynamic> userData = jsonDecode(dataStr);
        
        // Sekarang kita memiliki data user dan token
        // Anda dapat menyimpan token ke ProAppSettings
        // Dan memanggil fungsi tokenMe
        
        if (kDebugMode) print("Received user data: $userData");
        
        // Ubah linkss menjadi path yang diharapkan aplikasi untuk routing
        linkss = "/?token=${userData['token']}";
      } catch (e) {
        if (kDebugMode) print("Error parsing deep link data: $e");
      }
    }
  }
  
  if (kDebugMode) print("_onLink $linkss");
  onLink(linkss);
}

  void dispose() => _subscription!.cancel();
}
