class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class InvalidUserIdException extends AuthException {
  const InvalidUserIdException() : super('Enter a valid positive user ID.');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException()
      : super('No user was found for that ID. Please try another ID.');
}
