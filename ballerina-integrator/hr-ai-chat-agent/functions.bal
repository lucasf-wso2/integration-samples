import ballerina/http;
import ballerinax/pinecone.vector;

final http:Client mistralEmbeddingsClient = check new ("https://api.mistral.ai", {
    auth: {
        token: MISTRAL_TOKEN
    }
});

final http:Client mistralChatClient = check new ("https://api.mistral.ai", {
    auth: {
        token: MISTRAL_TOKEN
    }
});

final vector:Client pineconeVectorClient = check new ({
    apiKey: PINECONE_API_KEY
}, serviceUrl = PINECONE_URL);

vector:QueryRequest queryRequest = {
    topK: 4,
    includeMetadata: true
};

public type Metadata record {
    string text;
};

public type MistralEmbeddingRequest record {
    string model;
    string[] input;
};

public type MistralEmbeddingData record {
    float[] embedding;
    int index;
    string 'object;
};

public type MistralEmbeddingResponse record {
    string 'object;
    MistralEmbeddingData[] data;
    string model;
    record {} usage;
};

public type MistralChatMessage record {
    string role;
    string content;
};

public type MistralChatRequest record {
    string model;
    MistralChatMessage[] messages;
    decimal temperature?;
    int max_tokens?;
};

public type MistralChatChoice record {
    int index;
    MistralChatMessage message;
    string finish_reason;
};

public type MistralChatResponse record {
    string id;
    string 'object;
    int created;
    string model;
    MistralChatChoice[] choices;
    record {} usage;
};

function llmChat(string query) returns string|error {
    float[] embeddingsFloat = check getEmbeddings(query);
    queryRequest.vector = embeddingsFloat;
    vector:QueryMatch[] matches = check retrieveData(queryRequest);
    string context = check augment(matches);
    string chatResponse = check generateText(query, context);
    return chatResponse;
}

function getEmbeddings(string query) returns float[]|error {
    MistralEmbeddingRequest embeddingRequest = {
        model: "mistral-embed",
        input: [query]
    };

    MistralEmbeddingResponse embeddingResponse = check mistralEmbeddingsClient->/v1/embeddings.post(embeddingRequest);
    float[] embeddings = embeddingResponse.data[0].embedding;
    return embeddings;
}

isolated function retrieveData(vector:QueryRequest queryRequest) returns vector:QueryMatch[]|error {
    vector:QueryResponse response = check pineconeVectorClient->/query.post(queryRequest);
    vector:QueryMatch[]? matches = response.matches;
    if (matches == null) {
        return error("No matches found");
    }
    return matches;
}

isolated function augment(vector:QueryMatch[] matches) returns string|error {
    string context = "";
    foreach vector:QueryMatch data in matches {
        Metadata metadata = check data.metadata.cloneWithType();
        string metadataText = metadata.text;
        context = context.concat(metadataText);
    }
    return context;
}

isolated function generateText(string query, string context) returns string|error {
    string modelName = MISTRAL_MODEL.toString();
    string systemPrompt = string `You are an HR Policy Assistant that provides employees with accurate answers
        based on company HR policies. Your responses must be clear and strictly based on the provided context.
        ${context}`;

    MistralChatRequest chatRequest = {
        model: modelName,
        messages: [
            {
                role: "system",
                content: systemPrompt
            },
            {
                role: "user",
                content: query
            }
        ],
        temperature: 0.7,
        max_tokens: 1000
    };

    MistralChatResponse chatResponse = check mistralChatClient->/v1/chat/completions.post(chatRequest);
    string responseContent = chatResponse.choices[0].message.content;
    return responseContent;
}