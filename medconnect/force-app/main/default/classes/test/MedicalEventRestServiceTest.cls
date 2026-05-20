@IsTest
public class MedicalEventRestServiceTest {

    @TestSetup
    static void setup() {
        Location__c loc = new Location__c(
            Name = 'Test Location',
            Street__c = 'Street 1',
            City__c = 'City',
            State__c = 'State',
            Country__c = 'Brazil'
        );
        insert loc;

        Clinic_Organizer__c org = new Clinic_Organizer__c(
            Name = 'Test Organizer',
            Email__c = 'test@org.com'
        );
        insert org;

        Medical_Event__c eventLive = new Medical_Event__c(
            Event_Name__c = 'Live Event',
            Live__c = true,
            Start_Date_Time__c = System.now().addDays(1),
            End_Date_Time__c = System.now().addDays(2),
            Address__c = loc.Id,
            Organizer__c = org.Id,
            Status__c = 'Published'
        );
        insert eventLive;

        Medical_Event__c eventPast = new Medical_Event__c(
            Event_Name__c = 'Past Event',
            Live__c = true,
            Start_Date_Time__c = System.now().addDays(-2),
            End_Date_Time__c = System.now().addDays(-1),
            Address__c = loc.Id,
            Organizer__c = org.Id,
            Status__c = 'Completed'
        );
        insert eventPast;

        Medical_Event__c eventNotLive = new Medical_Event__c(
            Event_Name__c = 'Not Live Event',
            Live__c = false,
            Start_Date_Time__c = System.now().addDays(1),
            End_Date_Time__c = System.now().addDays(2),
            Address__c = loc.Id,
            Organizer__c = org.Id,
            Status__c = 'Created'
        );
        insert eventNotLive;
    }

    @IsTest
    static void testGetAllEvents() {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/medical-events/';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        MedicalEventRestService.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<MedicalEventRestService.MedicalEventResponse> response = 
            (List<MedicalEventRestService.MedicalEventResponse>) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                List<MedicalEventRestService.MedicalEventResponse>.class
            );
        
        System.assertEquals(1, response.size(), 'Deve retornar apenas 1 evento (Live e Futuro)');
        System.assertEquals('Live Event', response[0].name);
    }

    @IsTest
    static void testGetEventById() {
        Medical_Event__c event = [SELECT Id FROM Medical_Event__c WHERE Event_Name__c = 'Live Event' LIMIT 1];
        
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/medical-events/' + event.Id;
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        MedicalEventRestService.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        MedicalEventRestService.MedicalEventResponse response = 
            (MedicalEventRestService.MedicalEventResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                MedicalEventRestService.MedicalEventResponse.class
            );
        
        System.assertEquals('Live Event', response.name);
    }

    @IsTest
    static void testGetEventNotFound() {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/medical-events/a00000000000000AAA';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        MedicalEventRestService.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }
}
