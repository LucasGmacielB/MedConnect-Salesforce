public with sharing class EventListController {
  public class EventListItem {
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
    public Decimal remainingSeats { get; set; }
    @AuraEnabled
    public String locationName { get; set; }

    public EventListItem(Medical_Event__c eventRecord) {
      eventId = eventRecord.Id;
      eventName = eventRecord.Event_Name__c;
      startDateTime = eventRecord.Start_Date_Time__c;
      endDateTime = eventRecord.End_Date_Time__c;
      eventType = eventRecord.Event_Type__c;
      remainingSeats = eventRecord.Remaining_Seats__c;
      locationName = eventRecord.Event_Type__c == 'Virtual'
        ? 'Virtual Event'
        : eventRecord.Address__r != null ? eventRecord.Address__r.Name : null;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<EventListItem> getLiveUpcomingEvents(
    String searchTerm,
    Date startDate,
    String locationTerm
  ) {
    try {
      Datetime nowValue = System.now();
      String query =
        'SELECT Id, Event_Name__c, Start_Date_Time__c, End_Date_Time__c, Event_Type__c, ' +
        'Remaining_Seats__c, Address__r.Name, Address__r.City__c, Address__r.State__c ' +
        'FROM Medical_Event__c ' +
        'WHERE Live__c = true AND Start_Date_Time__c >= :nowValue';

      Map<String, Object> binds = new Map<String, Object>{
        'nowValue' => nowValue
      };

      if (startDate != null) {
        Datetime startDateTime = Datetime.newInstance(
          startDate,
          Time.newInstance(0, 0, 0, 0)
        );
        query += ' AND Start_Date_Time__c >= :startDateTime';
        binds.put('startDateTime', startDateTime);
      }

      if (String.isNotBlank(searchTerm)) {
        String searchPattern = '%' + searchTerm.trim() + '%';
        query += ' AND Event_Name__c LIKE :searchPattern';
        binds.put('searchPattern', searchPattern);
      }

      if (String.isNotBlank(locationTerm)) {
        String locationPattern = '%' + locationTerm.trim() + '%';
        query +=
          ' AND (Address__r.Name LIKE :locationPattern ' +
          'OR Address__r.City__c LIKE :locationPattern ' +
          'OR Address__r.State__c LIKE :locationPattern)';
        binds.put('locationPattern', locationPattern);
      }

      query += ' ORDER BY Start_Date_Time__c ASC LIMIT 200';

      List<EventListItem> results = new List<EventListItem>();
      for (
        SObject row : Database.queryWithBinds(
          query,
          binds,
          AccessLevel.USER_MODE
        )
      ) {
        results.add(new EventListItem((Medical_Event__c) row));
      }

      return results;
    } catch (Exception e) {
      ErrorLogService.logError(
        System.now(),
        e.getMessage() + ' - ' + e.getStackTraceString(),
        'EventListController'
      );
      throw new AuraHandledException('Nao foi possivel carregar os eventos.');
    }
  }
}
