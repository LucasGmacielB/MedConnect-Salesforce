public with sharing class EventRegistrationController {
  @AuraEnabled
  public static Id registerAttendee(
    Id medicalEventId,
    String name,
    String email,
    String phone,
    String companyInstitutionName
  ) {
    try {
      validateInput(medicalEventId, name, email);

      Medical_Event__c eventRecord = getValidEvent(medicalEventId);
      Attendee__c attendee = findOrCreateAttendee(
        name,
        email,
        phone,
        companyInstitutionName
      );

      if (
        [
          SELECT COUNT()
          FROM Event_Attendee__c
          WHERE Medical_Event__c = :eventRecord.Id AND Attendee__c = :attendee.Id
          WITH USER_MODE
        ] > 0
      ) {
        throw new AuraHandledException('Voce ja esta inscrito neste evento.');
      }

      Event_Attendee__c registration = new Event_Attendee__c(
        Medical_Event__c = eventRecord.Id,
        Attendee__c = attendee.Id,
        Status__c = 'Registered'
      );
      insert as user registration;

      return registration.Id;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      ErrorLogService.logError(
        System.now(),
        e.getMessage() + ' - ' + e.getStackTraceString(),
        'EventRegistrationController'
      );
      throw new AuraHandledException(
        'Nao foi possivel concluir sua inscricao no momento.'
      );
    }
  }

  private static void validateInput(Id medicalEventId, String name, String email) {
    if (medicalEventId == null) {
      throw new AuraHandledException('Informe o evento para realizar a inscricao.');
    }

    if (String.isBlank(name)) {
      throw new AuraHandledException('Informe seu nome completo.');
    }

    if (String.isBlank(email)) {
      throw new AuraHandledException('Informe seu e-mail.');
    }
  }

  private static Medical_Event__c getValidEvent(Id medicalEventId) {
    List<Medical_Event__c> events = [
      SELECT Id, Live__c, End_Date_Time__c, Remaining_Seats__c
      FROM Medical_Event__c
      WHERE Id = :medicalEventId
      WITH USER_MODE
      LIMIT 1
    ];

    if (events.isEmpty()) {
      throw new AuraHandledException('Evento nao encontrado.');
    }

    Medical_Event__c eventRecord = events[0];

    if (eventRecord.Live__c != true) {
      throw new AuraHandledException('Este evento nao esta aberto para inscricoes.');
    }

    if (
      eventRecord.End_Date_Time__c == null ||
      eventRecord.End_Date_Time__c <= System.now()
    ) {
      throw new AuraHandledException('As inscricoes deste evento ja foram encerradas.');
    }

    if (eventRecord.Remaining_Seats__c == null || eventRecord.Remaining_Seats__c <= 0) {
      throw new AuraHandledException('Este evento nao possui vagas disponiveis.');
    }

    return eventRecord;
  }

  private static Attendee__c findOrCreateAttendee(
    String name,
    String email,
    String phone,
    String companyInstitutionName
  ) {
    String normalizedEmail = email.trim().toLowerCase();
    List<Attendee__c> attendees = [
      SELECT Id
      FROM Attendee__c
      WHERE Email__c = :normalizedEmail
      WITH USER_MODE
      LIMIT 1
    ];

    if (!attendees.isEmpty()) {
      return attendees[0];
    }

    Attendee__c attendee = new Attendee__c(
      Name = name.trim(),
      Email__c = normalizedEmail,
      Phone__c = String.isBlank(phone) ? null : phone.trim(),
      Company_Institution_Name__c = String.isBlank(companyInstitutionName)
        ? null
        : companyInstitutionName.trim()
    );
    insert as user attendee;
    return attendee;
  }
}
