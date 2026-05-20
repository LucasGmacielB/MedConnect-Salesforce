@RestResource(urlMapping='/medical-events/*')
global with sharing class MedicalEventRestService {

    global class MedicalEventResponse {
        public Id eventId;
        public String name;
        public Datetime startDateTime;
        public Datetime endDateTime;
        public String status;
        public String eventType;
        public String organizerName;
        public String locationName;
        public String address;

        public MedicalEventResponse(Medical_Event__c event) {
            this.eventId = event.Id;
            this.name = event.Event_Name__c;
            this.startDateTime = event.Start_Date_Time__c;
            this.endDateTime = event.End_Date_Time__c;
            this.status = event.Status__c;
            this.eventType = event.Event_Type__c;
            this.organizerName = event.Organizer__r.Name;
            this.locationName = event.Address__r != null ? event.Address__r.Name : null;
            
            if (event.Event_Type__c == 'Virtual') {
                this.address = 'Virtual Event';
            } else if (event.Address__r != null) {
                List<String> addressParts = new List<String>();
                if (String.isNotBlank(event.Address__r.Street__c)) addressParts.add(event.Address__r.Street__c);
                if (String.isNotBlank(event.Address__r.City__c)) addressParts.add(event.Address__r.City__c);
                if (String.isNotBlank(event.Address__r.State__c)) addressParts.add(event.Address__r.State__c);
                if (String.isNotBlank(event.Address__r.Country__c)) addressParts.add(event.Address__r.Country__c);
                this.address = String.join(addressParts, ', ');
            } else {
                this.address = 'No address provided';
            }
        }
    }

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String eventId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

        try {
            if (String.isNotBlank(eventId) && eventId != 'medical-events') {
                handleGetEventById(eventId, res);
            } else {
                handleGetAllEvents(res);
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'error' => Label.API_General_Error
            }));
            ErrorLogService.logError(System.now(), e.getMessage(), 'MedicalEventRestService');
        }
    }

    private static void handleGetAllEvents(RestResponse res) {
        List<Medical_Event__c> events = [
            SELECT Id, Event_Name__c, Start_Date_Time__c, End_Date_Time__c, 
                   Status__c, Event_Type__c, Organizer__r.Name, 
                   Address__r.Name, Address__r.Street__c, Address__r.City__c, 
                   Address__r.State__c, Address__r.Country__c
            FROM Medical_Event__c
            WHERE Live__c = true 
            AND Start_Date_Time__c > :System.now()
            WITH USER_MODE
            ORDER BY Start_Date_Time__c ASC
        ];

        List<MedicalEventResponse> responseList = new List<MedicalEventResponse>();
        for (Medical_Event__c event : events) {
            responseList.add(new MedicalEventResponse(event));
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(responseList));
    }

    private static void handleGetEventById(Id eventId, RestResponse res) {
        List<Medical_Event__c> events = [
            SELECT Id, Event_Name__c, Start_Date_Time__c, End_Date_Time__c, 
                   Status__c, Event_Type__c, Organizer__r.Name, 
                   Address__r.Name, Address__r.Street__c, Address__r.City__c, 
                   Address__r.State__c, Address__r.Country__c
            FROM Medical_Event__c
            WHERE Id = :eventId
            WITH USER_MODE
            LIMIT 1
        ];

        if (events.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'error' => Label.Event_Not_Found
            }));
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(new MedicalEventResponse(events[0])));
    }
}
