import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/exceptions/category_exception.dart';
import '../../domain/usecases/add_category.dart' as add_use_case;
import '../../domain/usecases/delete_category.dart' as delete_use_case;
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_children.dart';
import '../../domain/usecases/search_categories.dart' as search_use_case;
import '../../domain/usecases/update_category.dart' as update_use_case;
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({
    required add_use_case.AddCategory addCategory,
    required update_use_case.UpdateCategory updateCategory,
    required delete_use_case.DeleteCategory deleteCategory,
    required GetCategories getCategories,
    required GetChildren getChildren,
    required search_use_case.SearchCategories searchCategories,
  })  : _addCategory = addCategory,
        _updateCategory = updateCategory,
        _deleteCategory = deleteCategory,
        _getCategories = getCategories,
        _getChildren = getChildren,
        _searchCategories = searchCategories,
        super(const CategoryInitial()) {
    on<ClearCategories>((event, emit) {
      _sessionGeneration++;
      _searchGeneration++;
      _lastCategories = const [];
      emit(const CategoryInitial());
    });
    on<LoadCategories>(_onLoadCategories);
    on<SearchCategories>(_onSearchCategories);
    on<ClearCategorySearch>(_onClearCategorySearch);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<LoadChildren>(_onLoadChildren);
  }

  final add_use_case.AddCategory _addCategory;
  final update_use_case.UpdateCategory _updateCategory;
  final delete_use_case.DeleteCategory _deleteCategory;
  final GetCategories _getCategories;
  final GetChildren _getChildren;
  final search_use_case.SearchCategories _searchCategories;
  List<Category> _lastCategories = const [];
  int _sessionGeneration = 0;
  int _searchGeneration = 0;

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    final generation = _sessionGeneration;
    emit(const CategoryLoading());
    try {
      final categories = await _getCategories(rootsOnly: event.rootsOnly);
      if (generation == _sessionGeneration) {
        _lastCategories = categories;
        emit(CategoryLoaded(categories));
      }
    } on CategoryException catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError(error.message));
      }
    } catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError('Unable to load categories: $error'));
      }
    }
  }

  Future<void> _onSearchCategories(
    SearchCategories event,
    Emitter<CategoryState> emit,
  ) async {
    final generation = ++_searchGeneration;
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const CategorySearchEmpty(''));
      return;
    }

    emit(CategorySearchLoading(query));
    try {
      final results = await _searchCategories(query);
      if (generation == _searchGeneration) {
        if (results.isEmpty) {
          emit(CategorySearchEmpty(query));
        } else {
          emit(CategorySearchSuccess(query: query, results: results));
        }
      }
    } on CategoryException catch (error) {
      if (generation == _searchGeneration) {
        emit(CategorySearchError(query: query, message: error.message));
      }
    } catch (error) {
      if (generation == _searchGeneration) {
        emit(
          CategorySearchError(
            query: query,
            message: 'Unable to search categories: $error',
          ),
        );
      }
    }
  }

  void _onClearCategorySearch(
    ClearCategorySearch event,
    Emitter<CategoryState> emit,
  ) {
    _searchGeneration++;
    emit(CategoryLoaded(_lastCategories));
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final generation = _sessionGeneration;
    emit(const CategoryLoading());
    try {
      final category = await _addCategory(event.name, parentId: event.parentId);
      if (generation == _sessionGeneration) {
        emit(
          CategoryOperationSuccess(
            message: 'Category added.',
            category: category,
          ),
        );
      }
    } on CategoryException catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError(error.message));
      }
    } catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError('Unable to add category: $error'));
      }
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final generation = _sessionGeneration;
    emit(const CategoryLoading());
    try {
      final category = await _updateCategory(
        id: event.id,
        name: event.name,
        parentId: event.parentId,
      );
      if (generation == _sessionGeneration) {
        emit(
          CategoryOperationSuccess(
            message: 'Category updated.',
            category: category,
          ),
        );
      }
    } on CategoryException catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError(error.message));
      }
    } catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError('Unable to update category: $error'));
      }
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final generation = _sessionGeneration;
    emit(const CategoryLoading());
    try {
      await _deleteCategory(event.id);
      if (generation == _sessionGeneration) {
        emit(
          CategoryOperationSuccess(
            message: 'Category and its descendants deleted.',
            categoryId: event.id,
          ),
        );
      }
    } on CategoryException catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError(error.message));
      }
    } catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError('Unable to delete category: $error'));
      }
    }
  }

  Future<void> _onLoadChildren(
    LoadChildren event,
    Emitter<CategoryState> emit,
  ) async {
    final generation = _sessionGeneration;
    emit(const CategoryLoading());
    try {
      final children = await _getChildren(event.parentId);
      if (generation == _sessionGeneration) {
        emit(CategoryLoaded(children, parentId: event.parentId));
      }
    } on CategoryException catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError(error.message));
      }
    } catch (error) {
      if (generation == _sessionGeneration) {
        emit(CategoryError('Unable to load subcategories: $error'));
      }
    }
  }
}
