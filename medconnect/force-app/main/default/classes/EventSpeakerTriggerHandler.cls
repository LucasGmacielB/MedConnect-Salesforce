public class EventSpeakerTriggerHandler {

    public static void preventDuplicateActiveSpeakerBooking(List<Event_Speaker__c> newRecords, Map<Id, Event_Speaker__c> oldMap) {
        Set<Id> speakerIds = new Set<Id>();

        for (Event_Speaker__c eventSpeaker : newRecords) {
            if (eventSpeaker.Speaker__c != null) {
                speakerIds.add(eventSpeaker.Speaker__c);
            }
        }

        if (speakerIds.isEmpty()) {
            return;
        }

        List<Event_Speaker__c> existingBookings = [
            SELECT Id, Speaker__c, Medical_Event__c,
                   Medical_Event__r.Live__c,
                   Medical_Event__r.End_Date_Time__c
            FROM Event_Speaker__c
            WHERE Speaker__c IN :speakerIds
            AND Medical_Event__r.Live__c = TRUE
            AND Medical_Event__r.End_Date_Time__c >= :System.now()
        ];

        Map<Id, Event_Speaker__c> activeBookingBySpeaker = new Map<Id, Event_Speaker__c>();

        for (Event_Speaker__c booking : existingBookings) {
            activeBookingBySpeaker.put(booking.Speaker__c, booking);
        }

        for (Event_Speaker__c eventSpeaker : newRecords) {
            if (eventSpeaker.Speaker__c == null) {
                continue;
            }

            if (activeBookingBySpeaker.containsKey(eventSpeaker.Speaker__c)) {
                Event_Speaker__c existingBooking = activeBookingBySpeaker.get(eventSpeaker.Speaker__c);

                if (eventSpeaker.Id == null || eventSpeaker.Id != existingBooking.Id) {
                    eventSpeaker.addError(
                        'Essa pessoa está inscrita em outro evento no mesmo horário.'
                    );
                }
            }
        }
    }
}