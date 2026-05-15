import getEventRelatedDetails
from '@salesforce/apex/EventDetailsController.getEventRelatedDetails';

export async function getEventDetails(eventId) {

    return await getEventRelatedDetails({
        eventId
    });
}