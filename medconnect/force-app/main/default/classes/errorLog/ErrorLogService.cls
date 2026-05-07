public class ErrorLogService {

    public static void logError(Datetime logDateTime, String logDetails, String processName) {
        
        try {
            Error_Log__c log = new Error_Log__c();

            log.Log_Date_Time__c = logDateTime;
            log.Log_Details__c = logDetails;
            log.Process_Name__c = processName;

            insert log;

        } catch (Exception e) {
            System.debug('Erro ao salvar log: ' + e.getMessage());
        }
    }
}