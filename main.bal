import ballerina/http;
import ballerinax/twilio;
import ballerina/log;

configurable string apiKey = ?;
configurable string apiSecret = ?;
configurable string accountSid = ?;

// SMS request record
type SmsRequest record {|
    string toNumber;
    string fromNumber;
    string messageBody;
|};

// SMS response record
type SmsResponse record {|
    boolean success;
    string message;
    string? messageSid?;
|};

service / on new http:Listener(8080) {
    
    isolated resource function post sendSms(SmsRequest smsRequest) returns SmsResponse|http:InternalServerError {
        
        // Initialize Twilio client with ApiKeyConfig
        twilio:ConnectionConfig twilioConfig = {
            auth: {
                apiKey: apiKey,
                apiSecret: apiSecret,
                accountSid: accountSid
            }
        };
        
        twilio:Client|error twilioClientResult = new (twilioConfig);
        if twilioClientResult is error {
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to initialize Twilio client: " + twilioClientResult.message()
                }
            };
        }

        twilio:Client twilioClient = twilioClientResult;
        
        // Create message request payload using request parameters
        twilio:CreateMessageRequest messageRequest = {
            To: smsRequest.toNumber,
            From: smsRequest.fromNumber,
            Body: smsRequest.messageBody
        };
        
        // Send SMS message
        twilio:Message|error smsResponse = twilioClient->createMessage(messageRequest);
        
        if smsResponse is error {
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to send SMS: " + smsResponse.message()
                }
            };
        }
        
        string? messageSid = smsResponse?.sid;
        string? messageStatus = smsResponse?.status;
        
        // Print the status of the message from the response
        if messageStatus is string {
            log:printInfo("Message Status: " + messageStatus);
        }
        
        return {
            success: true,
            message: "SMS sent successfully",
            messageSid: messageSid
        };
    }
}