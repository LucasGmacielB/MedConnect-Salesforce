import { createElement } from "@lwc/engine-dom";
import CommunityEventDetails from "c/communityEventDetails";
import getEventDetails from "@salesforce/apex/CommunityEventDetailsController.getEventDetails";
import registerAttendee from "@salesforce/apex/EventRegistrationController.registerAttendee";

jest.mock(
  "@salesforce/apex/CommunityEventDetailsController.getEventDetails",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/EventRegistrationController.registerAttendee",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const EVENT_DETAILS = {
  eventId: "a01000000000001AAA",
  eventName: "Congresso de Cardiologia",
  startDateTime: "2026-06-01T10:00:00.000Z",
  endDateTime: "2026-06-02T12:00:00.000Z",
  status: "Published",
  eventType: "In-Person",
  remainingSeats: 12,
  maxSeats: 150,
  organizerName: "MedConnect Eventos",
  locationName: "Centro Medico Recife",
  addressText: "Rua Principal, Recife, PE",
  locationVerified: true,
  speakers: [
    {
      speakerId: "a02000000000001AAA",
      name: "Dra Ana Lima",
      specialization: "Cardiologia",
      profileUrl: "https://example.com/ana",
      aboutMe: "Pesquisadora em cardiologia clinica."
    }
  ]
};

const flushPromises = () => Promise.resolve();

describe("c-community-event-details", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders event details", async () => {
    const element = createComponent();

    await flushPromises();
    await flushPromises();

    expect(getEventDetails).toHaveBeenCalledWith({
      eventId: "a01000000000001AAA"
    });
    expect(element.shadowRoot.textContent).toContain("Congresso de Cardiologia");
    expect(element.shadowRoot.textContent).toContain("Centro Medico Recife");
    expect(element.shadowRoot.textContent).toContain("12 vagas");
  });

  it("renders speakers", async () => {
    const element = createComponent();

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".speaker-card")).toHaveLength(1);
    expect(element.shadowRoot.textContent).toContain("Dra Ana Lima");
    expect(element.shadowRoot.textContent).toContain("Cardiologia");
  });

  it("opens registration form and submits attendee", async () => {
    registerAttendee.mockResolvedValue("a03000000000001AAA");
    const element = createComponent();

    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".register-button").click();
    await flushPromises();

    setInputValue(element, "name", "Maria Silva");
    setInputValue(element, "email", "maria@example.com");
    setInputValue(element, "phone", "81999990001");
    setInputValue(element, "companyInstitutionName", "Hospital Recife");

    element.shadowRoot
      .querySelector("form")
      .dispatchEvent(new CustomEvent("submit"));

    await flushPromises();
    await flushPromises();
    await flushPromises();

    expect(registerAttendee).toHaveBeenCalledWith({
      medicalEventId: "a01000000000001AAA",
      name: "Maria Silva",
      email: "maria@example.com",
      phone: "81999990001",
      companyInstitutionName: "Hospital Recife"
    });
    expect(element.shadowRoot.textContent).toContain(
      "Inscricao realizada com sucesso!"
    );
  });

  it("shows friendly error when registration fails", async () => {
    registerAttendee.mockRejectedValue({
      body: {
        message: "Este evento nao possui vagas disponiveis."
      }
    });
    const element = createComponent();

    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".register-button").click();
    await flushPromises();

    setInputValue(element, "name", "Maria Silva");
    setInputValue(element, "email", "maria@example.com");
    element.shadowRoot
      .querySelector("form")
      .dispatchEvent(new CustomEvent("submit"));

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "Este evento nao possui vagas disponiveis."
    );
  });
});

function createComponent() {
  getEventDetails.mockResolvedValue(EVENT_DETAILS);

  const element = createElement("c-community-event-details", {
    is: CommunityEventDetails
  });
  element.recordId = "a01000000000001AAA";
  document.body.appendChild(element);
  return element;
}

function setInputValue(element, name, value) {
  const input = element.shadowRoot.querySelector(`input[name="${name}"]`);
  input.value = value;
  input.dispatchEvent(new CustomEvent("input"));
}
