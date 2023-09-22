const Sentry = require("@sentry/serverless");
const { ObjectId } = require('mongodb');
const { z, ZodError } = require("zod");
const normalizeEvent = require('/opt/nodejs/normalizer');
const response = require('/opt/nodejs/response');
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

const updateClientDto = z.object({
    name: z.string(),
    email: z.string().email(),
});

const handler = async (event) => {
    if (debugEnabled) console.log({ event });

    try {
        const mongoClient = await getMongoClient();
        const { data, pathParameters } = normalizeEvent(event);
        if (!pathParameters?.id) {
            return response(400, { success: false });
        }

        const doc = updateClientDto.parse(data)
        const { id } = pathParameters

        await mongoClient
            .collection("clients")
            .updateOne(
                { _id: new ObjectId(id) },
                { $set: { ...doc, updatedAt: new Date() } }
            )
        if (debugEnabled) {
            console.log(`Update client ${doc.name} with id ${id}.`)
        }
        return response(200, { success: true, _id: id });
    } catch (error) {
        if (error instanceof ZodError) {
            return response(500, { error, message: 'Validation error.' });
        }

        return response(500, { message: error?.message ?? error });
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