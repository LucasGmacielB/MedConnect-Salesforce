@IsTest
public class EventListControllerTest {
  @TestSetup
  static void setup() {
    Location__c location = new Location__c(
      Name = 'Main Clinic',
      Street__c = 'Main Street',
      City__c = 'Recife',
      State__c = 'PE',
      Country__c = 'United States'
    );
    insert location;

    Clinic_Organizer__c organizer = new Clinic_Organizer__c(
      Name = 'Main Organizer',
      Email__c = 'organizer@example.com'
    );
    insert organizer;

    insert new List<Medical_Event__c>{
      new Medical_Event__c(
        Event_Name__c = 'Cardiology Summit',
        Start_Date_Time__c = System.now().addDays(2),
        End_Date_Time__c = System.now().addDays(3),
        Status__c = 'Published',
        Event_Type__c = 'In-Person',
        Live__c = true,
        Max_Seats__c = 50,
        Organizer__c = organizer.Id,
        Address__c = location.Id
      ),
      new Medical_Event__c(
        Event_Name__c = 'Virtual Oncology Talk',
        Start_Date_Time__c = System.now().addDays(4),
        End_Date_Time__c = System.now().addDays(5),
        Status__c = 'Published',
        Event_Type__c = 'Virtual',
        Live__c = true,
        Max_Seats__c = 100,
        Organizer__c = organizer.Id
      ),
      new Medical_Event__c(
        Event_Name__c = 'Inactive Event',
        Start_Date_Time__c = System.now().addDays(2),
        End_Date_Time__c = System.now().addDays(3),
        Status__c = 'Created',
        Event_Type__c = 'In-Person',
        Live__c = false,
        Max_Seats__c = 10,
        Organizer__c = organizer.Id,
        Address__c = location.Id
      ),
      new Medical_Event__c(
        Event_Name__c = 'Past Event',
        Start_Date_Time__c = System.now().addDays(-4),
        End_Date_Time__c = System.now().addDays(-3),
        Status__c = 'Completed',
        Event_Type__c = 'In-Person',
        Live__c = true,
        Max_Seats__c = 10,
        Organizer__c = organizer.Id,
        Address__c = location.Id
      )
    };
  }

  @IsTest
  static void shouldReturnOnlyLiveUpcomingEvents() {
    Test.startTest();
    List<EventListController.EventListItem> results = EventListController.getLiveUpcomingEvents(
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(2, results.size());
    System.assertEquals('Cardiology Summit', results[0].eventName);
  }

  @IsTest
  static void shouldFilterByNameAndLocation() {
    Test.startTest();
    List<EventListController.EventListItem> results = EventListController.getLiveUpcomingEvents(
      'Cardiology',
      null,
      'Recife'
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals('Main Clinic', results[0].locationName);
  }

  @IsTest
  static void shouldReturnVirtualLocationText() {
    Test.startTest();
    List<EventListController.EventListItem> results = EventListController.getLiveUpcomingEvents(
      'Virtual',
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals('Virtual Event', results[0].locationName);
  }
}
