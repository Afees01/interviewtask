class CategoryException implements Exception {
  const CategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidCategoryNameException extends CategoryException {
  const InvalidCategoryNameException()
      : super('Category name cannot be empty.');
}

class DuplicateCategoryException extends CategoryException {
  const DuplicateCategoryException()
      : super('A category with this name already exists under this parent.');
}

class CategoryNotFoundException extends CategoryException {
  const CategoryNotFoundException()
      : super('The requested category was not found.');
}

class ParentCategoryNotFoundException extends CategoryException {
  const ParentCategoryNotFoundException()
      : super('The selected parent category was not found.');
}

class CircularCategoryException extends CategoryException {
  const CircularCategoryException()
      : super('A category cannot be moved under itself or its descendants.');
}

class UnauthenticatedCategoryException extends CategoryException {
  const UnauthenticatedCategoryException()
      : super('Sign in before accessing categories.');
}
