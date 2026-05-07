@IsTest
public class MedicalEventPurgeBatchTest {

    @TestSetup
    static void setupData() {
        Location__c location = new Location__c(
            Name = 'Clinic Test',
            Street__c = 'Rua Teste',
            City__c = 'Recife',
            State__c = 'PE',
            Postal_Code__c = '50000000',
            Country__c = 'Brazil',
            Verified__c = true
        );
        insert location;

        Clinic_Organizer__c organizer = new Clinic_Organizer__c(
            Name = 'Organizer Test',
            Email__c = 'organizer@test.com',
            Phone__c = '81999990000',
            Location__c = location.Id
        );
        insert organizer;

        List<Medical_Event__c> oldEvents = new List<Medical_Event__c>();

        for (Integer i = 0; i < 199; i++) {
            oldEvents.add(new Medical_Event__c(
                Event_Name__c = 'Old Event ' + i,
                Status__c = 'Completed',
                Organizer__c = organizer.Id,
                Start_Date_Time__c = System.now().addMonths(-4),
                End_Date_Time__c = System.now().addMonths(-3),
                Max_Seats__c = 10,
                Address__c = location.Id,
                Live__c = false,
                Recurring__c = false,
                Event_Type__c = 'In-Person'
            ));
        }

        insert oldEvents;

        Medical_Event__c futureEvent = new Medical_Event__c(
            Event_Name__c = 'Future Event',
            Status__c = 'Published',
            Organizer__c = organizer.Id,
            Start_Date_Time__c = System.now().addDays(5),
            End_Date_Time__c = System.now().addDays(6),
            Max_Seats__c = 10,
            Address__c = location.Id,
            Live__c = true,
            Recurring__c = false,
            Event_Type__c = 'In-Person'
        );

        insert futureEvent;
    }

    @IsTest
    static void shouldDeleteOldCompletedEvents() {
        Integer beforeCount = [
            SELECT COUNT()
            FROM Medical_Event__c
            WHERE Live__c = false
        ];

        System.assertEquals(199, beforeCount);

        Test.startTest();

        Database.executeBatch(new MedicalEventPurgeBatch(), 200);

        Test.stopTest();

        Integer afterOldCount = [
            SELECT COUNT()
            FROM Medical_Event__c
            WHERE Live__c = false
        ];

        Integer futureEventCount = [
            SELECT COUNT()
            FROM Medical_Event__c
            WHERE Event_Name__c = 'Future Event'
        ];

        System.assertEquals(0, afterOldCount, 'Os eventos antigos deveriam ser deletados.');
        System.assertEquals(1, futureEventCount, 'O evento futuro não deveria ser deletado.');
    }
}