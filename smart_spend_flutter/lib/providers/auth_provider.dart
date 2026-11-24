import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user_profile_model.dart';
import '../services/avatar_cache_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SyncService _syncService = SyncService();

  User? _currentUser;
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _googleSignInInitFuture;

  User? get currentUser => _currentUser;
  UserProfileModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _currentUser != null || _userProfile != null;

  AuthProvider() {
    _initAuth();
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    if (AppConstants.googleWebClientId.isNotEmpty &&
        !AppConstants.googleWebClientId.startsWith('GOCSPX-')) {
      _googleSignInInitFuture = GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.googleWebClientId,
        clientId: kIsWeb ? AppConstants.googleWebClientId : null,
      );
    }
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
          fullName: meta?['full_name']?.toString() ??
              meta?['name']?.toString() ??
              cached?.fullName,
          avatarUrl: meta?['avatar_url']?.toString() ??
              meta?['picture']?.toString() ??
              cached?.avatarUrl,
        );
        _userProfile = profile;
        _storage.saveUserProfile(profile);
        if (profile.avatarUrl != null) {
          unawaited(AvatarCacheService.instance.preCacheAvatar(profile.avatarUrl));
        }

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
        if (profile.avatarUrl != null) {
          unawaited(AvatarCacheService.instance.preCacheAvatar(profile.avatarUrl));
        }
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
        if (profile.avatarUrl != null) {
          unawaited(AvatarCacheService.instance.preCacheAvatar(profile.avatarUrl));
        }
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

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate Client ID format
      if (AppConstants.googleWebClientId.startsWith('GOCSPX-')) {
        _errorMessage =
            'The value in googleWebClientId is a Google Client Secret (starts with GOCSPX-), not a Client ID. Please use your Client ID ending in ".apps.googleusercontent.com" from Google Cloud Console.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (AppConstants.googleWebClientId.isEmpty) {
        _errorMessage = 'Google Web Client ID is not configured.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Ensure initialized once
      if (_googleSignInInitFuture == null) {
        _initGoogleSignIn();
      }
      if (_googleSignInInitFuture != null) {
        await _googleSignInInitFuture;
      }

      // Native Google Sign-In with ID Token (No browser redirect, never goes to website)
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        _errorMessage =
            'Failed to retrieve Google ID token. Please verify Google Cloud Console configuration.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      _currentUser = res.user;
      if (_currentUser != null) {
        final meta = _currentUser!.userMetadata;
        final profile = UserProfileModel(
          id: _currentUser!.id,
          email: _currentUser!.email ?? account.email,
          fullName:
              meta?['full_name']?.toString() ?? account.displayName,
          avatarUrl:
              meta?['avatar_url']?.toString() ??
              meta?['picture']?.toString() ??
              account.photoUrl,
        );
        _userProfile = profile;
        await _storage.saveUserProfile(profile);
        if (profile.avatarUrl != null) {
          unawaited(AvatarCacheService.instance.preCacheAvatar(profile.avatarUrl));
        }
        await _syncService.syncAll();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User deliberately canceled account selection (no error banner)
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _errorMessage =
          'Google Sign-In failed (${e.code.name}): ${e.description ?? e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google Sign-In error: $e';
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
