import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getLiveUpcomingEvents from "@salesforce/apex/EventListController.getLiveUpcomingEvents";

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
  { label: "Type", fieldName: "eventType" },
  { label: "Remaining Seats", fieldName: "remainingSeats", type: "number" },
  { label: "Location", fieldName: "locationName" }
];

export default class EventList extends NavigationMixin(LightningElement) {
  columns = COLUMNS;
  events = [];
  loading = true;
  searchTerm = "";
  startDate;
  locationTerm = "";

  connectedCallback() {
    this.loadEvents();
  }

  get hasEvents() {
    return this.events.length > 0;
  }

  handleSearchChange(event) {
    this.searchTerm = event.target.value;
    this.loadEvents();
  }

  handleStartDateChange(event) {
    this.startDate = event.target.value;
    this.loadEvents();
  }

  handleLocationChange(event) {
    this.locationTerm = event.target.value;
    this.loadEvents();
  }

  async loadEvents() {
    this.loading = true;

    try {
      this.events = await getLiveUpcomingEvents({
        searchTerm: this.searchTerm,
        startDate: this.startDate || null,
        locationTerm: this.locationTerm
      });
    } catch (error) {
      this.events = [];
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
