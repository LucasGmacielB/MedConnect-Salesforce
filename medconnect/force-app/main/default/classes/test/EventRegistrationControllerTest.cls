@IsTest
public class EventRegistrationControllerTest {
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
      buildEvent('Evento Aberto', true, 2, 3, 2, organizer.Id, location.Id),
      buildEvent('Evento Existente', true, 4, 5, 3, organizer.Id, location.Id),
      buildEvent('Evento Inativo', false, 6, 7, 5, organizer.Id, location.Id),
      buildEvent('Evento Encerrado', true, -3, -2, 5, organizer.Id, location.Id),
      buildEvent('Evento Lotado', true, 8, 9, 0, organizer.Id, location.Id)
    };

    insert new Attendee__c(
      Name = 'Participante Existente',
      Email__c = 'existente@example.com',
      Phone__c = '81999990000'
    );
  }

  @IsTest
  static void shouldRegisterNewAttendee() {
    Id eventId = getEventId('Evento Aberto');

    Test.startTest();
    Id registrationId = EventRegistrationController.registerAttendee(
      eventId,
      'Maria Silva',
      'maria@example.com',
      '81999990001',
      'Hospital Recife'
    );
    Test.stopTest();

    System.assertNotEquals(null, registrationId);
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Attendee__c WHERE Email__c = 'maria@example.com']
    );
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Event_Attendee__c WHERE Medical_Event__c = :eventId]
    );
  }

  @IsTest
  static void shouldRegisterExistingAttendee() {
    Id eventId = getEventId('Evento Existente');

    Test.startTest();
    Id registrationId = EventRegistrationController.registerAttendee(
      eventId,
      'Participante Existente',
      'existente@example.com',
      '81999990000',
      'Clinica Recife'
    );
    Test.stopTest();

    System.assertNotEquals(null, registrationId);
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Attendee__c WHERE Email__c = 'existente@example.com']
    );
  }

  @IsTest
  static void shouldRejectDuplicateRegistration() {
    Id eventId = getEventId('Evento Aberto');

    EventRegistrationController.registerAttendee(
      eventId,
      'Joao Silva',
      'joao@example.com',
      null,
      null
    );

    Boolean wasThrown = false;

    Test.startTest();
    try {
      EventRegistrationController.registerAttendee(
        eventId,
        'Joao Silva',
        'joao@example.com',
        null,
        null
      );
    } catch (AuraHandledException e) {
      wasThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, wasThrown);
  }

  @IsTest
  static void shouldRejectInactiveEvent() {
    assertRegistrationFails(getEventId('Evento Inativo'));
  }

  @IsTest
  static void shouldRejectEndedEvent() {
    assertRegistrationFails(getEventId('Evento Encerrado'));
  }

  @IsTest
  static void shouldRejectEventWithoutSeats() {
    assertRegistrationFails(getEventId('Evento Lotado'));
  }

  private static Medical_Event__c buildEvent(
    String eventName,
    Boolean live,
    Integer startOffsetDays,
    Integer endOffsetDays,
    Integer maxSeats,
    Id organizerId,
    Id locationId
  ) {
    return new Medical_Event__c(
      Event_Name__c = eventName,
      Start_Date_Time__c = System.now().addDays(startOffsetDays),
      End_Date_Time__c = System.now().addDays(endOffsetDays),
      Status__c = live ? 'Published' : 'Created',
      Event_Type__c = 'In-Person',
      Live__c = live,
      Max_Seats__c = maxSeats,
      Organizer__c = organizerId,
      Address__c = locationId
    );
  }

  private static Id getEventId(String eventName) {
    return [
      SELECT Id
      FROM Medical_Event__c
      WHERE Event_Name__c = :eventName
      LIMIT 1
    ]
    .Id;
  }

  private static void assertRegistrationFails(Id eventId) {
    Boolean wasThrown = false;

    Test.startTest();
    try {
      EventRegistrationController.registerAttendee(
        eventId,
        'Teste Falha',
        String.valueOf(eventId).substring(0, 8) + '@example.com',
        null,
        null
      );
    } catch (AuraHandledException e) {
      wasThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, wasThrown);
  }
}
