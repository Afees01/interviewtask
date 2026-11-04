import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_search_result.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

final class CategoryLoaded extends CategoryState {
  const CategoryLoaded(this.categories, {this.parentId});

  final List<Category> categories;
  final int? parentId;

  @override
  List<Object?> get props => [categories, parentId];
}

final class CategoryOperationSuccess extends CategoryState {
  const CategoryOperationSuccess({
    required this.message,
    this.category,
    this.categoryId,
  });

  final String message;
  final Category? category;
  final int? categoryId;

  @override
  List<Object?> get props => [message, category, categoryId];
}

final class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class CategorySearchLoading extends CategoryState {
  const CategorySearchLoading(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CategorySearchSuccess extends CategoryState {
  const CategorySearchSuccess({
    required this.query,
    required this.results,
  });

  final String query;
  final List<CategorySearchResult> results;

  @override
  List<Object?> get props => [query, results];
}

final class CategorySearchEmpty extends CategoryState {
  const CategorySearchEmpty(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CategorySearchError extends CategoryState {
  const CategorySearchError({
    required this.query,
    required this.message,
  });

  final String query;
  final String message;

  @override
  List<Object?> get props => [query, message];
}
