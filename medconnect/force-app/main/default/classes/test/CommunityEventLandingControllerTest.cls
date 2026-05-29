@IsTest
public class CommunityEventLandingControllerTest {
  @TestSetup
  static void setup() {
    Location__c location = new Location__c(
      Name = 'Centro Medico Recife',
      Street__c = 'Rua Principal',
      City__c = 'Recife',
      State__c = 'PE',
      Country__c = 'Brazil'
    );
    insert location;

    Clinic_Organizer__c organizer = new Clinic_Organizer__c(
      Name = 'MedConnect Eventos',
      Email__c = 'events@example.com'
    );
    insert organizer;

    insert new List<Medical_Event__c>{
      new Medical_Event__c(
        Event_Name__c = 'Congresso de Cardiologia',
        Start_Date_Time__c = System.now().addDays(2),
        End_Date_Time__c = System.now().addDays(3),
        Status__c = 'Published',
        Event_Type__c = 'In-Person',
        Live__c = true,
        Max_Seats__c = 150,
        Organizer__c = organizer.Id,
        Address__c = location.Id
      ),
      new Medical_Event__c(
        Event_Name__c = 'Painel Online de Oncologia',
        Start_Date_Time__c = System.now().addDays(4),
        End_Date_Time__c = System.now().addDays(5),
        Status__c = 'Published',
        Event_Type__c = 'Virtual',
        Live__c = true,
        Max_Seats__c = 200,
        Organizer__c = organizer.Id
      ),
      new Medical_Event__c(
        Event_Name__c = 'Evento Inativo',
        Start_Date_Time__c = System.now().addDays(5),
        End_Date_Time__c = System.now().addDays(6),
        Status__c = 'Created',
        Event_Type__c = 'In-Person',
        Live__c = false,
        Max_Seats__c = 50,
        Organizer__c = organizer.Id,
        Address__c = location.Id
      ),
      new Medical_Event__c(
        Event_Name__c = 'Evento Encerrado',
        Start_Date_Time__c = System.now().addDays(-3),
        End_Date_Time__c = System.now().addDays(-2),
        Status__c = 'Completed',
        Event_Type__c = 'In-Person',
        Live__c = true,
        Max_Seats__c = 50,
        Organizer__c = organizer.Id,
        Address__c = location.Id
      )
    };
  }

  @IsTest
  static void shouldReturnOnlyLiveUpcomingEvents() {
    Test.startTest();
    List<CommunityEventLandingController.EventCard> results = CommunityEventLandingController.getUpcomingEvents();
    Test.stopTest();

    System.assertEquals(2, results.size());
    System.assertEquals('Congresso de Cardiologia', results[0].eventName);
    System.assertEquals('In-Person', results[0].eventType);
    System.assertEquals('Published', results[0].status);
    System.assertEquals('Centro Medico Recife', results[0].locationName);
    System.assert(results[0].locationLabel.contains('Recife'));
    System.assertNotEquals(null, results[0].description);
  }

  @IsTest
  static void shouldFormatVirtualLocation() {
    Test.startTest();
    List<CommunityEventLandingController.EventCard> results = CommunityEventLandingController.getUpcomingEvents();
    Test.stopTest();

    System.assertEquals('Evento online', results[1].locationLabel);
  }
}
