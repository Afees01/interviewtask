import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
    required super.phone,
    required super.website,
    required super.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    if (company is! Map<String, dynamic>) {
      throw const FormatException('User response is missing company details.');
    }

    return UserModel(
      id: _readId(json['id']),
      name: _readRequiredString(json, 'name'),
      username: _readRequiredString(json, 'username'),
      email: _readRequiredString(json, 'email'),
      phone: _readString(json['phone']),
      website: _readString(json['website']),
      company: _readString(company['name']),
    );
  }

  static int _readId(Object? value) {
    if (value is int && value > 0) {
      return value;
    }
    throw const FormatException('User response contains an invalid ID.');
  }

  static String _readRequiredString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('User response is missing $key.');
  }

  static String _readString(Object? value) => value is String ? value : '';
}
