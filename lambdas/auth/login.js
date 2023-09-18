const AWS = require('aws-sdk');
const response = require('/opt/nodejs/response');
const normalizeEvent = require('/opt/nodejs/normalizer');
const getMongoClient = require('/opt/nodejs/getMongoClient');

const { COGNITO_APP_CLIENT_ID } = process.env;

exports.handler = async (event) => {
  const { data } = normalizeEvent(event);

  try {
    const mongoClient = await getMongoClient();
    const admin = await mongoClient
      .collection("admins")
      .findOne({ email: data.username });

    if (!admin) {
      return response(404, {
        message: "User not found."
      });
    }

    // Create an instance of the AWS Cognito IdentityServiceProvider
    const identityServiceProvider = new AWS.CognitoIdentityServiceProvider();
    const authResult = await new Promise((resolve, reject) => {
      identityServiceProvider.initiateAuth({
        AuthFlow: "USER_PASSWORD_AUTH",
        AuthParameters: {
          "PASSWORD": data.password,
          "USERNAME": data.username
        },
        ClientId: COGNITO_APP_CLIENT_ID
      }, async function (err, data) {
        if (err) {
          console.error({ auth: { err, stack: err.stack }});
          reject(err);
        } else {
          const { IdToken: accessToken, RefreshToken: refreshToken } = data.AuthenticationResult
          const { _id, name, email } = admin

          resolve({
            id: _id.toString(),
            email,
            name,
            accessToken,
            refreshToken
          });
        }
      })
    });

    return response(200, authResult);
  } catch (error) {
    return response(401, { message: error.message });
  }
};
