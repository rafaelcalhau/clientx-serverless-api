const normalizeEvent = event => ({
  data: event['body'] ? JSON.parse(event['body']) : {},
  querystring: event['queryStringParameters'] || {},
  pathParameters: event['pathParameters'] || {},
});

module.exports = normalizeEvent;