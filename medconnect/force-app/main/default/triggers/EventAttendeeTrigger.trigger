trigger EventAttendeeTrigger on Event_Attendee__c(
  before insert,
  before update,
  after insert,
  after update
) {
  if (Trigger.isBefore) {
    EventAttendeeTriggerHandler.preventDuplicateAttendeeRegistration(
      Trigger.new,
      Trigger.oldMap
    );
  }

  if (Trigger.isAfter && Trigger.isInsert) {
    EventAttendeeTriggerHandler.sendConfirmationEmails(Trigger.new);
  }

  if (Trigger.isAfter && Trigger.isUpdate) {
    EventAttendeeTriggerHandler.handleCancellation(Trigger.new, Trigger.oldMap);
  }
}
