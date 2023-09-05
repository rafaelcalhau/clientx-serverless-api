const { ObjectId } = require('mongodb');
const Sentry = require("@sentry/serverless");
const response = require('/opt/nodejs/response');
const normalizeEvent = require('/opt/nodejs/normalizer');
const getMongoClient = require('/opt/nodejs/getMongoClient');

const {
    DEBUG,
    SENTRY_DSN,
    SENTRY_ENABLED,
    SENTRY_TRACES_SAMPLE_RATE,
} = process.env;

const debugEnabled = DEBUG === "true";
const useSentryAPM = SENTRY_ENABLED === "true";
const tracesSampleRate = typeof SENTRY_TRACES_SAMPLE_RATE === 'string'
    ? Number(SENTRY_TRACES_SAMPLE_RATE)
    : 0;

const handler = async (event, context) => {
    if (debugEnabled) console.log({ event });

    const { pathParameters, querystring } = normalizeEvent(event);
    if (debugEnabled) console.log({ pathParameters, querystring });
    const mongoClient = await getMongoClient();

    if (pathParameters?.id) {
        try {
            const customer = await mongoClient
                .collection("customers")
                .findOne({ _id: new ObjectId(pathParameters.id) });

            if (debugEnabled) {
                console.log({
                    message: 'Customers has been fetched.',
                    customer,
                });
            }
    
            return response(200, customer);
        } catch (err) {
            console.error(err);
            return response(500, {
                message: 'Woops, somenthing went wrong.'
            });
        }
    } else {
        try {
            const customers = await mongoClient
                .collection("customers")
                .find({})
                .toArray();
    
            console.log({
                message: 'Customers has been fecthed.',
                customers,
            });
    
            return response(200, customers);
        } catch (err) {
            console.error(err);
            return response(500, {
                msg: 'Somenthing went wrong',
                error: err.message,
            });
        }
    }
};

if (useSentryAPM) {
    Sentry.AWSLambda.init({
        dsn: SENTRY_DSN,
        
        // Set tracesSampleRate to 1.0 to capture 100%
        // of transactions for performance monitoring.
        // We recommend adjusting this value in production
        tracesSampleRate,
        timeoutWarningLimit: 50,
    });
}

exports.handler = useSentryAPM
    ? Sentry.AWSLambda.wrapHandler(handler)
    : handler;