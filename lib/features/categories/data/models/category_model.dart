import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.parentId,
    required super.createdAt,
    required super.userId,
    super.children,
  });

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final parentId = map['parent_id'];
    final createdAt = map['created_at'];
    final userId = map['user_id'];
    if (id is! int || name is! String || createdAt is! String) {
      throw const FormatException('Invalid category database record.');
    }
    if (userId is! int || userId <= 0) {
      throw const FormatException('Invalid category owner.');
    }

    return CategoryModel(
      id: id,
      name: name,
      parentId: parentId as int?,
      createdAt: DateTime.parse(createdAt),
      userId: userId,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'];
    final children = childrenJson is List
        ? childrenJson.map((child) {
            if (child is! Map<String, dynamic>) {
              throw const FormatException('Invalid nested category record.');
            }
            return CategoryModel.fromJson(child);
          }).toList()
        : const <CategoryModel>[];

    return CategoryModel(
      id: _readNullableInt(json['id']),
      name: _readString(json['name'], 'name'),
      parentId: _readNullableInt(json['parent_id']),
      createdAt: DateTime.parse(_readString(json['created_at'], 'created_at')),
      userId: _readPositiveInt(json['user_id']),
      children: children,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user_id': userId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      ...toMap(),
      'children': children
          .map((child) => CategoryModel.fromEntity(child).toJson())
          .toList(),
    };
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      parentId: category.parentId,
      createdAt: category.createdAt,
      userId: category.userId,
      children: category.children
          .map(CategoryModel.fromEntity)
          .toList(growable: false),
    );
  }

  static int? _readNullableInt(Object? value) {
    if (value == null || value is int) {
      return value as int?;
    }
    throw const FormatException('Invalid category identifier.');
  }

  static String _readString(Object? value, String field) {
    if (value is String) {
      return value;
    }
    throw FormatException('Invalid category $field.');
  }

  static int _readPositiveInt(Object? value) {
    if (value is int && value > 0) {
      return value;
    }
    throw const FormatException('Invalid category owner.');
  }
}
