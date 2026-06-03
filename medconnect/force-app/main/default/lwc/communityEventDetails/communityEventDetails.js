import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import getEventDetails from "@salesforce/apex/CommunityEventDetailsController.getEventDetails";
import registerAttendee from "@salesforce/apex/EventRegistrationController.registerAttendee";

const DATE_FORMAT = new Intl.DateTimeFormat("pt-BR", {
  day: "2-digit",
  month: "short",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit"
});

const SUCCESS_MESSAGE =
  "Inscricao realizada com sucesso! Verifique seu e-mail para a confirmacao.";

export default class CommunityEventDetails extends LightningElement {
  _recordId;

  @api
  get recordId() {
    return this._recordId;
  }

  set recordId(value) {
    this._recordId = value;
    this.loadEventDetails();
  }

  eventDetails;
  errorMessage;
  formError;
  successMessage;
  isLoading = true;
  isSubmitting = false;
  showRegistrationForm = false;

  form = {
    name: "",
    email: "",
    phone: "",
    companyInstitutionName: ""
  };

  @wire(CurrentPageReference)
  setCurrentPageReference(pageReference) {
    const urlRecordId =
      pageReference?.state?.recordId ||
      pageReference?.state?.c__recordId ||
      pageReference?.attributes?.recordId;

    if (!this._recordId && urlRecordId) {
      this._recordId = urlRecordId;
      this.loadEventDetails();
    }
  }

  connectedCallback() {
    if (!this._recordId) {
      this._recordId = this.getRecordIdFromUrl();
    }

    this.loadEventDetails();
  }

  get hasSpeakers() {
    return (this.eventDetails?.speakers || []).length > 0;
  }

  get eventTypeLabel() {
    return this.eventDetails?.eventType || "Evento";
  }

  get statusLabel() {
    return this.eventDetails?.status || "Publicado";
  }

  get organizerLabel() {
    return this.eventDetails?.organizerName || "Organizador a confirmar";
  }

  get locationLabel() {
    return this.eventDetails?.locationName || "Local a confirmar";
  }

  get verifiedLabel() {
    return this.eventDetails?.locationVerified ? "Sim" : "Nao";
  }

  get seatsLabel() {
    const remainingSeats = this.eventDetails?.remainingSeats;
    return remainingSeats || remainingSeats === 0
      ? `${remainingSeats} vagas`
      : "A confirmar";
  }

  get maxSeatsLabel() {
    const maxSeats = this.eventDetails?.maxSeats;
    return maxSeats || maxSeats === 0 ? `${maxSeats} vagas` : "A confirmar";
  }

  get periodLabel() {
    if (!this.eventDetails?.startDateTime) {
      return "Data a confirmar";
    }

    const startLabel = DATE_FORMAT.format(
      new Date(this.eventDetails.startDateTime)
    );

    if (!this.eventDetails.endDateTime) {
      return startLabel;
    }

    return `${startLabel} - ${DATE_FORMAT.format(
      new Date(this.eventDetails.endDateTime)
    )}`;
  }

  async loadEventDetails() {
    if (!this._recordId) {
      this.isLoading = false;
      this.errorMessage = "Evento nao informado.";
      return;
    }

    this.isLoading = true;
    this.errorMessage = undefined;

    try {
      this.eventDetails = await getEventDetails({ eventId: this._recordId });
    } catch (error) {
      this.eventDetails = undefined;
      this.errorMessage = this.normalizeError(error);
    } finally {
      this.isLoading = false;
    }
  }

  showForm() {
    this.showRegistrationForm = true;
    this.formError = undefined;
    this.successMessage = undefined;
  }

  handleInputChange(event) {
    this.form = {
      ...this.form,
      [event.target.name]: event.target.value
    };
  }

  async handleSubmit(event) {
    event.preventDefault();
    this.formError = undefined;
    this.successMessage = undefined;

    if (!this.isFormValid()) {
      return;
    }

    this.isSubmitting = true;

    try {
      await registerAttendee({
        medicalEventId: this._recordId,
        name: this.form.name.trim(),
        email: this.form.email.trim(),
        phone: this.form.phone.trim(),
        companyInstitutionName: this.form.companyInstitutionName.trim()
      });
      this.successMessage = SUCCESS_MESSAGE;
      this.form = {
        name: "",
        email: "",
        phone: "",
        companyInstitutionName: ""
      };
      await this.loadEventDetails();
    } catch (error) {
      this.formError = this.normalizeError(error);
    } finally {
      this.isSubmitting = false;
    }
  }

  isFormValid() {
    const requiredFields = ["name", "email"];
    const missingField = requiredFields.some(
      (fieldName) => !this.form[fieldName]?.trim()
    );

    if (missingField) {
      this.formError = "Preencha nome completo e e-mail.";
      return false;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.form.email.trim())) {
      this.formError = "Informe um e-mail valido.";
      return false;
    }

    return true;
  }

  getRecordIdFromUrl() {
    const params = new URLSearchParams(window.location.search);
    return params.get("recordId") || params.get("c__recordId");
  }

  normalizeError(error) {
    return (
      error?.body?.message ||
      error?.message ||
      "Ocorreu um erro inesperado. Tente novamente."
    );
  }
}
