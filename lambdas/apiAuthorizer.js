// Import necessary AWS SDK libraries
const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');

// Create an instance of the AWS Cognito IdentityServiceProvider
const identityServiceProvider = new AWS.CognitoIdentityServiceProvider();

// Helper function to generate an IAM policy
const generatePolicy = (principalId, effect, resource) => ({
  principalId: principalId,
  policyDocument: {
    Version: '2012-10-17',
    Statement: [
      {
        Action: 'execute-api:Invoke',
        Effect: effect,
        Resource: resource,
      },
    ],
  },
});

// Define your Lambda function handler
exports.handler = async (event, context) => {
  // Get the authorization token from the request headers
  const authToken = event.headers.Authorization;
  console.log({ authToken });
  if (!authToken) {
    return generatePolicy('user', 'Deny', event.methodArn);
  }

  // Validate and decode the JWT token
  try {
    const decodedToken = jwt.decode(authToken, { complete: true });

    // Extract the Cognito User Pool ID and Username from the decoded token
    const userPoolId = decodedToken.payload.iss;
    const username = decodedToken.payload.username;

    // Use the Cognito IdentityServiceProvider to validate the token
    const params = {
      UserPoolId: userPoolId,
      Username: username,
    };

    await identityServiceProvider.adminGetUser(params).promise();

    // If the user exists in Cognito and the token is valid, return an IAM policy
    return generatePolicy(username, 'Allow', event.methodArn);
  } catch (error) {
    console.error('Authorization error:', error);
    // If there's an error, deny access
    return generatePolicy('user', 'Deny', event.methodArn);
  }
};
