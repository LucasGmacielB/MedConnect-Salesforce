import { LightningElement, api } from 'lwc';

import { getEventDetails }
from './eventDetailsService';

export default class EventDetails extends LightningElement {

    @api recordId;

    speakers = [];
    attendees = [];
    location;

    loading = true;
    error;

    speakerColumns = [
        {
            label: 'Name',
            fieldName: 'Name'
        },
        {
            label: 'Email',
            fieldName: 'Email__c'
        },
        {
            label: 'Phone',
            fieldName: 'Phone__c'
        },
        {
            label: 'Specialisation',
            fieldName: 'Specialisation__c'
        }
    ];

    attendeeColumns = [
        {
            label: 'Name',
            fieldName: 'Name'
        },
        {
            label: 'Email',
            fieldName: 'Email__c'
        },
        {
            label: 'Phone',
            fieldName: 'Phone__c'
        },
        {
            label: 'Company',
            fieldName: 'Company_Institution_Name__c'
        }
    ];

    connectedCallback() {

        this.loadEventDetails();
    }

    async loadEventDetails() {

        try {

            this.loading = true;

            const data =
                await getEventDetails(this.recordId);

            this.speakers =
                data.speakers || [];

            this.attendees =
                data.attendees || [];

            this.location =
                data.location;

        } catch(error){

            console.error(error);

            this.error = error;

        } finally {

            this.loading = false;
        }
    }
}