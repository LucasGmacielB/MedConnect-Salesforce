public with sharing class CommunityEventLandingController {
  private static final String DEFAULT_DESCRIPTION = 'Confira a programacao cientifica, convidados e informacoes gerais deste evento medico.';

  public class EventCard {
    @AuraEnabled
    public Id eventId { get; set; }
    @AuraEnabled
    public String eventName { get; set; }
    @AuraEnabled
    public Datetime startDateTime { get; set; }
    @AuraEnabled
    public Datetime endDateTime { get; set; }
    @AuraEnabled
    public String eventType { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String locationName { get; set; }
    @AuraEnabled
    public String city { get; set; }
    @AuraEnabled
    public String state { get; set; }
    @AuraEnabled
    public String locationLabel { get; set; }
    @AuraEnabled
    public String description { get; set; }

    public EventCard(Medical_Event__c eventRecord) {
      eventId = eventRecord.Id;
      eventName = eventRecord.Event_Name__c;
      startDateTime = eventRecord.Start_Date_Time__c;
      endDateTime = eventRecord.End_Date_Time__c;
      eventType = eventRecord.Event_Type__c;
      status = eventRecord.Status__c;

      if (eventRecord.Address__r != null) {
        locationName = eventRecord.Address__r.Name;
        city = eventRecord.Address__r.City__c;
        state = eventRecord.Address__r.State__c;
      }

      locationLabel = buildLocationLabel(eventType, locationName, city, state);
      description = DEFAULT_DESCRIPTION;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<EventCard> getUpcomingEvents() {
    Datetime nowValue = System.now();
    List<EventCard> results = new List<EventCard>();

    for (Medical_Event__c eventRecord : [
      SELECT
        Id,
        Event_Name__c,
        Start_Date_Time__c,
        End_Date_Time__c,
        Event_Type__c,
        Status__c,
        Address__r.Name,
        Address__r.City__c,
        Address__r.State__c
      FROM Medical_Event__c
      WHERE Live__c = TRUE AND Start_Date_Time__c >= :nowValue
      WITH USER_MODE
      ORDER BY Start_Date_Time__c ASC
      LIMIT 12
    ]) {
      results.add(new EventCard(eventRecord));
    }

    return results;
  }

  private static String buildLocationLabel(
    String eventType,
    String locationName,
    String city,
    String state
  ) {
    if (eventType == 'Virtual') {
      return 'Evento online';
    }

    List<String> parts = new List<String>();

    if (String.isNotBlank(locationName)) {
      parts.add(locationName);
    }

    String cityState = String.isNotBlank(city) && String.isNotBlank(state)
      ? city + ', ' + state
      : String.isNotBlank(city) ? city : state;

    if (String.isNotBlank(cityState)) {
      parts.add(cityState);
    }

    return parts.isEmpty() ? 'Local a confirmar' : String.join(parts, ' - ');
  }
}
