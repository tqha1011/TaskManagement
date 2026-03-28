class UserModel {
  final String id;
  final String email;
  final String username;
  final int? age;
  final String? avatar;
  final String? timezone;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.age,
    this.avatar,
    this.timezone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String email) {
    return UserModel(
      id: json['id'] ?? '',
      email: email,
      username: json['username'] ?? 'No Name',
      age: json['age'],
      avatar: json['avatar'],
      timezone: json['timezone'],
    );
  }
}