class UserProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  UserProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  String get initials {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName!.substring(0, 1).toUpperCase();
    }
    if (email.isNotEmpty) {
      return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }

  factory UserProfileModel.fromMap(Map<dynamic, dynamic> map) {
    return UserProfileModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}
