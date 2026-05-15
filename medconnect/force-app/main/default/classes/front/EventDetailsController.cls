public with sharing class EventDetailsController {

    public class EventDetailsWrapper {

        @AuraEnabled
        public List<Speaker__c> speakers;

        @AuraEnabled
        public List<Attendee__c> attendees;

        @AuraEnabled
        public Location__c location;
    }

    @AuraEnabled(cacheable=true)
    public static EventDetailsWrapper getEventRelatedDetails(Id eventId) {

        EventDetailsWrapper result = new EventDetailsWrapper();

        Medical_Event__c eventRecord = [
            SELECT Id, Address__c
            FROM Medical_Event__c
            WHERE Id = :eventId
            LIMIT 1
        ];

        if(eventRecord.Address__c != null){

            result.location = [
                SELECT
                    Id,
                    Name,
                    Street__c,
                    City__c,
                    State__c,
                    Postal_Code__c,
                    Country__c,
                    Landmark__c,
                    Verified__c
                FROM Location__c
                WHERE Id = :eventRecord.Address__c
                LIMIT 1
            ];
        }

        result.speakers = new List<Speaker__c>();

        for(Event_Speaker__c es : [

            SELECT
                Speaker__r.Id,
                Speaker__r.Name,
                Speaker__r.Email__c,
                Speaker__r.Phone__c,
                Speaker__r.Specialization__c

            FROM Event_Speaker__c
            WHERE Medical_Event__c = :eventId
        ]){

            result.speakers.add(es.Speaker__r);
        }

        result.attendees = new List<Attendee__c>();

        for(Event_Attendee__c ea : [

            SELECT
                Attendee__r.Id,
                Attendee__r.Name,
                Attendee__r.Email__c,
                Attendee__r.Phone__c,
                Attendee__r.Company_Institution_Name__c

            FROM Event_Attendee__c
            WHERE Medical_Event__c = :eventId
        ]){

            result.attendees.add(ea.Attendee__r);
        }

        return result;
    }
}