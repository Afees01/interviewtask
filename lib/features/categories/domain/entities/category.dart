import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.parentId,
    required this.createdAt,
    required this.userId,
    this.children = const [],
  });

  final int? id;
  final String name;
  final int? parentId;
  final DateTime createdAt;
  final int userId;
  final List<Category> children;

  @override
  List<Object?> get props => [id, name, parentId, createdAt, userId, children];
}
