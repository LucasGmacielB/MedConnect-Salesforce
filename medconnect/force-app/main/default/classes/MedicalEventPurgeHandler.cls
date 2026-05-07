public class MedicalEventPurgeHandler {

    public static void deleteOldEvents(List<Medical_Event__c> eventsToDelete) {
        if (eventsToDelete == null || eventsToDelete.isEmpty()) {
            return;
        }

        try {
            delete eventsToDelete;
        } catch (Exception e) {
            ErrorLogService.logError(System.now(), e.getMessage() + ' - ' + e.getStackTraceString(), 'MedicalEventPurgeHandler');
        }
    }
}