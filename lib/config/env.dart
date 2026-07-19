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

  /// API Gateway base URL (Terraform output: `api_endpoint`).
  static const String apiEndpoint = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: 'https://nv3jx897x9.execute-api.ap-southeast-1.amazonaws.com',
  );

  /// AWS region tất cả tài nguyên được deploy.
  static const String awsRegion = String.fromEnvironment(
    'AWS_REGION',
    defaultValue: 'ap-southeast-1',
  );

  /// Cognito User Pool ID (Terraform output: `cognito_user_pool_id`).
  static const String cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: 'ap-southeast-1_MnBh9j0uR',
  );

  /// Cognito App Client ID (Terraform output: `cognito_client_id`).
  static const String cognitoClientId = String.fromEnvironment(
    'COGNITO_CLIENT_ID',
    defaultValue: '1igibvo3fq9m8deiepco56nu9i',
  );

  /// Cognito Hosted-UI (OAuth) domain — dùng cho social sign-in.
  static const String cognitoWebDomain = String.fromEnvironment(
    'COGNITO_WEB_DOMAIN',
    defaultValue: 'helpme-auth-mndkh.auth.ap-southeast-1.amazoncognito.com',
  );
}
