public with sharing class AttendeeEventsController {
  public class AttendeeEventsResponse {
    @AuraEnabled
    public List<EventItem> upcomingEvents { get; set; }
    @AuraEnabled
    public List<EventItem> pastEvents { get; set; }

    public AttendeeEventsResponse() {
      upcomingEvents = new List<EventItem>();
      pastEvents = new List<EventItem>();
    }
  }

  public class EventItem {
    @AuraEnabled
    public Id eventId { get; set; }
    @AuraEnabled
    public String eventName { get; set; }
    @AuraEnabled
    public Datetime startDateTime { get; set; }
    @AuraEnabled
    public Datetime endDateTime { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String eventType { get; set; }
    @AuraEnabled
    public String locationName { get; set; }

    public EventItem(Medical_Event__c eventRecord) {
      eventId = eventRecord.Id;
      eventName = eventRecord.Event_Name__c;
      startDateTime = eventRecord.Start_Date_Time__c;
      endDateTime = eventRecord.End_Date_Time__c;
      status = eventRecord.Status__c;
      eventType = eventRecord.Event_Type__c;
      locationName = eventRecord.Event_Type__c == 'Virtual'
        ? 'Virtual Event'
        : eventRecord.Address__r != null ? eventRecord.Address__r.Name : null;
    }
  }

  @AuraEnabled(cacheable=true)
  public static AttendeeEventsResponse getEventsByAttendee(Id attendeeId) {
    if (attendeeId == null) {
      throw new AuraHandledException('Participante nao informado.');
    }

    try {
      AttendeeEventsResponse response = new AttendeeEventsResponse();
      Datetime nowValue = System.now();

      for (Event_Attendee__c registration : [
        SELECT
          Medical_Event__r.Id,
          Medical_Event__r.Event_Name__c,
          Medical_Event__r.Start_Date_Time__c,
          Medical_Event__r.End_Date_Time__c,
          Medical_Event__r.Status__c,
          Medical_Event__r.Event_Type__c,
          Medical_Event__r.Address__r.Name
        FROM Event_Attendee__c
        WHERE Attendee__c = :attendeeId
        WITH USER_MODE
        ORDER BY Medical_Event__r.Start_Date_Time__c ASC
      ]) {
        Medical_Event__c eventRecord = registration.Medical_Event__r;
        if (eventRecord == null) {
          continue;
        }

        EventItem item = new EventItem(eventRecord);
        if (eventRecord.Start_Date_Time__c >= nowValue) {
          response.upcomingEvents.add(item);
        } else if (eventRecord.End_Date_Time__c < nowValue) {
          response.pastEvents.add(item);
        }
      }

      return response;
    } catch (Exception e) {
      ErrorLogService.logError(
        System.now(),
        e.getMessage() + ' - ' + e.getStackTraceString(),
        'AttendeeEventsController'
      );
      throw new AuraHandledException(
        'Nao foi possivel carregar os eventos do participante.'
      );
    }
  }
}
