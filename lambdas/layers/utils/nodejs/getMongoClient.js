const AWS = require('aws-sdk');
const { MongoClient } = require('mongodb');

let mongoClient;

const {
  DB_NAME,
  DB_CONNECTION_URI,
  DEBUG,
  SSM_PARAMETER_DB_USERNAME,
  SSM_PARAMETER_DB_PASSWORD,
} = process.env;

const environment = DEBUG === "true" ? "dev" : "production";

const getMongoClient = async () => {
  if (mongoClient) return mongoClient.db(DB_NAME);

  let dbUsername, dbPassword;
  const ssm = new AWS.SSM();

  try {
    const ssmParameterDbUsername = await ssm.getParameter({ Name: SSM_PARAMETER_DB_USERNAME ?? '' }).promise();
    dbUsername = ssmParameterDbUsername?.Parameter.Value;

    const ssmParameterDbPassword = await ssm.getParameter({ Name: SSM_PARAMETER_DB_PASSWORD ?? '' }).promise();
    dbPassword = ssmParameterDbPassword?.Parameter.Value;
  } catch (error) {
    console.error('@getMongoClient: ssmParameters', error);
  }
  
  return new Promise((resolve, reject) => {
    const mongoDbUri = `${(DB_CONNECTION_URI ?? '')
      .replace('<username>', dbUsername)
      .replace('<password>', dbPassword)}/${environment}`;

    try {
      mongoClient = new MongoClient(mongoDbUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true
      });

      resolve(mongoClient.db(DB_NAME));
    } catch (error) {
      console.error({ error, mongoDbUri })
      reject(error);
    }
  });
};

module.exports = getMongoClient;