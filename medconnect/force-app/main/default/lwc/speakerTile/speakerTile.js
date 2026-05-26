import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Speaker__c.Name";
import PROFILE_URL_FIELD from "@salesforce/schema/Speaker__c.Profile_URL__c";
import SPECIALIZATION_FIELD from "@salesforce/schema/Speaker__c.Specialization__c";
import ABOUT_ME_FIELD from "@salesforce/schema/Speaker__c.About_Me__c";

const FIELDS = [
  NAME_FIELD,
  PROFILE_URL_FIELD,
  SPECIALIZATION_FIELD,
  ABOUT_ME_FIELD
];

export default class SpeakerTile extends LightningElement {
  @api recordId;
  speaker;
  error;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredSpeaker({ data, error }) {
    this.speaker = data;
    this.error = error;
  }

  get name() {
    return getFieldValue(this.speaker, NAME_FIELD);
  }

  get profileUrl() {
    return getFieldValue(this.speaker, PROFILE_URL_FIELD);
  }

  get specialization() {
    return getFieldValue(this.speaker, SPECIALIZATION_FIELD);
  }

  get aboutMe() {
    return getFieldValue(this.speaker, ABOUT_ME_FIELD);
  }
}
