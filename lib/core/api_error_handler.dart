import 'logger.dart';

/// Centralized error handling for API calls
class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      
      // Network errors
      if (message.contains('SocketException') || 
          message.contains('HandshakeException') ||
          message.contains('TimeoutException')) {
        return 'Network connection error. Please check your internet connection.';
      }
      
      // HTTP errors
      if (message.contains('404')) {
        return 'Content not found.';
      }
      
      if (message.contains('429')) {
        return 'Too many requests. Please try again later.';
      }
      
      if (message.contains('500') || message.contains('502') || message.contains('503')) {
        return 'Server error. Please try again later.';
      }
      
      // API specific errors
      if (message.contains('AniList API Error')) {
        return 'AniList service is temporarily unavailable.';
      }
      
      // Generic API errors
      if (message.contains('Failed to fetch') || message.contains('Failed to search')) {
        return 'Unable to load data. Please try again.';
      }
      
      // Return the original message if it's user-friendly
      if (!message.contains('Exception:') && message.length < 100) {
        return message;
      }
    }
    
    // Fallback error message
    return 'Something went wrong. Please try again.';
  }
  
  /// Log API errors using the centralized logger
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.apiError('API call', error, stackTrace);
  }
}

/// Loading state enum
enum LoadingState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

/// Generic result wrapper for API calls
class ApiResult<T> {
  final T? data;
  final String? error;
  final LoadingState state;
  
  const ApiResult._({
    this.data,
    this.error,
    required this.state,
  });
  
  factory ApiResult.loading() => const ApiResult._(state: LoadingState.loading);
  
  factory ApiResult.success(T data) => ApiResult._(
    data: data,
    state: LoadingState.loaded,
  );
  
  factory ApiResult.error(String error) => ApiResult._(
    error: error,
    state: LoadingState.error,
  );
  
  factory ApiResult.empty() => const ApiResult._(state: LoadingState.empty);
  
  bool get isLoading => state == LoadingState.loading;
  bool get isSuccess => state == LoadingState.loaded && data != null;
  bool get isError => state == LoadingState.error;
  bool get isEmpty => state == LoadingState.empty;
  
  /// Transform the data if successful
  ApiResult<U> map<U>(U Function(T data) transform) {
    if (isSuccess) {
      final dataValue = data;
      if (dataValue != null) {
        try {
          return ApiResult.success(transform(dataValue));
        } catch (e) {
          return ApiResult.error(ApiErrorHandler.getErrorMessage(e));
        }
      }
    }
    
    return ApiResult._(
      error: error,
      state: state,
    );
  }
  
  /// Handle the result with callbacks
  U when<U>({
    required U Function() loading,
    required U Function(T data) success,
    required U Function(String error) error,
    required U Function() empty,
  }) {
    switch (state) {
      case LoadingState.loading:
        return loading();
      case LoadingState.loaded:
        return success(data as T);
      case LoadingState.error:
        return error(this.error ?? 'Unknown error');
      case LoadingState.empty:
        return empty();
      case LoadingState.initial:
        return loading(); // Treat initial as loading
    }
  }
}
