import { createElement } from "@lwc/engine-dom";
import EventDetails from "c/eventDetails";
import getEventRelatedDetails from "@salesforce/apex/EventDetailsController.getEventRelatedDetails";

jest.mock(
  "@salesforce/apex/EventDetailsController.getEventRelatedDetails",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-event-details", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("loads data and renders creation buttons", async () => {
    getEventRelatedDetails.mockResolvedValue({
      speakers: [
        {
          Id: "a03000000000001AAA",
          Name: "Speaker",
          Specialization__c: "Cardiology"
        }
      ],
      attendees: [
        {
          Id: "a04000000000001AAA",
          Name: "Attendee"
        }
      ],
      location: {
        Name: "Main Clinic",
        Street__c: "Main Street"
      }
    });

    const element = createElement("c-event-details", {
      is: EventDetails
    });
    element.recordId = "a01000000000001AAA";

    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(getEventRelatedDetails).toHaveBeenCalledWith({
      eventId: "a01000000000001AAA"
    });

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    expect(buttons).toHaveLength(2);
    expect(buttons[0].label).toBe("New Speaker");
    expect(buttons[1].label).toBe("New Attendee");
  });
});
