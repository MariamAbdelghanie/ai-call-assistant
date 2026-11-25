import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';


/// Parola gucu kurallari.
///
/// Parola hicbir zaman bizim veritabanimiza yazilmaz. Firebase
/// Authentication onu kendi sunucularinda scrypt ile ozetleyerek saklar;
/// uygulama yalnizca kullaniciyi dogrulayan bir belirtec alir. Burada
/// yapilan sey, zayif bir parolanin ilk basta olusturulmasini engellemektir.
class PasswordPolicy {
  static const int minLength = 8;

  /// Karsilanmayan kurallarin metin anahtarlarini dondurur; bos liste = gecerli.
  static List<String> violations(String value) {
    final issues = <String>[];
    if (value.length < minLength) issues.add('pwRuleLength');
    if (!RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(value)) issues.add('pwRuleUpper');
    if (!RegExp(r'[a-zçğıöşü]').hasMatch(value)) issues.add('pwRuleLower');
    if (!RegExp(r'[0-9]').hasMatch(value)) issues.add('pwRuleDigit');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) issues.add('pwRuleSymbol');
    return issues;
  }

  static bool isValid(String value) => violations(value).isEmpty;

  /// 0.0 - 1.0 arasi kaba bir guc olcusu (yalnizca gorsel gosterge).
  static double strength(String value) {
    if (value.isEmpty) return 0;
    final passed = 5 - violations(value).length;
    final lengthBonus = value.length >= 12 ? 1 : 0;
    return ((passed + lengthBonus) / 6).clamp(0.0, 1.0);
  }
}

/// Google ve e-posta ile oturum acma.
///
/// Firebase yapilandirmasi (android/app/google-services.json) yoksa uygulama
/// cokmez: [isConfigured] false kalir ve giris ekrani kurulumun eksik
/// oldugunu soyler. Sahte/gecici oturum acma YOKTUR; oturum yalnizca gercek
/// bir Google hesabiyla acilir.
class AuthService extends ChangeNotifier {
  AuthService();

  /// Firebase baslatildi mi. False ise google-services.json eksik demektir.
  bool isConfigured = false;

  /// Baslatma denemesi tamamlandi mi (acilis ekranini bekletmek icin).
  bool isReady = false;

  /// Oturum acmis kullanici; yoksa null.
  User? user;

  /// Son hatanin metin anahtari ('authNotConfigured', 'authCancelled', ...).
  String? errorKey;

  /// Hata ayiklama icin ham hata metni; kullaniciya gosterilmez.
  String? errorDetail;

  bool isBusy = false;

  GoogleSignIn? _google;

  bool get isSignedIn => user != null;

  String get displayName => user?.displayName?.trim().isNotEmpty == true
      ? user!.displayName!.trim()
      : (user?.email ?? '');

  String? get photoUrl => user?.photoURL;

  /// Uygulama acilisinda bir kez cagrilir.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      isConfigured = true;
      _google = GoogleSignIn(scopes: const ['email']);
      user = FirebaseAuth.instance.currentUser;
      FirebaseAuth.instance.authStateChanges().listen((value) {
        user = value;
        notifyListeners();
      });
    } catch (error) {
      // google-services.json yok ya da gecersiz.
      isConfigured = false;
      errorKey = 'authNotConfigured';
      errorDetail = error.toString();
    } finally {
      isReady = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!isConfigured) {
      errorKey = 'authNotConfigured';
      notifyListeners();
      return false;
    }
    isBusy = true;
    errorKey = null;
    errorDetail = null;
    notifyListeners();
    try {
      final account = await _google!.signIn();
      if (account == null) {
        // Kullanici hesap secme ekranini kapatti.
        errorKey = 'authCancelled';
        return false;
      }
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      user = result.user;
      return user != null;
    } on FirebaseAuthException catch (error) {
      errorKey = 'authFailed';
      errorDetail = '${error.code}: ${error.message}';
      return false;
    } catch (error) {
      errorKey = 'authFailed';
      errorDetail = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  // --- E-posta ve parola ---

  /// Yeni hesap olusturur ve dogrulama e-postasi gonderir.
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!isConfigured) {
      errorKey = 'authNotConfigured';
      notifyListeners();
      return false;
    }
    if (!PasswordPolicy.isValid(password)) {
      errorKey = 'authWeakPassword';
      notifyListeners();
      return false;
    }
    isBusy = true;
    errorKey = null;
    errorDetail = null;
    notifyListeners();
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final created = result.user;
      final name = (displayName ?? '').trim();
      if (created != null && name.isNotEmpty) {
        await created.updateDisplayName(name);
        await created.reload();
      }
      user = FirebaseAuth.instance.currentUser;
      // Dogrulama e-postasi: hesabin gercek bir adrese ait oldugunu gosterir.
      try {
        await user?.sendEmailVerification();
      } catch (_) {
        // Gonderilemezse kayit yine de gecerlidir.
      }
      return user != null;
    } on FirebaseAuthException catch (error) {
      errorKey = _mapAuthError(error.code);
      errorDetail = '${error.code}: ${error.message}';
      return false;
    } catch (error) {
      errorKey = 'authFailed';
      errorDetail = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      errorKey = 'authNotConfigured';
      notifyListeners();
      return false;
    }
    isBusy = true;
    errorKey = null;
    errorDetail = null;
    notifyListeners();
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = result.user;
      return user != null;
    } on FirebaseAuthException catch (error) {
      errorKey = _mapAuthError(error.code);
      errorDetail = '${error.code}: ${error.message}';
      return false;
    } catch (error) {
      errorKey = 'authFailed';
      errorDetail = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Parola sifirlama baglantisi gonderir.
  Future<bool> sendPasswordReset(String email) async {
    if (!isConfigured) {
      errorKey = 'authNotConfigured';
      notifyListeners();
      return false;
    }
    isBusy = true;
    errorKey = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (error) {
      errorKey = _mapAuthError(error.code);
      errorDetail = '${error.code}: ${error.message}';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Firebase hata kodlarini kullaniciya gosterilecek metin anahtarlarina cevirir.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'authEmailInUse';
      case 'invalid-email':
        return 'authInvalidEmail';
      case 'weak-password':
        return 'authWeakPassword';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'authWrongCredentials';
      case 'too-many-requests':
        return 'authTooManyRequests';
      case 'network-request-failed':
        return 'authNetwork';
      default:
        return 'authFailed';
    }
  }

  /// Sunucuya gonderilecek Firebase kimlik belirteci.
  ///
  /// Sunucu bu belirteci dogrulayip kullanicinin kim oldugunu bulur ve
  /// yalnizca o kullaniciya ait cagri kayitlarini dondurur. Belirtec
  /// kisa omurludur; her istekte tazesi alinir.
  Future<String> idToken() async {
    if (!isConfigured) return '';
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    isBusy = true;
    notifyListeners();
    try {
      await _google?.signOut();
      await FirebaseAuth.instance.signOut();
      user = null;
    } catch (error) {
      errorKey = 'authFailed';
      errorDetail = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
