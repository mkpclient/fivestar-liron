import { api, LightningElement, track } from "lwc";

export default class ManualPaymentForm extends LightningElement {
  @api soName;
  @api recordId;
  @api accountId;
  @api contactId;
  @api netDue;
  @api soStatus;
  @track showtoast = false;
  @track toast = {
    variant: "",
    title: "",
    message: ""
  };
  showForm = true;

  connectedCallback() {
    if (
      this.soStatus &&
      !["Released", "Unreleased", "Approved"].includes(this.soStatus)
    ) {
      this.showForm = false;
      alert("Unable to make payments on unapproved sales orders.");
      window.location.replace("/" + this.recordId);
      return;
    }
  }

  get defaultPaymentName() {
    let defaultName = "";
    if (this.soName) {
      defaultName = "Payment for " + this.soName;
    }
    return defaultName;
  }

  handleSubmit() {
    const requiredFields = this.template.querySelectorAll(
      "lightning-input-field[data-name='required']"
    );
    for (let i = 0; i < requiredFields.length; i++) {
      const rf = requiredFields[i];
      if (!rf.value) {
        rf.reportValidity();
        rf.focus();
        return;
      }
    }

    this.template.querySelector("lightning-record-edit-form").submit();
  }

  handleBack() {
    window.location.href = "/" + this.recordId;
  }

  handleSuccess(evt) {
    this.showForm = false;
    const newToast = {
      variant: "success",
      title: "Success",
      message:
        "Payment created successfully. Redirecting you to the new payment's page."
    };
    this.toast = newToast;
    this.showtoast = true;
    location.replace("/" + evt.detail.id);
  }

  handleCloseToast() {
    this.showtoast = false;
  }
}