import 'package:flutter/foundation.dart';
import '../data/expense_repository.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);
  final ExpenseRepository _repo;

  AppUser? _currentUser;
  bool _loading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _repo.signIn(email, password);
      if (user == null) {
        _error = 'メールアドレスまたはパスワードが正しくありません';
        _loading = false;
        notifyListeners();
        return false;
      }
      _currentUser = user;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'ログイン処理でエラーが発生しました';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void signOut() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
