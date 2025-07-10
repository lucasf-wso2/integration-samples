import ballerinax/ai.agent;

configurable string MISTRAL_TOKEN = ?;
configurable string PINECONE_API_KEY = ?;
configurable string PINECONE_URL = ?;
configurable agent:MISTRAL_AI_MODEL_NAMES MISTRAL_MODEL = "mistral-large-latest";