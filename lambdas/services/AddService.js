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

const newServiceDto = z.object({
    name: z.string(),
    description: z.string(),
    basePrice: z.number(),
    paymentCycle: z.enum(['hourly', 'daily', 'monthly', 'one-time']),
})

const handler = async (event) => {
    if (debugEnabled) console.log({ event });

    try {
        const mongoClient = await getMongoClient();
        const { data } = normalizeEvent(event);
        const doc = newServiceDto.parse(data)
        const newService = await mongoClient
            .collection("services")
            .insertOne({ ...doc, createdAt: new Date() })
        if (debugEnabled) {
            console.log(`Registered service ${doc.name} with id ${newService.insertedId}.`)
        }
        return response(200, { success: true, _id: newService.insertedId });
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