/**
 * @description Test class for WebhookResource
 * @author Stephen Church
 */
@IsTest
private class WebhookResourceTest {
    
    public static DateTime expectedDateTime = DateTime.newInstance(1777378719654L / 1000);

    /**
     * @description Test method for Jira issue created webhook
     */
    @IsTest
    static void testJiraIssueCreatedWebhook() {
        // Create test request
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        // Create a sample Jira issue created payload
        String requestBody = '{' +
            '"timestamp": 1777378719654,' +
            '"webhookEvent": "jira:issue_created",' +
            '"issue": {' +
                '"id": "10000",' +
                '"key": "TEST-123",' +
                '"fields": {' +
                    '"summary": "Test issue",' +
                    '"description": "This is a test issue",' +
                    '"issuetype": {' +
                        '"name": "Bug"' +
                    '},' +
                    '"status": {' +
                        '"name": "Open"' +
                    '},' +
                    '"project": {' +
                        '"key": "TEST"' +
                    '}' +
                '}' +
            '}' +
        '}';

        req.requestBody = Blob.valueOf(requestBody);
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('success', response.status, 'Response status should be success');
        
        // Verify that the Jira issue record was created
        List<Jira_Issue__c> issues = [
            SELECT Id, Name, Issue_Type__c, Project_Key__c, Status__c, Description__c, Summary__c, Last_Updated__c, Issue_Id__c, Issue_Key__c
            FROM Jira_Issue__c
            WHERE Issue_Key__c = 'TEST-123'
        ];

        Assert.areEqual(1, issues.size(), 'One Jira issue record should be created');
        Assert.areEqual('TEST-123', issues[0].Name, 'Name should match the Issue Key');
        Assert.areEqual('Bug', issues[0].Issue_Type__c, 'Issue type should match');
        Assert.areEqual('TEST', issues[0].Project_Key__c, 'Project key should match');
        Assert.areEqual('Open', issues[0].Status__c, 'Status should match');
        Assert.areEqual('This is a test issue', issues[0].Description__c, 'Description should match');
        Assert.areEqual('Test issue', issues[0].Summary__c, 'Summary should match');
        Assert.areEqual(expectedDateTime, issues[0].Last_Updated__c, 'Last Updated should match');
        Assert.areEqual('10000', issues[0].Issue_Id__c, 'Issue Id should match');
        Assert.areEqual('TEST-123', issues[0].Issue_Key__c, 'Issue key should match');
    }
    
    /**
     * @description Test method for Jira issue updated webhook
     */
    @IsTest
    static void testJiraIssueUpdatedWebhook() {
        // Create a test issue record
        Jira_Issue__c testIssue = new Jira_Issue__c(
            Name = 'TEST-123',
            Issue_Type__c = 'Task',
            Project_Key__c = 'TEST',
            Status__c = 'To Do',
            Description__c = 'Initial Description',
            Summary__c = 'Initial Summary',
            Last_Updated__c = Datetime.now(),
            Issue_Key__c = 'TEST-123',
            Issue_Id__c = '10000'
        );
        
        insert testIssue;
        
        // Create test request
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        // Create a sample Jira issue updated payload
        String requestBody = '{' +
            '"timestamp": 1777378719654,' +    
            '"webhookEvent": "jira:issue_updated",' +
            '"issue": {' +
                '"id": "10000",' +
                '"key": "TEST-123",' +
                '"fields": {' +
                    '"summary": "Updated Summary",' +
                    '"description": "Updated Description",' +
                    '"issuetype": {' +
                        '"name": "Bug"' +
                    '},' +
                    '"status": {' +
                        '"name": "In Progress"' +
                    '},' +
                    '"project": {' +
                        '"key": "TEST"' +
                    '}' +
                '}' +
            '}' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('success', response.status, 'Response status should be success');
        
        // Verify that the Jira issue record was updated
        List<Jira_Issue__c> issues = [
            SELECT Id, Name, Issue_Type__c, Project_Key__c, Status__c, Description__c, Summary__c, Last_Updated__c, Issue_Id__c, Issue_Key__c
            FROM Jira_Issue__c
            WHERE Issue_Key__c = 'TEST-123'
        ];
        
        Assert.areEqual(1, issues.size(), 'One Jira issue record should exist');
        Assert.areEqual('TEST-123', issues[0].Name, 'Name should match the Issue Key');
        Assert.areEqual('Bug', issues[0].Issue_Type__c, 'Issue type should be updated');
        Assert.areEqual('TEST', issues[0].Project_Key__c, 'Project key should match');
        Assert.areEqual('In Progress', issues[0].Status__c, 'Status should be updated');
        Assert.areEqual('Updated Description', issues[0].Description__c, 'Description should be updated');
        Assert.areEqual('Updated Summary', issues[0].Summary__c, 'Summary should be updated');
        Assert.areEqual(expectedDateTime, issues[0].Last_Updated__c, 'Last Updated should match');
        Assert.areEqual('10000', issues[0].Issue_Id__c, 'Issue Id should match');
        Assert.areEqual('TEST-123', issues[0].Issue_Key__c, 'Issue key should match');
    }
    
    /**
     * @description Test method for Jira issue deleted webhook
     */
    @IsTest
    static void testJiraIssueDeletedWebhook() {
        // Create a test issue record
        Jira_Issue__c testIssue = new Jira_Issue__c(
            Issue_Key__c = 'TEST-123',
            Summary__c = 'Test Summary',
            Description__c = 'Test Description',
            Issue_Type__c = 'Task',
            Status__c = 'To Do',
            Project_Key__c = 'TEST',
            Last_Updated__c = Datetime.now()
        );
        
        insert testIssue;
        
        // Create test request
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        // Create a sample Jira issue deleted payload
        String requestBody = '{' +
            '"webhookEvent": "jira:issue_deleted",' +
            '"issue": {' +
                '"key": "TEST-123"' +
            '}' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('success', response.status, 'Response status should be success');
        
        // Verify that the Jira issue record was deleted
        List<Jira_Issue__c> issues = [
            SELECT Id
            FROM Jira_Issue__c
            WHERE Issue_Key__c = 'TEST-123'
        ];
        
        Assert.areEqual(0, issues.size(), 'The Jira issue record should be deleted');
    }
    
    /**
     * @description Test method for Jira project created webhook
     */
    @IsTest
    static void testJiraProjectCreatedWebhook() {
        // Create test request
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        // Create a sample Jira project created payload
        String requestBody = '{' +
            '"timestamp": 1777378719654,' +
            '"webhookEvent": "project_created",' +
            '"project": {' +
                '"key": "TEST",' +
                '"id": 10000,' +
                '"name": "Test Project",' +
                '"self": "https://stephennicolaschurch.atlassian.net/rest/api/2/project/10000"' +
            '}' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('success', response.status, 'Response status should be success');
        
        // Verify that the Jira project record was created
        List<Jira_Project__c> projects = [
            SELECT Id, Project_Key__c, Project_ID__c, Project_Name__c, Description__c, Last_Updated__c, Name, Created_Date__c
            FROM Jira_Project__c
            WHERE Project_Key__c = 'TEST'
        ];

        Assert.areEqual(1, projects.size(), 'One Jira project record should be created');
        Assert.areEqual('Test Project', projects[0].Name, 'Name should match the project name');
        Assert.areEqual('Test Project', projects[0].Project_Name__c, 'Project name should match');
        Assert.areEqual('https://stephennicolaschurch.atlassian.net/rest/api/2/project/10000', projects[0].Description__c, 'Project description should match');
        Assert.areEqual(expectedDateTime, projects[0].Last_Updated__c, 'Project Last Updated should match');
        Assert.areEqual('10000', projects[0].Project_ID__c, 'Project ID should match');
        Assert.areEqual('TEST', projects[0].Project_Key__c, 'Project key should match');
        Assert.areEqual(expectedDateTime, projects[0].Created_Date__c, 'Project Created Date should match');
    }

    @IsTest
    static void testJiraProjectUpdatedWebhook() {
        // Create a test project record
        DateTime insertedDateTime = DateTime.now();
        
        Jira_Project__c testProject = new Jira_Project__c(
            Name = 'TEST',
            Project_Name__c = 'TEST',
            Description__c = 'Initial Description', 
            Last_Updated__c = insertedDateTime,     
            Project_Id__c = '10000',
            Project_Key__c = 'TEST',
            Created_Date__c = insertedDateTime     
        );
        
        insert testProject;
        
        // Create test request
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        // Create a sample Jira issue updated payload
        String requestBody = '{' +
            '"timestamp": 1777378719654,' +    
            '"webhookEvent": "project_updated",' +
            '"project": {' +
                '"id": 10000,' +
                '"key": "TEST",' +
                '"name": "TEST UPDATE",' +
                '"self": "https://stephennicolaschurch.atlassian.net/rest/api/2/project/10000"' +
            '}' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('success', response.status, 'Response status should be success');
        
        // Verify that the Jira issue record was updated
        List<Jira_Project__c> projects = [
            SELECT Id, Name, Project_Name__c, Description__c, Last_Updated__c, Project_Id__c, Project_Key__c, Created_Date__c
            FROM Jira_Project__c
            WHERE Project_Key__c = 'TEST'
        ];
        
        Assert.areEqual(1, projects.size(), 'One Jira project record should exist');
        Assert.areEqual('TEST UPDATE', projects[0].Name, 'Name should be updated to match the Project');
        Assert.areEqual('TEST UPDATE', projects[0].Project_Name__c, 'Project Name should be updated to match the Project');
        Assert.areEqual('https://stephennicolaschurch.atlassian.net/rest/api/2/project/10000', projects[0].Description__c, 'Description should match the Project');
        Assert.areEqual(expectedDateTime, projects[0].Last_Updated__c, 'Last Updated should match');
        Assert.areEqual('10000', projects[0].Project_Id__c, 'Project Id should match');
        Assert.areEqual('TEST', projects[0].Project_Key__c, 'Project key should match');
        Assert.areEqual(insertedDateTime, projects[0].Created_Date__c, 'CreatedDate should match the inserted date / time');
    }

    @IsTest
    static void testJiraProjectDeletedWebhook() {

        DateTime insertedDateTime = DateTime.now();

        Jira_Project__c testProject = new Jira_Project__c(
            Name = 'TEST',
            Project_Name__c = 'TEST',
            Description__c = 'Initial Description', 
            Last_Updated__c = insertedDateTime,     
            Project_Id__c = '10000',
            Project_Key__c = 'TEST',
            Created_Date__c = insertedDateTime     
        );
        
        insert testProject;
        
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        String requestBody = '{' +
            '"webhookEvent": "project_deleted",' +
            '"project": {' +
                '"key": "TEST"' +
            '}' +
        '}';
        
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        Assert.areEqual('success', response.status, 'Response status should be success');
        
        List<Jira_Project__c> project = [
            SELECT Id
            FROM Jira_Project__c
            WHERE Project_Key__c = 'TEST'
        ];
        
        Assert.areEqual(0, project.size(), 'The Jira project record should be deleted');
    }
    
    /**
     * @description Test method for invalid webhook type
     */
    @IsTest
    static void testInvalidWebhookType() {
        // Create test request
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/invalid';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"test": "data"}');
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('error', response.status, 'Response status should be error');
        Assert.isTrue(response.message.contains('Unsupported webhook type'), 'Error message should indicate unsupported webhook type');
    }
    
    /**
     * @description Test method for invalid JSON payload
     */
    @IsTest
    static void testInvalidJsonPayload() {
        // Create test request with invalid JSON
        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"invalid JSON');
        
        // Set the request and response
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call the REST resource
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        // Assert the response
        Assert.areEqual('error', response.status, 'Response status should be error');
    }

    @IsTest
    static void testNotValidated() {

        RestRequest req = new RestRequest();
        req.requestURI = '/webhook/jira';
        req.httpMethod = 'POST';
        
        // Create a sample Jira issue created payload with no webhookEvent
        String requestBody = '{' +
            '"timestamp": 1777378719654,' +
            '"issue": {' +
                '"id": "10000",' +
                '"key": "TEST-123",' +
                '"fields": {' +
                    '"summary": "Test issue",' +
                    '"description": "This is a test issue",' +
                    '"issuetype": {' +
                        '"name": "Bug"' +
                    '},' +
                    '"status": {' +
                        '"name": "Open"' +
                    '},' +
                    '"project": {' +
                        '"key": "TEST"' +
                    '}' +
                '}' +
            '}' +
        '}';

        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        WebhookResource.ResponseWrapper response = WebhookResource.doPost();
        Test.stopTest();
        
        Assert.areEqual('error', response.status, 'Response status should be success');
        Assert.isTrue(response.message.startsWith('Webhook validation failed for type:'));
    }

    @IsTest
    static void testWebhookPathNullReturn() {

        Test.startTest();
        String result = WebhookResource.getWebhookTypeFromPath(null);
        Test.stopTest();
        
        Assert.areEqual('', result, 'Null path should return empty string');
    }

    @IsTest
    static void testWebhookPathDoesNotContainWebhookReturn () {

        Test.startTest();
        String result = WebhookResource.getWebhookTypeFromPath('/services/apexrest/test');
        Test.stopTest();
        
        Assert.areEqual('', result, 'Path without /webhook/ should return empty string');
    }

    @IsTest
    static void testWebhookPathNextSlashGreaterThan0Return() {
        
        Test.startTest();
        String result = WebhookResource.getWebhookTypeFromPath('/services/apexrest/webhook/jira/test');
        Test.stopTest();
        
        Assert.areEqual('jira', result, 'Should extract "jira" when additional path exists');
    }
} 