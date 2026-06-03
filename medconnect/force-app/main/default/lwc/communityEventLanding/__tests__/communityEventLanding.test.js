import { createElement } from "@lwc/engine-dom";
import CommunityEventLanding from "c/communityEventLanding";
import getUpcomingEvents from "@salesforce/apex/CommunityEventLandingController.getUpcomingEvents";

jest.mock(
  "@salesforce/apex/CommunityEventLandingController.getUpcomingEvents",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-community-event-landing", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders upcoming event cards", async () => {
    getUpcomingEvents.mockResolvedValue([
      {
        eventId: "a01000000000001AAA",
        eventName: "Congresso de Cardiologia",
        startDateTime: "2026-06-01T10:00:00.000Z",
        endDateTime: "2026-06-02T12:00:00.000Z",
        eventType: "In-Person",
        status: "Published",
        locationLabel: "Centro Medico Recife - Recife, PE",
        description: "Programacao cientifica para cardiologistas."
      }
    ]);

    const element = createElement("c-community-event-landing", {
      is: CommunityEventLanding
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "Central de Informações Científicas"
    );
    expect(element.shadowRoot.textContent).toContain(
      "Congresso de Cardiologia"
    );
    expect(element.shadowRoot.querySelectorAll(".event-card")).toHaveLength(1);
  });

  it("renders empty state", async () => {
    getUpcomingEvents.mockResolvedValue([]);

    const element = createElement("c-community-event-landing", {
      is: CommunityEventLanding
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "Nenhum evento programado foi encontrado no momento."
    );
  });
});
