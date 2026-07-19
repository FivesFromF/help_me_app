import 'config/env.dart';

// Các giá trị Cognito được nội suy từ lib/config/env.dart (nguồn duy nhất).
// Amplify.configure() parse chuỗi này lúc runtime; vẫn giữ const vì Env.* là const.
const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/1.0",
        "Version": "1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "${Env.cognitoUserPoolId}",
            "AppClientId": "${Env.cognitoClientId}",
            "Region": "${Env.awsRegion}"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "${Env.cognitoWebDomain}",
              "AppClientId": "${Env.cognitoClientId}",
              "SignInRedirectURI": "helpme://auth-callback",
              "SignOutRedirectURI": "helpme://auth-logout",
              "Scopes": [
                "phone",
                "email",
                "openid",
                "profile",
                "aws.cognito.signin.user.admin"
              ]
            },
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [
              "GOOGLE"
            ],
            "usernameAttributes": [
              "EMAIL"
            ],
            "signupAttributes": [
              "EMAIL"
            ],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": [
                "REQUIRES_LOWERCASE",
                "REQUIRES_UPPERCASE",
                "REQUIRES_NUMBERS"
              ]
            },
            "mfaConfiguration": "OFF",
            "mfaTypes": [
              "SMS"
            ],
            "verificationMechanisms": [
              "EMAIL"
            ]
          }
        }
      }
    }
  }
}''';
