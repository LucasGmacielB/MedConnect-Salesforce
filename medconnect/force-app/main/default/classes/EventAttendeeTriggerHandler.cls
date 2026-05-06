public class EventAttendeeTriggerHandler {

    public static void sendConfirmationEmails(List<Event_Attendee__c> newRecords) {
        try {
            Set<Id> eventAttendeeIds = new Set<Id>();

            for (Event_Attendee__c record : newRecords) {
                eventAttendeeIds.add(record.Id);
            }

            List<Event_Attendee__c> registrations = [
                SELECT Id,
                       Attendee__r.Name,
                       Attendee__r.Email__c,
                       Medical_Event__r.Event_Name__c,
                       Medical_Event__r.Start_Date_Time__c,
                       Medical_Event__r.Organizer__r.Name,
                       Medical_Event__r.Address__r.Street__c,
                       Medical_Event__r.Address__r.City__c,
                       Medical_Event__r.Address__r.State__c,
                       Medical_Event__r.Address__r.Country__c
                FROM Event_Attendee__c
                WHERE Id IN :eventAttendeeIds
            ];

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Event_Attendee__c registration : registrations) {
                if (String.isBlank(registration.Attendee__r.Email__c)) {
                    continue;
                }

                String eventName = registration.Medical_Event__r.Event_Name__c;
                String attendeeName = registration.Attendee__r.Name;
                String organizerName = registration.Medical_Event__r.Organizer__r.Name;
                String eventDate = String.valueOf(registration.Medical_Event__r.Start_Date_Time__c);

                String locationText = '';

                if (registration.Medical_Event__r.Address__r != null) {
                    locationText =
                        registration.Medical_Event__r.Address__r.Street__c + ', ' +
                        registration.Medical_Event__r.Address__r.City__c + ', ' +
                        registration.Medical_Event__r.Address__r.State__c + ', ' +
                        registration.Medical_Event__r.Address__r.Country__c;
                } else {
                    locationText = 'Virtual Event';
                }

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                email.setToAddresses(new List<String>{
                    registration.Attendee__r.Email__c
                });

                email.setSubject('Ingresso para o evento "' + eventName + '"');

                email.setPlainTextBody(
                    'Olá ' + attendeeName + ',\n\n' +
                    
                    'Obrigado por se registrar no evento "' + eventName + '" que acontecerá em ' +
                    '"' + eventDate + '" no local "' + locationText + '". Estamos felizes em ter você conosco!\n\n' +
                    
                    'Você pode visualizar a localização do evento no Google Maps através do link abaixo:\n' +
                    'https://www.google.com/maps/place/' + EncodingUtil.urlEncode(locationText, 'UTF-8') + '\n\n' +
                    
                    'Atenciosamente,\n' +
                    organizerName
                );

                emails.add(email);
            }
     

            if (!emails.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);

                for (Messaging.SendEmailResult result : results) {
                    System.debug('EMAIL SUCCESS: ' + result.isSuccess());

                    if (!result.isSuccess()) {
                        for (Messaging.SendEmailError error : result.getErrors()) {
                            System.debug('EMAIL ERROR: ' + error.getMessage());
                        }
                    }
                }
            }

        } catch (Exception e) {
            ErrorLogService.logError(System.now(), e.getMessage() + ' - ' + e.getStackTraceString(), 'EventAttendeeTriggerHandler');
        }
    }
}