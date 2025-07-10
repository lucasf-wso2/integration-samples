import ballerina/http;
import ballerina/io;
import ballerinax/ai.agent;

listener agent:Listener hrRagAgentListener = new (listenOn = check http:getDefaultListener());

service /hrRagAgent on hrRagAgentListener {
    resource function post chat(@http:Payload agent:ChatReqMessage request) returns agent:ChatRespMessage|error {
        string requestMessage = request.message;
        string agentResponse = check llmChat(requestMessage);
        return {message: agentResponse};
    }
}

public function main() returns error? {
    io:println("Testing HR AI Chat Agent with paternity leave query...");
    io:println("Query: 'how many days for paternity leave?'");
    io:println("Processing...");
    
    string|error result = testPaternityLeaveQuery();
    if result is error {
        string errorMessage = result.message();
        io:println("Error occurred: ", errorMessage);
        return result;
    } else {
        io:println("Response: ", result);
        io:println("Test completed successfully!");
    }
}