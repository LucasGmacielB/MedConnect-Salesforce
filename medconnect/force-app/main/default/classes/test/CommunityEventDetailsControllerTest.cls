@IsTest
public class CommunityEventDetailsControllerTest {
  @TestSetup
  static void setup() {
    Location__c location = new Location__c(
      Name = 'Centro Medico Recife',
      Street__c = 'Rua Principal',
      City__c = 'Recife',
      State__c = 'PE',
      Postal_Code__c = '50000000',
      Country__c = 'Brazil',
      Verified__c = true
    );
    insert location;

    Clinic_Organizer__c organizer = new Clinic_Organizer__c(
      Name = 'MedConnect Eventos',
      Email__c = 'events@example.com'
    );
    insert organizer;

    Medical_Event__c event = new Medical_Event__c(
      Event_Name__c = 'Congresso de Cardiologia',
      Start_Date_Time__c = System.now().addDays(2),
      End_Date_Time__c = System.now().addDays(3),
      Status__c = 'Published',
      Event_Type__c = 'In-Person',
      Live__c = true,
      Max_Seats__c = 150,
      Organizer__c = organizer.Id,
      Address__c = location.Id
    );
    insert event;

    Speaker__c speaker = new Speaker__c(
      Name = 'Dra Ana Lima',
      Email__c = 'ana@example.com',
      Specialization__c = 'Cardiologia',
      Profile_URL__c = 'https://example.com/ana',
      About_Me__c = 'Pesquisadora em cardiologia clinica.'
    );
    insert speaker;

    insert new Event_Speaker__c(Medical_Event__c = event.Id, Speaker__c = speaker.Id);
  }

  @IsTest
  static void shouldReturnValidEventDetails() {
    Medical_Event__c event = [
      SELECT Id
      FROM Medical_Event__c
      WHERE Event_Name__c = 'Congresso de Cardiologia'
      LIMIT 1
    ];

    Test.startTest();
    CommunityEventDetailsController.EventDetails result = CommunityEventDetailsController.getEventDetails(
      event.Id
    );
    Test.stopTest();

    System.assertEquals(event.Id, result.eventId);
    System.assertEquals('Congresso de Cardiologia', result.eventName);
    System.assertEquals('Published', result.status);
    System.assertEquals('In-Person', result.eventType);
    System.assertEquals(150, result.maxSeats);
    System.assertEquals('MedConnect Eventos', result.organizerName);
    System.assertEquals('Centro Medico Recife', result.locationName);
    System.assert(result.addressText.contains('Recife'));
    System.assertEquals(true, result.locationVerified);
  }

  @IsTest
  static void shouldReturnSpeakers() {
    Medical_Event__c event = [SELECT Id FROM Medical_Event__c LIMIT 1];

    Test.startTest();
    CommunityEventDetailsController.EventDetails result = CommunityEventDetailsController.getEventDetails(
      event.Id
    );
    Test.stopTest();

    System.assertEquals(1, result.speakers.size());
    System.assertEquals('Dra Ana Lima', result.speakers[0].name);
    System.assertEquals('Cardiologia', result.speakers[0].specialization);
    System.assertEquals('https://example.com/ana', result.speakers[0].profileUrl);
    System.assert(result.speakers[0].aboutMe.contains('cardiologia'));
  }

  @IsTest
  static void shouldThrowForMissingEvent() {
    Medical_Event__c event = [SELECT Id FROM Medical_Event__c LIMIT 1];
    delete [SELECT Id FROM Event_Speaker__c WHERE Medical_Event__c = :event.Id];
    delete event;

    Boolean wasThrown = false;

    Test.startTest();
    try {
      CommunityEventDetailsController.getEventDetails(event.Id);
    } catch (AuraHandledException e) {
      wasThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, wasThrown);
  }
}
