import { getRecord } from "lightning/uiRecordApi";
import { LightningElement, api, wire } from "lwc";
import saveCustomer from "@salesforce/apex/Zealynx.saveCustomer";
import savePaymentMethod from "@salesforce/apex/Zealynx.savePaymentMethod";
import saveRecord from "@salesforce/apex/LWC.saveRecord";

const FIELDS = [
  "Contact.MX_Customer_Id__c",
  "Contact.FirstName",
  "Contact.LastName",
  "Contact.MailingStreet",
  "Contact.MailingCity",
  "Contact.MailingState",
  "Contact.MailingPostalCode",
  "Contact.MailingCountry"
];
export default class PaymentMethodForm extends LightningElement {
  @api recordId;
  @api paymentMethodId;
  @api merchantToken;
  @api externalId;
  localDefaultMonth = null;
  localDefaultYear = null;
  record;
  showForm = false;
  disableButton = false;
  showtoast = false;
  toast = {
    variant: "",
    title: "",
    message: ""
  };
  localDefaultState = null;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (error) {
      console.error(error);
    } else if (data) {
      const localRecord = {};

      for (const [key, value] of Object.entries(data.fields)) {
        localRecord[key] = value.value;
      }
      console.log(localRecord);
      this.localDefaultState = localRecord.MailingState;
      this.record = localRecord;
      this.showForm = true;
    }
  }

  luhnCheck = (val) => {
    let checksum = 0; // running checksum total
    let j = 1; // takes value of 1 or 2

    // Process each digit one by one starting from the last
    for (let i = val.length - 1; i >= 0; i--) {
      let calc = 0;
      // Extract the next digit and multiply by 1 or 2 on alternative digits.
      calc = Number(val.charAt(i)) * j;

      // If the result is in two digits add 1 to the checksum total
      if (calc > 9) {
        checksum = checksum + 1;
        calc = calc - 10;
      }

      // Add the units element to the checksum total
      checksum = checksum + calc;

      // Switch the value of j
      if (j == 1) {
        j = 2;
      } else {
        j = 1;
      }
    }

    //Check if it is divisible by 10 or not.
    return checksum % 10 == 0;
  };

  validateCardNumber = (number) => {
    //Check if the number contains only numeric value
    //and is of between 13 to 19 digits
    const regex = new RegExp("^[0-9]{13,19}$");
    if (!regex.test(number)) {
      return false;
    }

    return this.luhnCheck(number);
  };

  async handleZealynxSavePaymentMethod(record) {
    const CreditCardResource = {
      customerId: parseInt(this.record.MX_Customer_Id__c),
      ...(this.merchantToken && { token: this.merchantToken }), 
      ...(this.externalId && { id: parseInt(this.externalId) }),
      isDefault: record.Default__c,
      expiryMonth: "" + record.expiryMonth,
      expiryYear: "" + record.expiryYear,
      name: record.Billing_First_Name__c + " " + record.Billing_Last_Name__c,
      avsStreet: "" + record.Billing_Street__c,
      avsZip: "" + record.Billing_Postal_Code__c,
      ...(this.isNew && { REPLACE_number: "" + record.cardNumber }),
      ...(this.isNew && {
        alias:
          record.Billing_First_Name__c +
          " " +
          record.Billing_Last_Name__c +
          " " +
          record.Card_Type__c
      }),
      ...(record.cvv && { cvv: "" + record.cvv })
    };
    console.log(CreditCardResource);

    try {
      const res = await savePaymentMethod({ creditCard: CreditCardResource });
      console.log(res);

      return res.creditCard;
    } catch (err) {
      console.error(err);
      throw new Error(err);
    }
  }

  async handleSaveCustomer() {
    const contactRecord = { ...this.record };

    const CustomerResource = {
      name: contactRecord.FirstName + " " + contactRecord.LastName,
      firstName: contactRecord.FirstName,
      lastName: contactRecord.LastName,
      REPLACE_number: this.recordId,
      address1: contactRecord.MailingStreet,
      address2: "",
      city: contactRecord.MailingCity,
      state: contactRecord.MailingState,
      zip: contactRecord.MailingPostalCode,
      customerType: "Business"
    };
    console.log(CustomerResource);
    const res = await saveCustomer({ customer: CustomerResource });
    console.log(res);
    if (!res.isSuccess) {
      if (res.errorMessage && res.errorCode) {
        console.error(res.errorCode + " : " + res.errorMessage);
        return;
      }
    }

    const updatedContact = {
      sobjectType: "Contact",
      MX_Customer_Id__c: res.customer.id + "",
      Id: this.recordId
    };

    try {
      const savedContact = await saveRecord({ record: updatedContact });
      console.log("savedContact", savedContact);
      this.record = {
        ...this.record,
        MX_Customer_Id__c: updatedContact.MX_Customer_Id__c
      };
    } catch (err) {
      console.error(err);
    }
  }

  setDate(y, m) {
    return new Date(y, m, 0).getDate();
  }

  async handleSubmit(evt) {
    evt.preventDefault();
    let fields = { ...evt.detail.fields };
    const customInputs = this.template.querySelectorAll(
      '[data-type="customInput"]'
    );
    let customRecords = {
      expiryMonth: "",
      expiryYear: "",
      cardNumber: "",
      cvv: "",
      billingState: ""
    };

    for (let i = 0; i < customInputs.length; i++) {
      const inp = customInputs[i];
      const fld = inp.getAttribute("data-field");
      const val = inp.value;

      inp.reportValidity();
      if (!inp.checkValidity()) {
        return;
      }

      if (fld == "cardNumber") {
        if (!this.validateCardNumber(val)) {
          inp.setCustomValidity("Invalid Card Number");
          inp.reportValidity();
          inp.focus();
          return;
        } else {
          inp.setCustomValidity("");
        }
      }

      customRecords[fld] = val;
    }

    this.disableButton = true;

    if (!this.record.MX_Customer_Id__c) {
      try {
        await this.handleSaveCustomer();
      } catch (err) {
        console.error(err);
      }
    }

    try {
      const cardData = await this.handleZealynxSavePaymentMethod({
        ...fields,
        ...customRecords
      });
      if (this.isNew) {
        fields.ExternalId__c = "" + cardData.id;
        fields.Merchant_Token__c = "" + cardData.token;
        fields.Billing_State__c = customRecords.billingState;
        fields.Last_4_Digits_of_Card__c = customRecords.cardNumber.slice(-4);
      }
      const expDate = new Date(
        customRecords.expiryMonth +
          "-" +
          this.setDate(customRecords.expiryYear, customRecords.expiryMonth) +
          "-" +
          customRecords.expiryYear
      );
      const expDateString =
        expDate.getFullYear() +
        "-" +
        (expDate.getMonth() + 1) +
        "-" +
        expDate.getDate();
      fields.Expiration_Date__c = expDateString;
      fields.Billing_Name__c =
        fields.Billing_First_Name__c + " " + fields.Billing_Last_Name__c;
      console.log(fields);
      console.log('on saving to salesforce db');
      this.template.querySelector("lightning-record-edit-form").submit(fields);
    } catch (err) {
      console.error(err);
    }
  }

  handleSuccess(evt) {
    const alertMessage = this.isNew
      ? "You have successfully added a payment method to this contact. You will now be redirected back to the contact record."
      : "You have successfully updated this payment method. You will now be redirected back to the record.";
    alert(alertMessage);

    const url = "/" + (this.isNew ? this.recordId : this.paymentMethodId);

    location.replace(url);
  }


  handleBack() {
    const url = "/" + (this.isNew ? this.recordId : this.paymentMethodId);

    location.replace(url);
  }

  handleCloseToast() {
    this.showtoast = false;
  }

  get monthOptions() {
    let options = [];
    for (let i = 1; i < 13; i++) {
      let n = "" + i;
      if (n.length === 1) {
        n = "0" + i;
      }
      options.push({ label: n, value: n });
    }
    return options;
  }

  get yearOptions() {
    let options = [];
    for (let i = 1; i < 6; i++) {
      let y = new Date().getFullYear() + i;
      options.push({ label: "" + y, value: "" + y });
    }
    return options;
  }

  get stateOptions() {
    return [
      { label: "AL", value: "AL" },
      { label: "AK", value: "AK" },
      { label: "AS", value: "AS" },
      { label: "AZ", value: "AZ" },
      { label: "AR", value: "AR" },
      { label: "CA", value: "CA" },
      { label: "CO", value: "CO" },
      { label: "CT", value: "CT" },
      { label: "DE", value: "DE" },
      { label: "DC", value: "DC" },
      { label: "FM", value: "FM" },
      { label: "FL", value: "FL" },
      { label: "GA", value: "GA" },
      { label: "GU", value: "GU" },
      { label: "HI", value: "HI" },
      { label: "ID", value: "ID" },
      { label: "IL", value: "IL" },
      { label: "IN", value: "IN" },
      { label: "IA", value: "IA" },
      { label: "KS", value: "KS" },
      { label: "KY", value: "KY" },
      { label: "LA", value: "LA" },
      { label: "ME", value: "ME" },
      { label: "MH", value: "MH" },
      { label: "MD", value: "MD" },
      { label: "MA", value: "MA" },
      { label: "MI", value: "MI" },
      { label: "MN", value: "MN" },
      { label: "MS", value: "MS" },
      { label: "MO", value: "MO" },
      { label: "MT", value: "MT" },
      { label: "NE", value: "NE" },
      { label: "NV", value: "NV" },
      { label: "NH", value: "NH" },
      { label: "NJ", value: "NJ" },
      { label: "NM", value: "NM" },
      { label: "NY", value: "NY" },
      { label: "NC", value: "NC" },
      { label: "ND", value: "ND" },
      { label: "MP", value: "MP" },
      { label: "OH", value: "OH" },
      { label: "OK", value: "OK" },
      { label: "OR", value: "OR" },
      { label: "PW", value: "PW" },
      { label: "PA", value: "PA" },
      { label: "PR", value: "PR" },
      { label: "RI", value: "RI" },
      { label: "SC", value: "SC" },
      { label: "SD", value: "SD" },
      { label: "TN", value: "TN" },
      { label: "TX", value: "TX" },
      { label: "UT", value: "UT" },
      { label: "VT", value: "VT" },
      { label: "VI", value: "VI" },
      { label: "VA", value: "VA" },
      { label: "WA", value: "WA" },
      { label: "WV", value: "WV" },
      { label: "WI", value: "WI" },
      { label: "WY", value: "WY" }
    ];
  }

  get pageTitle() {
    return this.paymentMethodId ? "Edit Payment Method" : "New Payment Method";
  }

  get isNew() {
    return !this.paymentMethodId;
  }

  @api
  get defaultMonth() {
    return this.localDefaultMonth;
  }

  set defaultMonth(val) {
    this.localDefaultMonth = val.length < 2 ? "0" + val : val;
  }

  @api
  get defaultYear() {
    return this.localDefaultYear;
  }

  set defaultYear(val) {
    this.localDefaultYear = val;
  }

  @api
  get defaultState() {
    return this.localDefaultState;
  }

  set defaultState(val) {
    this.localDefaultState = val;
  }
}