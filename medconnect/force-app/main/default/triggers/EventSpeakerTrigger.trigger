trigger EventSpeakerTrigger on Event_Speaker__c (before insert, before update) {
    EventSpeakerTriggerHandler.preventDuplicateActiveSpeakerBooking(Trigger.new, Trigger.oldMap);
}