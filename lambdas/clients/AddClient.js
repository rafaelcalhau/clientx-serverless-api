const Sentry = require("@sentry/serverless");
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

const newClientDto = z.object({
    name: z.string(),
    email: z.string().email('Invalid email address.')
})

const handler = async (event, context) => {
    if (debugEnabled) console.log({ event });

    try {
        const mongoClient = await getMongoClient();
        const { data } = normalizeEvent(event);
        const doc = newClientDto.parse(data)
        const newClient = await mongoClient
            .collection("clients")
            .insertOne({ ...doc, createdAt: new Date() })
        if (debugEnabled) {
            console.log(`Registered client ${doc.name} with id ${newClient.insertedId}.`)
        }
        return response(200, { success: true, _id: newClient.insertedId });
    } catch (error) {
        if (error instanceof ZodError) {
            const message = error.issues.map(issue => issue.message)?.join('; ') ?? 'Data validation error.'
            return response(500, { message });
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