const AWS = require('aws-sdk');
const normalizeEvent = require('/opt/nodejs/normalizer');
const response = require('/opt/nodejs/response');

const {
  COGNITO_APP_CLIENT_ID,
  DEBUG,
} = process.env;

exports.handler = async (event) => {
  const { data } = normalizeEvent(event);
  if (DEBUG) {
    console.log({ data, event });
  }

  try {
    // Create an instance of the AWS Cognito IdentityServiceProvider
    const identityServiceProvider = new AWS.CognitoIdentityServiceProvider();
    const { AuthenticationResult } = await new Promise((resolve, reject) => {
      identityServiceProvider.initiateAuth({
        AuthFlow: "USER_PASSWORD_AUTH",
        AuthParameters: {
          "PASSWORD": data.password,
          "USERNAME": data.username
        },
        ClientId: COGNITO_APP_CLIENT_ID
      }, function (err, data) {
        if (err) {
          console.log({ auth: { err, stack: err.stack }});
          reject(err); // an error occurred
        } else {
          resolve(data); // successful response
        }
      })
    });

    return response(200, {
      // accessToken: AuthenticationResult.AccessToken,
      accessToken: AuthenticationResult.IdToken,
      refreshToken: AuthenticationResult.RefreshToken,
    });
  } catch (error) {
    return response(500, { message: error.message });
  }
};
