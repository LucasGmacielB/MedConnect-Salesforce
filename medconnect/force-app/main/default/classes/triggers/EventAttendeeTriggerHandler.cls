public class EventAttendeeTriggerHandler {
  private static final String DUPLICATE_REGISTRATION_ERROR = 'Este participante já está inscrito neste evento médico.';

  public static void preventDuplicateAttendeeRegistration(
    List<Event_Attendee__c> newRecords,
    Map<Id, Event_Attendee__c> oldMap
  ) {
    Set<Id> eventIds = new Set<Id>();
    Set<Id> attendeeIds = new Set<Id>();
    Set<String> pairKeysInRequest = new Set<String>();

    for (Event_Attendee__c record : newRecords) {
      if (record.Medical_Event__c == null || record.Attendee__c == null) {
        continue;
      }

      String pairKey = buildRegistrationKey(
        record.Medical_Event__c,
        record.Attendee__c
      );
      if (pairKeysInRequest.contains(pairKey)) {
        record.addError(DUPLICATE_REGISTRATION_ERROR);
        continue;
      }

      pairKeysInRequest.add(pairKey);
      eventIds.add(record.Medical_Event__c);
      attendeeIds.add(record.Attendee__c);
    }

    if (eventIds.isEmpty() || attendeeIds.isEmpty()) {
      return;
    }

    Map<String, Id> existingRegistrationIdByPair = new Map<String, Id>();
    for (Event_Attendee__c existingRegistration : [
      SELECT Id, Medical_Event__c, Attendee__c
      FROM Event_Attendee__c
      WHERE Medical_Event__c IN :eventIds AND Attendee__c IN :attendeeIds
    ]) {
      existingRegistrationIdByPair.put(
        buildRegistrationKey(
          existingRegistration.Medical_Event__c,
          existingRegistration.Attendee__c
        ),
        existingRegistration.Id
      );
    }

    for (Event_Attendee__c record : newRecords) {
      if (record.Medical_Event__c == null || record.Attendee__c == null) {
        continue;
      }

      Id existingRegistrationId = existingRegistrationIdByPair.get(
        buildRegistrationKey(record.Medical_Event__c, record.Attendee__c)
      );

      if (
        existingRegistrationId != null &&
        existingRegistrationId != record.Id
      ) {
        record.addError(DUPLICATE_REGISTRATION_ERROR);
      }
    }
  }

  private static String buildRegistrationKey(Id medicalEventId, Id attendeeId) {
    return String.valueOf(medicalEventId) + ':' + String.valueOf(attendeeId);
  }

  public static void sendConfirmationEmails(
    List<Event_Attendee__c> newRecords
  ) {
    try {
      // Buscar o ID do Template de E-mail
      EmailTemplate template = [
        SELECT Id
        FROM EmailTemplate
        WHERE DeveloperName = 'Event_Registration_Confirmation'
        LIMIT 1
      ];

      List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

      // Para templates funcionarem com campos personalizados do objeto,
      // precisamos do ID do registro (WhatId) e o ID do destinatário (TargetObjectId).
      // Nota: O TargetObjectId deve ser um Lead, Contact ou User ID.
      // Se Attendee__c não for um desses, usaremos o ID do registro e renderizaremos manualmente ou
      // assumiremos que o e-mail será enviado para o endereço fixo.

      for (Event_Attendee__c record : newRecords) {
        // Buscamos os dados necessários para o envio (Email do participante)
        // Usamos uma query aqui ou passamos os dados já carregados
        Event_Attendee__c registration = [
          SELECT Id, Attendee__r.Email__c
          FROM Event_Attendee__c
          WHERE Id = :record.Id
          LIMIT 1
        ];

        if (String.isBlank(registration.Attendee__r.Email__c)) {
          continue;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setTemplateId(template.Id);
        email.setWhatId(registration.Id); // Associa o registro para Merge Fields

        // Como Attendee__c é um objeto customizado e não um Contato/Lead,
        // definimos o endereço de e-mail manualmente e setamos o TargetObjectId como nulo
        // ou usamos um ID fake/técnico se necessário para renderização.
        email.setToAddresses(
          new List<String>{ registration.Attendee__r.Email__c }
        );

        // Importante: Para usar ToAddresses com Templates, precisamos desabilitar o salvamento como atividade
        // se o TargetObjectId for nulo.
        email.setSaveAsActivity(false);

        emails.add(email);
      }

      if (!emails.isEmpty()) {
        Messaging.sendEmail(emails, false);
      }
    } catch (Exception e) {
      ErrorLogService.logError(
        System.now(),
        e.getMessage() + ' - ' + e.getStackTraceString(),
        'EventAttendeeTriggerHandler'
      );
    }
  }

  public static void handleCancellation(
    List<Event_Attendee__c> newRecords,
    Map<Id, Event_Attendee__c> oldMap
  ) {
    List<Event_Attendee__c> cancelledRecords = new List<Event_Attendee__c>();

    for (Event_Attendee__c record : newRecords) {
      Event_Attendee__c oldRecord = oldMap.get(record.Id);

      if (
        record.Status__c == 'Cancelled' &&
        oldRecord.Status__c != 'Cancelled'
      ) {
        cancelledRecords.add(record);
      }
    }

    if (cancelledRecords.isEmpty()) {
      return;
    }

    try {
      List<Event_Attendee__c> registrations = [
        SELECT Id, Attendee__r.Name, Attendee__r.Email__c,
              Medical_Event__r.Event_Name__c
        FROM Event_Attendee__c
        WHERE Id IN :cancelledRecords
      ];

      List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

      for (Event_Attendee__c registration : registrations) {
        if (String.isBlank(registration.Attendee__r.Email__c)) continue;

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ registration.Attendee__r.Email__c });
        email.setSubject('Event Registration Cancelled');
        email.setPlainTextBody(
          'Hello ' + registration.Attendee__r.Name +
          ', your registration for the event "' +
          registration.Medical_Event__r.Event_Name__c +
          '" has been cancelled.'
        );
        email.setSaveAsActivity(false);
        emails.add(email);
      }

      if (!emails.isEmpty()) Messaging.sendEmail(emails, false);

    } catch (Exception e) {
      ErrorLogService.logError(
        System.now(),
        e.getMessage() + ' - ' + e.getStackTraceString(),
        'EventAttendeeCancellation'
      );
    }
  }
}
