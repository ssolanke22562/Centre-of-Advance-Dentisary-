enum UserRole {
  admin,
  receptionist,
}

extension UserRoleExtension on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.receptionist:
        return 'Receptionist';
    }
  }

  static UserRole fromString(String value) {
    if (value.toLowerCase() == 'admin') {
      return UserRole.admin;
    }
    return UserRole.receptionist;
  }
}

class UserModel {
  final int? id;
  final String email;
  final String passwordHash;
  final String salt;
  final UserRole role;
  final String name;

  UserModel({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.role,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role == UserRole.admin ? 'admin' : 'receptionist',
      'name': name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      role: UserRoleExtension.fromString(map['role'] as String),
      name: map['name'] as String? ?? 'Staff User',
    );
  }
}

class UserSession {
  final String email;
  final UserRole role;
  final String name;
  final DateTime loginTime;

  UserSession({
    required this.email,
    required this.role,
    required this.name,
    required this.loginTime,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isReceptionist => role == UserRole.receptionist;
}
