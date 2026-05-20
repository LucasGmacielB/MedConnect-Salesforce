@IsTest
public class EventDetailsControllerTest {

    @TestSetup
    static void setup() {
        Location__c loc = new Location__c(
            Name = 'Test Loc',
            Street__c = 'Street',
            City__c = 'City',
            State__c = 'State',
            Country__c = 'Brazil'
        );
        insert loc;

        Clinic_Organizer__c org = new Clinic_Organizer__c(
            Name = 'Test Org',
            Email__c = 'org@test.com'
        );
        insert org;

        Medical_Event__c event = new Medical_Event__c(
            Event_Name__c = 'Test Event',
            Start_Date_Time__c = System.now().addDays(1),
            End_Date_Time__c = System.now().addDays(2),
            Address__c = loc.Id,
            Organizer__c = org.Id,
            Status__c = 'Published',
            Live__c = true,
            Max_Seats__c = 100
        );
        insert event;

        Attendee__c att = new Attendee__c(
            Name = 'Test Att',
            Email__c = 'att@test.com'
        );
        insert att;

        Event_Attendee__c ea = new Event_Attendee__c(
            Medical_Event__c = event.Id,
            Attendee__c = att.Id
        );
        insert ea;

        Speaker__c spk = new Speaker__c(
            Name = 'Test Spk',
            Email__c = 'spk@test.com'
        );
        insert spk;

        Event_Speaker__c es = new Event_Speaker__c(
            Medical_Event__c = event.Id,
            Speaker__c = spk.Id
        );
        insert es;
    }

    @IsTest
    static void testGetEventRelatedDetails() {
        Medical_Event__c event = [SELECT Id FROM Medical_Event__c LIMIT 1];

        Test.startTest();
        EventDetailsController.EventDetailsWrapper result = EventDetailsController.getEventRelatedDetails(event.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.location);
        System.assertEquals(1, result.speakers.size());
        System.assertEquals(1, result.attendees.size());
    }
}
