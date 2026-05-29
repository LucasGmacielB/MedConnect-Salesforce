import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getUpcomingEvents from "@salesforce/apex/CommunityEventLandingController.getUpcomingEvents";

const DATE_FORMAT = new Intl.DateTimeFormat("pt-BR", {
  day: "2-digit",
  month: "short",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit"
});

export default class CommunityEventLanding extends NavigationMixin(
  LightningElement
) {
  events = [];
  loading = true;
  error;

  connectedCallback() {
    this.loadEvents();
  }

  get hasEvents() {
    return this.events.length > 0;
  }

  async loadEvents() {
    this.loading = true;

    try {
      const data = await getUpcomingEvents();
      this.events = (data || []).map((event) => ({
        ...event,
        eventType: event.eventType || "Evento",
        status: event.status || "Publicado",
        description:
          event.description ||
          "Confira a programacao cientifica e as informacoes gerais deste evento.",
        locationLabel: event.locationLabel || "Local a confirmar",
        periodLabel: this.formatPeriod(
          event.startDateTime,
          event.endDateTime
        )
      }));
      this.error = undefined;
    } catch (error) {
      this.events = [];
      this.error = error;
    } finally {
      this.loading = false;
    }
  }

  formatPeriod(startDateTime, endDateTime) {
    if (!startDateTime) {
      return "Data a confirmar";
    }

    const startLabel = DATE_FORMAT.format(new Date(startDateTime));

    if (!endDateTime) {
      return startLabel;
    }

    return `${startLabel} - ${DATE_FORMAT.format(new Date(endDateTime))}`;
  }

  handleCardClick(event) {
    const recordId = event.currentTarget.dataset.id;

    if (!recordId) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId,
        objectApiName: "Medical_Event__c",
        actionName: "view"
      }
    });
  }
}
