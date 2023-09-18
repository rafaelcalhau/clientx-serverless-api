const normalizeEvent = event => {
  const getBody = (event) => {
    if (typeof event?.body === "string") {
      return JSON.parse(event.body)
    } else if (typeof event?.body === "object") {
      return event.body
    }

    return {}
  }
  try {
    return {
      data: getBody(event),
      querystring: event['queryStringParameters'] || {},
      pathParameters: event['pathParameters'] || {},
    }
  } catch (error) {
    console.error('@normalizeEvent', { event })
  }

  return {
    data: {},
    querystring: {},
    pathParameters: {}
  }
};

module.exports = normalizeEvent;