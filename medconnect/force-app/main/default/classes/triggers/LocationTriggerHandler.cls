public with sharing class LocationTriggerHandler {
    public static void afterInsertOrUpdate(List<Location__c> newLocations, Map<Id, Location__c> oldMap) {
        Set<Id> locationIds = new Set<Id>();

        for (Location__c location : newLocations) {
            Location__c oldLocation = oldMap == null ? null : oldMap.get(location.Id);
            if (oldLocation == null || addressChanged(location, oldLocation)) {
                locationIds.add(location.Id);
            }
        }

        if (!locationIds.isEmpty()) {
            System.enqueueJob(new SmartyAddressVerificationQueueable(locationIds));
        }
    }

    private static Boolean addressChanged(Location__c newLocation, Location__c oldLocation) {
        return newLocation.Street__c != oldLocation.Street__c ||
            newLocation.City__c != oldLocation.City__c ||
            newLocation.State__c != oldLocation.State__c ||
            newLocation.Postal_Code__c != oldLocation.Postal_Code__c ||
            newLocation.Country__c != oldLocation.Country__c;
    }
}
