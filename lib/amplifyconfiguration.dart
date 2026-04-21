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
            "PoolId": "ap-southeast-1_MnBh9j0uR",
            "AppClientId": "1igibvo3fq9m8deiepco56nu9i",
            "Region": "ap-southeast-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "helpme-auth-mndkh.auth.ap-southeast-1.amazoncognito.com",
              "AppClientId": "1igibvo3fq9m8deiepco56nu9i",
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
