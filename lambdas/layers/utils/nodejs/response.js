function responseHandler (status, body) {
  return {
    statusCode: status,
    body: JSON.stringify(body),
    headers: {
      "Access-Control-Allow-Headers" : "Authorization, Content-Type",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "*",
      'Content-Type': 'application/json',
    },
  };
};

module.exports = responseHandler;