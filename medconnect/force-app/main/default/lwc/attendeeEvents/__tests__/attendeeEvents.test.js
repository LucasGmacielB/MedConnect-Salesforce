import { createElement } from "@lwc/engine-dom";
import AttendeeEvents from "c/attendeeEvents";
import getEventsByAttendee from "@salesforce/apex/AttendeeEventsController.getEventsByAttendee";

jest.mock(
  "@salesforce/apex/AttendeeEventsController.getEventsByAttendee",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-attendee-events", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders upcoming and past event tables", async () => {
    getEventsByAttendee.mockResolvedValue({
      upcomingEvents: [
        {
          eventId: "a01000000000001AAA",
          eventName: "Upcoming Event"
        }
      ],
      pastEvents: [
        {
          eventId: "a01000000000002AAA",
          eventName: "Past Event"
        }
      ]
    });

    const element = createElement("c-attendee-events", {
      is: AttendeeEvents
    });
    element.recordId = "a02000000000001AAA";
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const datatables = element.shadowRoot.querySelectorAll(
      "lightning-datatable"
    );
    expect(datatables).toHaveLength(2);
    expect(datatables[0].data[0].eventName).toBe("Upcoming Event");
    expect(datatables[1].data[0].eventName).toBe("Past Event");
  });

  it("renders empty states", async () => {
    getEventsByAttendee.mockResolvedValue({
      upcomingEvents: [],
      pastEvents: []
    });

    const element = createElement("c-attendee-events", {
      is: AttendeeEvents
    });
    element.recordId = "a02000000000001AAA";
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain("No upcoming events.");
    expect(element.shadowRoot.textContent).toContain("No past events.");
  });
});
