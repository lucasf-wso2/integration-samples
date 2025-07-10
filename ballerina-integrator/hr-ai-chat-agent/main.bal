import ballerina/http;
import ballerinax/ai.agent;

listener agent:Listener hrRagAgentListener = new (listenOn = check http:getDefaultListener());

service /hrRagAgent on hrRagAgentListener {
    resource function post chat(@http:Payload agent:ChatReqMessage request) returns agent:ChatRespMessage|error {
        string requestMessage = request.message;
        string agentResponse = check llmChat(requestMessage);
        return {message: agentResponse};
    }
}