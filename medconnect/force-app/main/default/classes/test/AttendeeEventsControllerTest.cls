@IsTest
public class AttendeeEventsControllerTest {
  @TestSetup
  static void setup() {
    Location__c location = new Location__c(
      Name = 'Training Center',
      Street__c = 'Training Street',
      City__c = 'Recife',
      State__c = 'PE',
      Country__c = 'United States'
    );
    insert location;

    Clinic_Organizer__c organizer = new Clinic_Organizer__c(
      Name = 'Organizer',
      Email__c = 'organizer@example.com'
    );
    insert organizer;

    Attendee__c attendee = new Attendee__c(
      Name = 'Attendee',
      Email__c = 'attendee@example.com'
    );
    insert attendee;

    Medical_Event__c upcomingEvent = new Medical_Event__c(
      Event_Name__c = 'Upcoming Event',
      Start_Date_Time__c = System.now().addDays(2),
      End_Date_Time__c = System.now().addDays(3),
      Status__c = 'Published',
      Event_Type__c = 'In-Person',
      Live__c = true,
      Max_Seats__c = 20,
      Organizer__c = organizer.Id,
      Address__c = location.Id
    );
    insert upcomingEvent;

    Medical_Event__c eventToBecomePast = new Medical_Event__c(
      Event_Name__c = 'Past Event',
      Start_Date_Time__c = System.now().addDays(5),
      End_Date_Time__c = System.now().addDays(6),
      Status__c = 'Published',
      Event_Type__c = 'In-Person',
      Live__c = true,
      Max_Seats__c = 20,
      Organizer__c = organizer.Id,
      Address__c = location.Id
    );
    insert eventToBecomePast;

    insert new List<Event_Attendee__c>{
      new Event_Attendee__c(
        Medical_Event__c = upcomingEvent.Id,
        Attendee__c = attendee.Id
      ),
      new Event_Attendee__c(
        Medical_Event__c = eventToBecomePast.Id,
        Attendee__c = attendee.Id
      )
    };

    eventToBecomePast.Start_Date_Time__c = System.now().addDays(-4);
    eventToBecomePast.End_Date_Time__c = System.now().addDays(-3);
    eventToBecomePast.Status__c = 'Completed';
    update eventToBecomePast;
  }

  @IsTest
  static void shouldSplitUpcomingAndPastEvents() {
    Attendee__c attendee = [SELECT Id FROM Attendee__c LIMIT 1];

    Test.startTest();
    AttendeeEventsController.AttendeeEventsResponse response = AttendeeEventsController.getEventsByAttendee(
      attendee.Id
    );
    Test.stopTest();

    System.assertEquals(1, response.upcomingEvents.size());
    System.assertEquals(1, response.pastEvents.size());
    System.assertEquals('Upcoming Event', response.upcomingEvents[0].eventName);
    System.assertEquals('Past Event', response.pastEvents[0].eventName);
  }

  @IsTest
  static void shouldRejectMissingAttendeeId() {
    Boolean exceptionThrown = false;

    try {
      AttendeeEventsController.getEventsByAttendee(null);
    } catch (AuraHandledException e) {
      exceptionThrown = true;
    }

    System.assertEquals(true, exceptionThrown);
  }
}
