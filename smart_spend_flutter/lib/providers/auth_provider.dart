import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SyncService _syncService = SyncService();

  User? _currentUser;
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  UserProfileModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _currentUser != null || _userProfile != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    final client = Supabase.instance.client;
    _currentUser = client.auth.currentUser;
    _userProfile = _storage.getUserProfile();

    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _currentUser = session?.user;

      if (_currentUser != null) {
        // Update cached profile
        final meta = _currentUser!.userMetadata;
        final cached = _storage.getUserProfile();
        final profile = UserProfileModel(
          id: _currentUser!.id,
          email: _currentUser!.email ?? '',
          fullName: meta?['full_name']?.toString() ?? cached?.fullName,
          avatarUrl: meta?['avatar_url']?.toString() ?? cached?.avatarUrl,
        );
        _userProfile = profile;
        _storage.saveUserProfile(profile);

        // Trigger sync
        _syncService.syncAll();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _currentUser = res.user;
      if (_currentUser != null) {
        final profile = UserProfileModel(
          id: _currentUser!.id,
          email: _currentUser!.email ?? email.trim(),
          fullName: _currentUser!.userMetadata?['full_name']?.toString(),
        );
        _userProfile = profile;
        await _storage.saveUserProfile(profile);
        await _syncService.syncAll();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      _currentUser = res.user;
      if (_currentUser != null) {
        final profile = UserProfileModel(
          id: _currentUser!.id,
          email: _currentUser!.email ?? email.trim(),
          fullName: fullName.trim(),
        );
        _userProfile = profile;
        await _storage.saveUserProfile(profile);
        await _syncService.syncAll();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create account: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_syncService.isOnline) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {}

    _currentUser = null;
    _userProfile = null;
    await _storage.clearUserProfile();
    await _storage.clearAll();

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
