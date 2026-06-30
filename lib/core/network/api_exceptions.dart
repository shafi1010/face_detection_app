class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';

  factory ApiException.fromStatusCode(int code, {String? body}) {
    switch (code) {
      case 400:
        return ApiException('Bad request', statusCode: code, details: body);
      case 401:
        return ApiException('Unauthorized — check your credentials', statusCode: code, details: body);
      case 403:
        return ApiException('Forbidden — insufficient permissions', statusCode: code, details: body);
      case 404:
        return ApiException('Resource not found', statusCode: code, details: body);
      case 409:
        return ApiException('Resource conflict', statusCode: code, details: body);
      case 422:
        return ApiException('Validation error', statusCode: code, details: body);
      case 429:
        return ApiException('Rate limit exceeded — try again later', statusCode: code, details: body);
      case 500:
        return ApiException('Internal server error', statusCode: code, details: body);
      case 502:
        return ApiException('Bad gateway', statusCode: code, details: body);
      case 503:
        return ApiException('Service unavailable', statusCode: code, details: body);
      default:
        return ApiException('Request failed', statusCode: code, details: body);
    }
  }
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'No internet connection']);
}

class TimeoutException extends ApiException {
  const TimeoutException([super.message = 'Request timed out']);
}
