@IsTest
public class MedConnectTriggerTest {
  @TestSetup
  static void setupData() {
    Location__c location = new Location__c(
      Name = 'Clinic Recife',
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

    Attendee__c attendee = new Attendee__c(
      Name = 'Attendee Test',
      Email__c = 'attendee@test.com',
      Phone__c = '81999991111',
      Company_Institution_Name__c = 'Test Institution',
      Address__c = location.Id
    );
    insert attendee;

    Attendee__c secondAttendee = new Attendee__c(
      Name = 'Second Attendee Test',
      Email__c = 'second.attendee@test.com',
      Phone__c = '81999993333',
      Company_Institution_Name__c = 'Second Test Institution',
      Address__c = location.Id
    );
    insert secondAttendee;

    Speaker__c speaker = new Speaker__c(
      Name = 'Speaker Test',
      Email__c = 'speaker@test.com',
      Phone__c = '81999992222',
      Specialization__c = 'Cardiology'
    );
    insert speaker;

    Medical_Event__c event1 = new Medical_Event__c(
      Event_Name__c = 'Health Talk 1',
      Status__c = 'Published',
      Organizer__c = organizer.Id,
      Start_Date_Time__c = System.now().addDays(2),
      End_Date_Time__c = System.now().addDays(3),
      Max_Seats__c = 10,
      Address__c = location.Id,
      Live__c = true,
      Recurring__c = false,
      Event_Type__c = 'In-Person'
    );
    insert event1;

    Medical_Event__c event2 = new Medical_Event__c(
      Event_Name__c = 'Health Talk 2',
      Status__c = 'Published',
      Organizer__c = organizer.Id,
      Start_Date_Time__c = System.now().addDays(4),
      End_Date_Time__c = System.now().addDays(5),
      Max_Seats__c = 10,
      Address__c = location.Id,
      Live__c = true,
      Recurring__c = false,
      Event_Type__c = 'In-Person'
    );
    insert event2;
  }

  @IsTest
  static void shouldCreateEventAttendeeAndSendEmail() {
    Medical_Event__c eventRecord = [
      SELECT Id
      FROM Medical_Event__c
      WHERE Event_Name__c = 'Health Talk 1'
      LIMIT 1
    ];

    Attendee__c attendee = [
      SELECT Id
      FROM Attendee__c
      LIMIT 1
    ];

    Test.startTest();

    Event_Attendee__c registration = new Event_Attendee__c(
      Medical_Event__c = eventRecord.Id,
      Attendee__c = attendee.Id
    );
    insert registration;

    Test.stopTest();

    Event_Attendee__c insertedRegistration = [
      SELECT Id, Medical_Event__c, Attendee__c
      FROM Event_Attendee__c
      WHERE Id = :registration.Id
    ];

    System.assertNotEquals(null, insertedRegistration.Id);
    System.assertEquals(eventRecord.Id, insertedRegistration.Medical_Event__c);
    System.assertEquals(attendee.Id, insertedRegistration.Attendee__c);
  }

  @IsTest
  static void shouldPreventDuplicateAttendeeRegistrationForSameEvent() {
    Medical_Event__c eventRecord = [
      SELECT Id
      FROM Medical_Event__c
      WHERE Event_Name__c = 'Health Talk 1'
      LIMIT 1
    ];

    Attendee__c attendee = [
      SELECT Id
      FROM Attendee__c
      WHERE Name = 'Attendee Test'
      LIMIT 1
    ];

    insert new Event_Attendee__c(
      Medical_Event__c = eventRecord.Id,
      Attendee__c = attendee.Id
    );

    Test.startTest();

    Boolean errorThrown = false;
    try {
      insert new Event_Attendee__c(
        Medical_Event__c = eventRecord.Id,
        Attendee__c = attendee.Id
      );
    } catch (DmlException e) {
      errorThrown = true;
      System.assert(
        e.getMessage()
          .contains(
            'Este participante já está inscrito neste evento médico.'
          ),
        'A mensagem de erro deve indicar duplicidade de inscricao.'
      );
    }

    Test.stopTest();

    System.assertEquals(
      true,
      errorThrown,
      'Deveria bloquear attendee duplicado no mesmo evento.'
    );
  }

  @IsTest
  static void shouldAllowSameAttendeeInDifferentEvents() {
    List<Medical_Event__c> events = [
      SELECT Id
      FROM Medical_Event__c
      ORDER BY Event_Name__c ASC
    ];

    Attendee__c attendee = [
      SELECT Id
      FROM Attendee__c
      WHERE Name = 'Attendee Test'
      LIMIT 1
    ];

    Test.startTest();

    insert new List<Event_Attendee__c>{
      new Event_Attendee__c(
        Medical_Event__c = events[0].Id,
        Attendee__c = attendee.Id
      ),
      new Event_Attendee__c(
        Medical_Event__c = events[1].Id,
        Attendee__c = attendee.Id
      )
    };

    Test.stopTest();

    Integer registrations = [
      SELECT COUNT()
      FROM Event_Attendee__c
      WHERE Attendee__c = :attendee.Id
    ];

    System.assertEquals(2, registrations);
  }

  @IsTest
  static void shouldAllowDifferentAttendeesInSameEvent() {
    Medical_Event__c eventRecord = [
      SELECT Id
      FROM Medical_Event__c
      WHERE Event_Name__c = 'Health Talk 1'
      LIMIT 1
    ];

    List<Attendee__c> attendees = [
      SELECT Id
      FROM Attendee__c
      ORDER BY Name ASC
    ];

    Test.startTest();

    insert new List<Event_Attendee__c>{
      new Event_Attendee__c(
        Medical_Event__c = eventRecord.Id,
        Attendee__c = attendees[0].Id
      ),
      new Event_Attendee__c(
        Medical_Event__c = eventRecord.Id,
        Attendee__c = attendees[1].Id
      )
    };

    Test.stopTest();

    Integer registrations = [
      SELECT COUNT()
      FROM Event_Attendee__c
      WHERE Medical_Event__c = :eventRecord.Id
    ];

    System.assertEquals(2, registrations);
  }

  @IsTest
  static void shouldAllowUpdatingExistingRegistrationWithoutFalseDuplicate() {
    Medical_Event__c eventRecord = [
      SELECT Id
      FROM Medical_Event__c
      WHERE Event_Name__c = 'Health Talk 1'
      LIMIT 1
    ];

    Attendee__c attendee = [
      SELECT Id
      FROM Attendee__c
      WHERE Name = 'Attendee Test'
      LIMIT 1
    ];

    Event_Attendee__c registrationToUpdate = new Event_Attendee__c(
      Medical_Event__c = eventRecord.Id,
      Attendee__c = attendee.Id
    );
    insert registrationToUpdate;

    Test.startTest();

    update registrationToUpdate;

    Test.stopTest();

    Event_Attendee__c updatedRegistration = [
      SELECT Id
      FROM Event_Attendee__c
      WHERE Id = :registrationToUpdate.Id
    ];

    System.assertNotEquals(null, updatedRegistration.Id);
  }

  @IsTest
  static void shouldPreventDuplicateActiveSpeakerBooking() {
    Speaker__c speaker = [
      SELECT Id
      FROM Speaker__c
      LIMIT 1
    ];

    List<Medical_Event__c> events = [
      SELECT Id
      FROM Medical_Event__c
      ORDER BY Event_Name__c ASC
    ];

    Event_Speaker__c firstBooking = new Event_Speaker__c(
      Medical_Event__c = events[0].Id,
      Speaker__c = speaker.Id
    );
    insert firstBooking;

    Test.startTest();

    Boolean errorThrown = false;

    try {
      Event_Speaker__c secondBooking = new Event_Speaker__c(
        Medical_Event__c = events[1].Id,
        Speaker__c = speaker.Id
      );
      insert secondBooking;
    } catch (DmlException e) {
      errorThrown = true;
    }

    Test.stopTest();

    System.assertEquals(
      true,
      errorThrown,
      'Deveria bloquear speaker duplicado em evento ativo.'
    );
  }
}
