public with sharing class ViaCepAddressVerificationQueueable implements Queueable, Database.AllowsCallouts {
    private final Set<Id> locationIds;

    public ViaCepAddressVerificationQueueable(Set<Id> locationIds) {
        this.locationIds = locationIds == null ? new Set<Id>() : new Set<Id>(locationIds);
    }

    public void execute(QueueableContext context) {
        if (locationIds.isEmpty()) {
            return;
        }

        List<Location__c> locationsToUpdate = new List<Location__c>();
        for (Location__c location : [
            SELECT Id, Street__c, City__c, State__c, Postal_Code__c, Country__c, Verified__c
            FROM Location__c
            WHERE Id IN :locationIds
            WITH USER_MODE
        ]) {
            try {
                Boolean verified = ViaCepAddressVerificationService.verify(location);
                if (location.Verified__c != verified) {
                    locationsToUpdate.add(new Location__c(Id = location.Id, Verified__c = verified));
                }
            } catch (Exception e) {
                ErrorLogService.logError(System.now(), e.getMessage(), 'ViaCepAddressVerificationQueueable');
            }
        }

        if (!locationsToUpdate.isEmpty()) {
            Database.update(locationsToUpdate, false, AccessLevel.USER_MODE);
        }
    }
}
