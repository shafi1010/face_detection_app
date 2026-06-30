class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String tenantId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.tenantId,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'viewer',
      tenantId: json['tenant_id'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'tenant_id': tenantId,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isAdmin => role == 'admin';
  bool get isOperator => role == 'operator';
}
