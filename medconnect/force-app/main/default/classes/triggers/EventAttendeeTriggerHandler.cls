public class EventAttendeeTriggerHandler {

    public static void sendConfirmationEmails(List<Event_Attendee__c> newRecords) {
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
                email.setToAddresses(new List<String>{ registration.Attendee__r.Email__c });
                
                // Importante: Para usar ToAddresses com Templates, precisamos desabilitar o salvamento como atividade 
                // se o TargetObjectId for nulo.
                email.setSaveAsActivity(false);

                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails, false);
            }

        } catch (Exception e) {
            ErrorLogService.logError(System.now(), e.getMessage() + ' - ' + e.getStackTraceString(), 'EventAttendeeTriggerHandler');
        }
    }
}