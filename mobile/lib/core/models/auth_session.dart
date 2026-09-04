enum UserRole {
  customer,
  dispatcher,
  driver,
  storeAdmin;

  static UserRole fromJson(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return UserRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => throw FormatException('Unknown user role: $value'),
    );
  }
}

final class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
  });

  factory AppUser.fromJson(Map<String, Object?> json) => AppUser(
    id: json['id']! as String,
    email: json['email']! as String,
    displayName: json['displayName']! as String,
    role: UserRole.fromJson(json['role']),
    phoneNumber: json['phoneNumber'] as String?,
  );

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
}

final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAtUtc,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, Object?> json) => AuthSession(
    accessToken: json['accessToken']! as String,
    expiresAtUtc: DateTime.parse(json['expiresAtUtc']! as String).toUtc(),
    user: AppUser.fromJson(json['user']! as Map<String, Object?>),
  );

  final String accessToken;
  final DateTime expiresAtUtc;
  final AppUser user;
}
