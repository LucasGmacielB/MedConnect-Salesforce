import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getEventsByAttendee from "@salesforce/apex/AttendeeEventsController.getEventsByAttendee";

const COLUMNS = [
  {
    label: "Event Name",
    fieldName: "eventName",
    type: "button",
    typeAttributes: {
      label: { fieldName: "eventName" },
      name: "view_event",
      variant: "base"
    }
  },
  { label: "Start", fieldName: "startDateTime", type: "date" },
  { label: "End", fieldName: "endDateTime", type: "date" },
  { label: "Status", fieldName: "status" },
  { label: "Type", fieldName: "eventType" },
  { label: "Location", fieldName: "locationName" }
];

export default class AttendeeEvents extends NavigationMixin(LightningElement) {
  columns = COLUMNS;
  activeSections = ["upcoming"];
  upcomingEvents = [];
  pastEvents = [];
  loading = true;
  _recordId;

  @api
  get recordId() {
    return this._recordId;
  }

  set recordId(value) {
    this._recordId = value;
    if (value) {
      this.loadEvents();
    }
  }

  connectedCallback() {
    if (this.recordId) {
      this.loadEvents();
    }
  }

  get hasUpcomingEvents() {
    return this.upcomingEvents.length > 0;
  }

  get hasPastEvents() {
    return this.pastEvents.length > 0;
  }

  get upcomingLabel() {
    return `Upcoming Events (${this.upcomingEvents.length})`;
  }

  get pastLabel() {
    return `Past Events (${this.pastEvents.length})`;
  }

  async loadEvents() {
    this.loading = true;

    try {
      const data = await getEventsByAttendee({
        attendeeId: this.recordId
      });

      this.upcomingEvents = data?.upcomingEvents || [];
      this.pastEvents = data?.pastEvents || [];
    } catch (error) {
      this.upcomingEvents = [];
      this.pastEvents = [];
      this.error = error;
    } finally {
      this.loading = false;
    }
  }

  handleRowAction(event) {
    if (event.detail.action.name !== "view_event") {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.detail.row.eventId,
        objectApiName: "Medical_Event__c",
        actionName: "view"
      }
    });
  }
}
