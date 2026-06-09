part of '../../main.dart';

class SupabaseAppException implements Exception {
  SupabaseAppException({
    required this.plugin,
    required this.code,
    this.message,
  });

  final String plugin;
  final String code;
  final String? message;

  @override
  String toString() => message ?? '$plugin/$code';
}

class SupabaseAuthException extends SupabaseAppException {
  SupabaseAuthException({required super.code, super.message})
    : super(plugin: 'supabase_auth');
}

class StoredTimestamp {
  const StoredTimestamp._(this._dateTime);

  final DateTime _dateTime;

  factory StoredTimestamp.fromDate(DateTime dateTime) =>
      StoredTimestamp._(dateTime);

  DateTime toDate() => _dateTime;
}

class DatabaseValue {
  const DatabaseValue._();

  static DateTime serverTimestamp() => DateTime.now().toUtc();

  static List<T> arrayUnion<T>(List<T> values) => values;
}

class AuthCredential {
  const AuthCredential(this.user);

  final User? user;
}

class User {
  const User(this._inner);

  final supabase.User _inner;

  String get id => _inner.id;
  String? get email => _inner.email;

  String? get displayName {
    final metadata = _inner.userMetadata ?? const <String, dynamic>{};
    return metadata['name'] as String? ?? metadata['full_name'] as String?;
  }

  String? get photoURL {
    final metadata = _inner.userMetadata ?? const <String, dynamic>{};
    return metadata['photo_url'] as String? ??
        metadata['avatar_url'] as String?;
  }

  Future<void> updateDisplayName(String name) async {
    await supabase.Supabase.instance.client.auth.updateUser(
      supabase.UserAttributes(data: {'name': name}),
    );
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final data = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      data['name'] = displayName.trim();
    }
    if (photoUrl != null) {
      data['photo_url'] = photoUrl.trim();
    }
    if (data.isEmpty) {
      return;
    }

    await supabase.Supabase.instance.client.auth.updateUser(
      supabase.UserAttributes(data: data),
    );
  }

  Future<void> updatePassword(String password) async {
    await supabase.Supabase.instance.client.auth.updateUser(
      supabase.UserAttributes(password: password),
    );
  }
}

class SupabaseAuth {
  SupabaseAuth._();

  static final instance = SupabaseAuth._();

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  User? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : User(user);
  }

  Stream<User?> authStateChanges() {
    return (() async* {
      yield currentUser;
      yield* _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user ?? _client.auth.currentUser;
        return user == null ? null : User(user);
      });
    })();
  }

  Future<AuthCredential> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthCredential(
        response.user == null ? currentUser : User(response.user!),
      );
    } on supabase.AuthException catch (error) {
      throw SupabaseAuthException(
        code: _authCode(error),
        message: error.message,
      );
    }
  }

  Future<AuthCredential> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName == null || displayName.trim().isEmpty
            ? null
            : {'name': displayName.trim()},
      );
      return AuthCredential(
        response.user == null ? currentUser : User(response.user!),
      );
    } on supabase.AuthException catch (error) {
      throw SupabaseAuthException(
        code: _authCode(error),
        message: error.message,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (error) {
      throw SupabaseAuthException(
        code: _authCode(error),
        message: error.message,
      );
    }
  }

  String _authCode(supabase.AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'invalid-credential';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'email-already-in-use';
    }
    if (message.contains('password')) {
      return 'weak-password';
    }
    if (message.contains('invalid email') ||
        message.contains('validate email') ||
        message.contains('email address is invalid') ||
        message.contains('email format')) {
      return 'invalid-email';
    }
    return error.statusCode ?? 'auth-error';
  }
}
