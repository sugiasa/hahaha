import 'package:flutter/material.dart';
import 'package:mentahan_google/provider/pro_app_setting.dart';
import 'package:mentahan_google/provider/pro_shared_pref.dart';

import '../cmn.dart';

class ProUser extends ChangeNotifier {
  //if token is Empty then user not Loggedin
  final ApiDio _dio = ApiDio();
  final ProSharedPref _pref = ProSharedPref();
  final ProAppSettings _proAppSetting = ProAppSettings();
  List<String> _serverProviders = [];
  MoUserProfile? moUser;
  List<bool> isLoadingLS = [];
  ProUser() {
    asyncInit();
  }

  asyncInit({bool shouldNotify = true}) async {
    await readListOfProvider();
    await readMoUser();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////
  /*
  Login
  logout
  Register
  add provider
  forgot password
   */
  List<String> get serverProviders => _serverProviders;
  Future<List<String>> readListOfProvider({
    bool canFromServer = true,
    bool shouldNotify = true,
  }) async {
    if (_serverProviders.isNotEmpty) {
      notilistner(shouldNotify);
      return _serverProviders;
    }
    try {
      List temp = await _pref.getfromoPref("getfromoPref", []);
      if (temp.isEmpty) {
        if (temp.isEmpty && canFromServer) await getListOfProvider();
      } else {
        if (kDebugMode)
          print("getfromoPref  getfromoPref length ${temp.length}");
        _serverProviders = List<String>.from(temp);
      }
    } catch (e) {
      if (kDebugMode) print(e);
      await getListOfProvider();
    }

    notilistner(shouldNotify);
    return _serverProviders;
  }

  Future<List<String>> saveListOfProvider([
    List<String> providers = const [],
  ]) async {
    bool bl = await _pref.setToPref("serverProviders", strLS: providers);
    if (bl) _serverProviders = providers;
    return _serverProviders;
  }

  Future<List<String>> getListOfProvider({
    bool shouldNotify = false,
    bool isForce = false,
  }) async {
    if (_serverProviders.isNotEmpty && !isForce) return _serverProviders;
    isLoadingLS.add(true);
    try {
      MoResponse ms = await _dio.getAsync("auth/google");
      if (ms.status != "ok" ||
          ms.success == false ||
          ms.result == null ||
          ms.result!.isEmpty) {
        //print(ms.status);print(ms.success);print(ms.result);
        if (isLoadingLS.isNotEmpty) isLoadingLS.removeAt(0);
        return [];
      }
      await saveListOfProvider(serverProviderFromJson(ms.result![0]));
    } catch (e) {
      if (kDebugMode) print(e);
    }

    if (isLoadingLS.isNotEmpty) isLoadingLS.removeAt(0);
    return _serverProviders;
  }

  List<String> serverProviderFromJson(dynamic data) {
    if (data == null) return [];
    return List<String>.from(data["providers"]);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////

  Future<MoUserProfile?> readMoUser({
    bool canFromServer = true,
    bool shouldNotify = true,
  }) async {
    if (moUser != null) {
      notilistner(shouldNotify);
      return moUser;
    }
    try {
      String tep = await _pref.getfromoPref("moUser");
      if (tep.isEmpty) {
        String tok = await _proAppSetting.getToken(shouldNotify: shouldNotify);
        if (canFromServer && tok.isNotEmpty)
          await tokenMe(tok, shouldNotify: shouldNotify);
      } else {
        Map<String, dynamic> moo = jsonDecode(tep);
        moUser = MoUserProfile.fromJson(moo);
      }
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
    notilistner(shouldNotify);
    return moUser;
  }

  Future<MoUserProfile?> saveMoUser(MoUserProfile? moSave) async {
    if (moUser == null) return null;
    bool bl = await _pref.setToPref(
      "moUser",
      str: jsonEncode(moSave!.toJson()),
    );
    if (bl) {
      moUser = moSave;
    }
    return moUser;
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Metode untuk login OAuth - dimodifikasi untuk fokus pada Google
  oAuthLogIn(String provider, {bool shouldNotify = true}) async {
    if (provider != "google") {
      if (kDebugMode) print("Hanya login Google yang tersedia");
      return;
    }

    // URL diubah untuk menyesuaikan dengan server Node.js
    // Pastikan port dan path sesuai dengan server Node.js
    Uri uri = Uri.parse("${baseDiol[0]}auth/google");

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: "_self",
    )) {
      throw Exception('Could not launch $uri');
    }
  }

  // Metode untuk memverifikasi token yang diterima dari server
  Future<String> tokenMe(
    String token, {
    bool shouldNotify = true,
    ProAppSettings? proApp,
  }) async {
    if (token.isEmpty) return "";
    isLoadingLS.add(true);

    // Sesuaikan dengan API endpoint pada server Node.js
    _dio.xAccessToken = token;
    MoResponse ms = await _dio.getAsync("api/user");

    if (ms.status != "ok" ||
        ms.success == false ||
        ms.result == null ||
        ms.result!.isEmpty) {
      _dio.xAccessToken = "";
      if (isLoadingLS.isNotEmpty) isLoadingLS.removeAt(0);
      return "";
    }

    // Sesuaikan dengan format respons dari server Node.js
    try {
      moUser = MoUserProfile.fromJson(ms.result![0]);
      // Jika format respons berbeda, Anda mungkin perlu menyesuaikan parsing
    } catch (e) {
      if (kDebugMode) print("Error parsing user data: $e");
    }

    saveMoUser(moUser);
    String tk = await (proApp ?? _proAppSetting).setToken(
      moUser?.token ?? "",
      shouldNotify: shouldNotify,
    );

    if (isLoadingLS.isNotEmpty) isLoadingLS.removeAt(0);
    notilistner(shouldNotify);
    return tk;
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////

  notilistner([bool shouldNotify = false]) {
    if (shouldNotify) notifyListeners();
  }
}
