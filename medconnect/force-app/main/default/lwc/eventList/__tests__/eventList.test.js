import { createElement } from "@lwc/engine-dom";
import EventList from "c/eventList";
import getLiveUpcomingEvents from "@salesforce/apex/EventListController.getLiveUpcomingEvents";

jest.mock(
  "@salesforce/apex/EventListController.getLiveUpcomingEvents",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-event-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders loaded events", async () => {
    getLiveUpcomingEvents.mockResolvedValue([
      {
        eventId: "a01000000000001AAA",
        eventName: "Cardiology Summit",
        startDateTime: "2026-06-01T10:00:00.000Z",
        endDateTime: "2026-06-02T10:00:00.000Z",
        eventType: "In-Person",
        remainingSeats: 10,
        locationName: "Main Clinic"
      }
    ]);

    const element = createElement("c-event-list", {
      is: EventList
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.data).toHaveLength(1);
    expect(datatable.data[0].eventName).toBe("Cardiology Summit");
  });

  it("renders empty state", async () => {
    getLiveUpcomingEvents.mockResolvedValue([]);

    const element = createElement("c-event-list", {
      is: EventList
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "No upcoming events found."
    );
  });
});
