@RestResource(urlMapping='/webhook/*')
global without sharing class WebhookResource {
    
    @HttpPost
    global static ResponseWrapper doPost() {

        ResponseWrapper response = new ResponseWrapper(null, null);

        try {
            RestRequest req = RestContext.request; 
            String webhookType = getWebhookTypeFromPath(req.requestURI);
            WebhookFactory.processWebhook(webhookType, req);  
            response.status = 'success';      
            Logger.info('Request processed');
            Logger.saveLog();    
        } catch (Exception e) {
            response.status = 'error';
            response.message = e.getMessage();
            Logger.error(e.getMessage());
            Logger.saveLog();
        }
        return response;
    }
    
    // Expected formats: /webhook/jira or /services/apexrest/webhook/jira
    @TestVisible
    private static String getWebhookTypeFromPath(String path) {

        if (path == null) {
            return '';
        }
        
        Integer webhookIndex = path.indexOf('/webhook/');
        
        if (webhookIndex >= 0) {
            String remaining = path.substring(webhookIndex + 9);
            
            Integer nextSlash = remaining.indexOf('/');
            if (nextSlash > 0) {
                return remaining.substring(0, nextSlash).toLowerCase();
            }
            return remaining.toLowerCase();
        }
        
        return '';
    }
    
    global class ResponseWrapper {
        public String status;
        public String message;
        
        public ResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }
} 