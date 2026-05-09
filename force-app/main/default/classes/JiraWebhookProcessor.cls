public without sharing class JiraWebhookProcessor implements IWebhookProcessor {
    
    // Constants for webhook event types
    private static final String EVENT_ISSUE_CREATED = 'jira:issue_created';
    private static final String EVENT_ISSUE_UPDATED = 'jira:issue_updated';
    private static final String EVENT_ISSUE_DELETED = 'jira:issue_deleted';
    private static final String EVENT_PROJECT_CREATED = 'project_created';
    private static final String EVENT_PROJECT_UPDATED = 'project_updated';
    private static final String EVENT_PROJECT_DELETED = 'project_deleted';
    
    public Boolean validate(RestRequest request) {
        
        Boolean validated = false;

        String requestBody = request.requestBody.toString();
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        if (payload.containsKey('webhookEvent')) {
            validated = true;
        }
        return validated;
    }
    
    public void process(RestRequest request) {

        String requestBody = request.requestBody.toString();
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String webhookEvent = (String) payload.get('webhookEvent');


        if (webhookEvent == EVENT_ISSUE_CREATED) {
            processIssueCreated(payload);
        } else if (webhookEvent == EVENT_ISSUE_UPDATED) {
            processIssueUpdated(payload);
        } else if (webhookEvent == EVENT_ISSUE_DELETED) {
            processIssueDeleted(payload);
        } else if (webhookEvent == EVENT_PROJECT_CREATED) {
            processProjectCreated(payload);
        } else if (webhookEvent == EVENT_PROJECT_UPDATED) {
            processProjectUpdated(payload);
        } else if (webhookEvent == EVENT_PROJECT_DELETED) {
            processProjectDeleted(payload);   
        }
    }
    //***** JIRA ISSUE METHODS *****/

    private Id getExistingJiraIssueId(String issueKey) {

        Id jiraIssueId = null;
        List<Jira_Issue__c> jiraIssues = [SELECT Id FROM Jira_Issue__c WHERE Issue_Key__c = :issueKey LIMIT 1];
        if (!jiraIssues.isEmpty()) {
            jiraIssueId = jiraIssues.get(0).Id;
        }
        return jiraIssueId;
    }
    
    private Jira_Issue__c mapIssuePayloadToRecord(Map<String, Object> payload, Boolean isCreate) {

        // Extract the needed maps from the payload
        Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
        Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
        Map<String, Object> project = (Map<String, Object>) fields.get('project'); 
        Map<String, Object> status = (Map<String, Object>) fields.get('status'); 
        Map<String, Object> issueType = (Map<String, Object>) fields.get('issuetype'); 
        DateTime jiraTimeStampForSf = convertTimestampField(payload);

        // Map the fields that could apply for both a create and update. At a minimum, Last_Updated__c will always have changed
        Jira_Issue__c issue = new Jira_Issue__c(
            Name = (String)issueData.get('key'),
            Issue_Type__c = (String)issueType.get('name'),
            Project_Key__c = (String)project.get('key'),
            Status__c = (String)status.get('name'),      
            Description__c = (String)fields.get('description'),   
            Summary__c = (String)fields.get('summary'),
            Last_Updated__c = jiraTimeStampForSf
        );

        // Extract the Jira Key and map this and the Id for a create. For an update, try to find the existing SF Id with that Jira Key.
        String issueKey = (String)issueData.get('key');
        if (isCreate) {
            issue.Issue_Id__c = (String)issueData.get('id');
            issue.Issue_Key__c = issueKey;
        } else {
            issue.Id = getExistingJiraIssueId(issueKey);
        }
        return issue;
    }
    
    private void processIssueCreated(Map<String, Object> payload) {

        Jira_Issue__c issue = mapIssuePayloadToRecord(payload, true);
        insert issue;
    }  
    
    private void processIssueUpdated(Map<String, Object> payload) {

        Jira_Issue__c issue = mapIssuePayloadToRecord(payload, false);
        upsert issue;
    }
    
    private void processIssueDeleted(Map<String, Object> payload) {
        
        Map<String, Object> issueData = (Map<String, Object>)payload.get('issue');
        String key = (String)issueData.get('key');
        Jira_Issue__c issue = [SELECT Id FROM Jira_Issue__c WHERE Issue_Key__c = :key];
        delete issue;
    }

        //***** JIRA PROJECT METHODS *****/

    private Id getExistingJiraProjectId(String projectKey) {

        Id jiraProjectId = null;
        List<Jira_Project__c> jiraProjects = [SELECT Id FROM Jira_Project__c WHERE Project_Key__c = :projectKey LIMIT 1];
        if (!jiraProjects.isEmpty()) {
            jiraProjectId = jiraProjects.get(0).Id;
        }
        return jiraProjectId;
    }
    
    private Jira_Project__c mapProjectPayloadToRecord(Map<String, Object> payload, Boolean isCreate) {

        // Extract the needed values and maps from the payload
        DateTime jiraTimeStampForSf = convertTimestampField(payload);
        Map<String, Object> projectData = (Map<String, Object>) payload.get('project');

        // Map the fields that could apply for both a create and update. At a minimum, Last_Updated__c will always have changed
        Jira_Project__c project = new Jira_Project__c(
            Name = (String)projectData.get('name'),
            Project_Name__c = (String)projectData.get('name'),
            Description__c = (String)projectData.get('self'),
            Last_Updated__c = jiraTimeStampForSf
        );

        // Extract the Jira Key and map this and the Id for a create. For an update, try to find the existing SF Id with that Jira Key.
        String projectKey = (String)projectData.get('key');
        if (isCreate) {
            project.Project_Id__c = String.valueOf(projectData.get('id'));
            project.Project_Key__c = projectKey;
            project.Created_Date__c = jiraTimeStampForSf;
        } else {
            project.Id = getExistingJiraProjectId(projectKey);
        }
        return project;
    }
    
    private void processProjectCreated(Map<String, Object> payload) {

        Jira_Project__c project = mapProjectPayloadToRecord(payload, true);
        insert project;
    }
    
    private void processProjectUpdated(Map<String, Object> payload) {

        Jira_Project__c project = mapProjectPayloadToRecord(payload, false);
        upsert project;
    }
    
    private void processProjectDeleted(Map<String, Object> payload) {

        Map<String, Object> projectData = (Map<String, Object>)payload.get('project');
        String key = (String)projectData.get('key');
        Jira_Project__c project = [SELECT Id FROM Jira_Project__c WHERE Project_Key__c = :key];
        delete project;
    }

    private DateTime convertTimestampField(Map<String, Object> payload) {

        Long jiraTimestamp = (Long)payload.get('timestamp');
        DateTime jiraTimeStampForSf = DateTime.newInstance(jiraTimestamp / 1000);
        return jiraTimeStampForSf;
    }
} 