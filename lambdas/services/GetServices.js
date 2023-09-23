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

const handler = async (event) => {
    if (debugEnabled) console.log({ event });

    const { pathParameters, querystring } = normalizeEvent(event);
    if (debugEnabled) console.log({ pathParameters, querystring });
    
    const mongoClient = await getMongoClient();
    if (pathParameters?.id) {
        try {
            const service = await mongoClient
                .collection("services")
                .findOne({ _id: new ObjectId(pathParameters.id) });

            if (debugEnabled) {
                console.log({
                    message: 'Service data has been fetched.',
                    service,
                });
            }
    
            return response(200, service);
        } catch (err) {
            console.error(err);
            return response(500, {
                message: 'Whoops, something went wrong.'
            });
        }
    } else {
        const limit = Number(querystring?.limit ?? 25);
        const page = Number(querystring?.page ?? 1);
        const skip = limit * (page - 1)

        try {
            const queryPipeline = [
                {
                  $facet: {
                    services: [
                      { $match: {} },
                      { $skip: skip },
                      { $limit: limit },
                    ],
                    totalServices: [
                      { $count: "total" },
                    ],
                  },
                },
                {
                  $unwind: "$totalServices",
                },
              ];

            const [{ services, totalServices }] = await mongoClient
                .collection("services")
                .aggregate(queryPipeline)
                .toArray();
    
            if (debugEnabled) {
                console.log({
                    message: 'Services has been fecthed.',
                    services,
                    totalServices,
                });
            }
    
            return response(200, {
                data: services,
                total: totalServices.total
            });
        } catch (err) {
            console.error(err);
            return response(500, {
                msg: 'Something went wrong',
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