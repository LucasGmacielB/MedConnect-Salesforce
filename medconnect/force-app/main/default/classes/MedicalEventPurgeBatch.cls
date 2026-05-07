public class MedicalEventPurgeBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        DateTime limitDate = System.now().addMonths(-2);

        return Database.getQueryLocator([
            SELECT Id
            FROM Medical_Event__c
            WHERE End_Date_Time__c < :limitDate
            AND Live__c = false
        ]);
    }

    public void execute(Database.BatchableContext context, List<Medical_Event__c> scope) {
        System.debug('EVENTOS ENCONTRADOS: ' + scope.size());
        MedicalEventPurgeHandler.deleteOldEvents(scope);
    }

    public void finish(Database.BatchableContext context) {
        //Pega o email do usuário que executou o batch.
        try {

            User currentUser = [
                SELECT Email, Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            email.setToAddresses(new List<String>{
                currentUser.Email
            });

            email.setSubject('MedConnect - Batch de limpeza concluída');

            email.setPlainTextBody(
                'Olá ' + currentUser.Name + ',\n\n' +

                'A limpeza de Medical Events antigos foi concluída com sucesso.\n\n' +

                'Critérios utilizados:\n' +
                '- Eventos com mais de 2 meses\n' +
                '- Eventos com Live = false\n\n' +

                'Atenciosamente,\n' +
                'Sistema MedConnect'
            );

            System.debug('BATCH EMAIL PARA: ' + currentUser.Email);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ email },
                false
            );

            for (Messaging.SendEmailResult result : results) {
                System.debug('BATCH EMAIL SUCCESS: ' + result.isSuccess());

                if (!result.isSuccess()) {
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        System.debug('BATCH EMAIL ERROR: ' + error.getMessage());
                    }
                }
            }

        } catch (Exception e) {

            ErrorLogService.logError(
                System.now(),
                e.getMessage() + ' - ' + e.getStackTraceString(),
                'MedicalEventPurgeBatch'
            );

        }
    }
}