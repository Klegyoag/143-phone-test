class ApiException implements Exception {
  ApiException({required this.message, this.code, this.statusCode, this.errors});

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}
