trigger LocationTrigger on Location__c (after insert, after update) {
    if (Trigger.isAfter) {
        LocationTriggerHandler.afterInsertOrUpdate(Trigger.new, Trigger.oldMap);
    }
}
