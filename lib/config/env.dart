/// Cấu hình môi trường tập trung cho toàn app.
///
/// ĐÂY là nơi DUY NHẤT chứa các giá trị từ Terraform outputs của backend.
/// Sau mỗi lần `terraform apply` mà các ID thay đổi (API Gateway id, Cognito
/// User Pool / App Client), chỉ cần sửa ở file này — auth_service.dart và
/// amplifyconfiguration.dart đều đọc từ đây.
///
/// Có thể override lúc build bằng --dart-define, ví dụ:
///   flutter run --dart-define=API_ENDPOINT=https://xxxx.execute-api...
class Env {
  Env._();

  /// API Gateway / CloudFront base URL.
  static const String apiEndpoint = String.fromEnvironment('API_ENDPOINT');

  /// AWS region tất cả tài nguyên được deploy.
  static const String awsRegion = String.fromEnvironment('AWS_REGION');

  /// Cognito User Pool ID (Terraform output: `cognito_user_pool_id`).
  static const String cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
  );

  /// Cognito App Client ID (Terraform output: `cognito_client_id`).
  static const String cognitoClientId = String.fromEnvironment(
    'COGNITO_CLIENT_ID',
  );

  /// Cognito Hosted-UI (OAuth) domain — dùng cho social sign-in (không chứa https://).
  static const String cognitoWebDomain = String.fromEnvironment(
    'COGNITO_WEB_DOMAIN',
  );
}
