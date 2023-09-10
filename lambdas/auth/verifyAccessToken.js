const response = require('/opt/nodejs/response');

exports.handler = async (event, context) => {
    return response(200, { status: true });
};