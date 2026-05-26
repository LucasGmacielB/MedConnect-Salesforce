trigger EventAttendeeTrigger on Event_Attendee__c(
  before insert,
  before update,
  after insert
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
}
