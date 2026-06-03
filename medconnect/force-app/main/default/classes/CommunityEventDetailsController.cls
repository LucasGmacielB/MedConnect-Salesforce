public with sharing class CommunityEventDetailsController {
  public class EventDetails {
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
    public Decimal remainingSeats { get; set; }
    @AuraEnabled
    public Decimal maxSeats { get; set; }
    @AuraEnabled
    public String organizerName { get; set; }
    @AuraEnabled
    public String locationName { get; set; }
    @AuraEnabled
    public String addressText { get; set; }
    @AuraEnabled
    public Boolean locationVerified { get; set; }
    @AuraEnabled
    public List<SpeakerDetails> speakers { get; set; }

    public EventDetails(Medical_Event__c eventRecord) {
      eventId = eventRecord.Id;
      eventName = eventRecord.Event_Name__c;
      startDateTime = eventRecord.Start_Date_Time__c;
      endDateTime = eventRecord.End_Date_Time__c;
      status = eventRecord.Status__c;
      eventType = eventRecord.Event_Type__c;
      remainingSeats = eventRecord.Remaining_Seats__c;
      maxSeats = eventRecord.Max_Seats__c;
      organizerName = eventRecord.Organizer__r?.Name;
      locationName = eventRecord.Address__r?.Name;
      locationVerified = eventRecord.Location_Verified__c;
      addressText = buildAddressText(eventRecord);
      speakers = new List<SpeakerDetails>();
    }
  }

  public class SpeakerDetails {
    @AuraEnabled
    public Id speakerId { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String specialization { get; set; }
    @AuraEnabled
    public String profileUrl { get; set; }
    @AuraEnabled
    public String aboutMe { get; set; }

    public SpeakerDetails(Event_Speaker__c eventSpeaker) {
      speakerId = eventSpeaker.Speaker__c;
      name = eventSpeaker.Speaker__r.Name;
      specialization = eventSpeaker.Speaker__r.Specialization__c;
      profileUrl = eventSpeaker.Speaker__r.Profile_URL__c;
      aboutMe = eventSpeaker.Speaker__r.About_Me__c;
    }
  }

  @AuraEnabled(cacheable=true)
  public static EventDetails getEventDetails(Id eventId) {
    if (eventId == null) {
      throw new AuraHandledException('Informe um evento para consultar os detalhes.');
    }

    try {
      List<Medical_Event__c> events = [
        SELECT
          Id,
          Event_Name__c,
          Start_Date_Time__c,
          End_Date_Time__c,
          Status__c,
          Event_Type__c,
          Live__c,
          Max_Seats__c,
          Remaining_Seats__c,
          Organizer__r.Name,
          Address__r.Name,
          Address__r.Street__c,
          Address__r.City__c,
          Address__r.State__c,
          Address__r.Postal_Code__c,
          Address__r.Country__c,
          Location_Verified__c
        FROM Medical_Event__c
        WHERE Id = :eventId
        WITH USER_MODE
        LIMIT 1
      ];

      if (events.isEmpty()) {
        throw new AuraHandledException('Evento nao encontrado.');
      }

      EventDetails result = new EventDetails(events[0]);

      for (Event_Speaker__c eventSpeaker : [
        SELECT
          Medical_Event__c,
          Speaker__c,
          Speaker__r.Name,
          Speaker__r.Specialization__c,
          Speaker__r.Profile_URL__c,
          Speaker__r.About_Me__c
        FROM Event_Speaker__c
        WHERE Medical_Event__c = :eventId
        WITH USER_MODE
        ORDER BY Speaker__r.Name ASC
      ]) {
        result.speakers.add(new SpeakerDetails(eventSpeaker));
      }

      return result;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      ErrorLogService.logError(
        System.now(),
        e.getMessage() + ' - ' + e.getStackTraceString(),
        'CommunityEventDetailsController'
      );
      throw new AuraHandledException(
        'Nao foi possivel carregar os detalhes do evento no momento.'
      );
    }
  }

  private static String buildAddressText(Medical_Event__c eventRecord) {
    if (eventRecord.Address__r == null) {
      return 'Local a confirmar';
    }

    List<String> parts = new List<String>();
    addIfPresent(parts, eventRecord.Address__r.Street__c);
    addIfPresent(parts, eventRecord.Address__r.City__c);
    addIfPresent(parts, eventRecord.Address__r.State__c);
    addIfPresent(parts, eventRecord.Address__r.Postal_Code__c);
    addIfPresent(parts, eventRecord.Address__r.Country__c);

    return parts.isEmpty() ? 'Local a confirmar' : String.join(parts, ', ');
  }

  private static void addIfPresent(List<String> parts, String value) {
    if (String.isNotBlank(value)) {
      parts.add(value);
    }
  }
}
