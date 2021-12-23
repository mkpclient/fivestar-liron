import doQuery from "@salesforce/apex/LWC.doQuery";
import saveRecord from "@salesforce/apex/LWC.saveRecord";
import makePayment from "@salesforce/apex/Zealynx.makePayment";
import saveCustomer from "@salesforce/apex/Zealynx.saveCustomer";
import savePaymentMethod from "@salesforce/apex/Zealynx.savePaymentMethod";
import { getRecord } from "lightning/uiRecordApi";
import { api, LightningElement, wire } from "lwc";

export default class PublicPaymentTerminal extends LightningElement {
  isProcessing = false;
  isSuccess = false;
  soName;
  @api orderId;
  isReview = false;
  accountId;
  contactId;
  errorMessage = "";
  logoUrl =
    "https://fivestarprofessional--c.na169.content.force.com/servlet/servlet.ImageServer?id=015d00000060AVl&oid=00Dd0000000gsfl";
  paymentAmount;
  paymentEntry = {
    FirstName: "",
    LastName: "",
    MailingStreet: "",
    MailingCity: "",
    MailingState: "",
    MailingPostalCode: "",
    MailingCountry: "",
    CardType: "",
    CardNumber: "",
    SecurityCode: "",
    ExpiryYear: "",
    ExpiryMonth: "",
    MX_Customer_Id__c: "Unavailable"
  };
  contactRecord = {};
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
      { label: "WY", value: "WY" },
      { label: "Other", value: "Other" }
    ];
  }

  get cardOptions() {
    return [
      { label: "Visa", value: "Visa" },
      { label: "Mastercard", value: "Mastercard" },
      { label: "Amex", value: "Amex" },
      { label: "Discover", value: "Discover" }
    ];
  }

  get monthOptions() {
    return [
      { label: "Jan", value: "01" },
      { label: "Feb", value: "02" },
      { label: "Mar", value: "03" },
      { label: "Apr", value: "04" },
      { label: "May", value: "05" },
      { label: "Jun", value: "06" },
      { label: "Jul", value: "07" },
      { label: "Aug", value: "08" },
      { label: "Sep", value: "09" },
      { label: "Oct", value: "10" },
      { label: "Nov", value: "11" },
      { label: "Dec", value: "12" }
    ];
  }

  get yearOptions() {
    const yearValues = [];
    for (let i = 0; i <= 10; i++) {
      yearValues.push({
        label: new Date().getFullYear() + i,
        value: ("" + new Date().getFullYear() + i).slice(-2)
      });
    }

    return yearValues;
  }

  async connectedCallback() {
    if(this.orderId) {
      try {

        let query = "SELECT Id, Name, Account__c, BalanceDueAmount__c, ContactBilling__c, " +
        "ContactBilling__r.FirstName, ContactBilling__r.LastName, " +
        "ContactBilling__r.MailingStreet, ContactBilling__r.MailingCity, " +
        "ContactBilling__r.MailingState, ContactBilling__r.MailingPostalCode, " +
        "ContactBilling__r.MailingCountry, ContactBilling__r.MX_Customer_Id__c " + 
        "FROM SalesOrder__c WHERE Id = '" + this.orderId + "'";
        

        const record = await doQuery({ queryString: query});

        this.paymentAmount = record[0].BalanceDueAmount__c;
        this.contactId = record[0].ContactBilling__c;
        this.accountId = record[0].Account__c;
        this.soName = record[0].Name;

        for(const [key, value] of Object.entries(record[0].ContactBilling__r)) {
            this.contactRecord[key] = value;
            this.paymentEntry[key] = value;
        }

      } catch(err) {
        console.error(err);
        this.errorMessage =
        "Error loading page. We apologize for the inconvenience.";
      }
    }
  }

  // @wire(getRecord, {
  //   recordId: "$orderId",
  //   fields: [
  //     "SalesOrder__c.Account__c",
  //     "SalesOrder__c.BalanceDueAmount__c",
  //     "SalesOrder__c.ContactBilling__c",
  //     "SalesOrder__c.ContactBilling__r.FirstName",
  //     "SalesOrder__c.ContactBilling__r.LastName",
  //     "SalesOrder__c.ContactBilling__r.MailingStreet",
  //     "SalesOrder__c.ContactBilling__r.MailingCity",
  //     "SalesOrder__c.ContactBilling__r.MailingState",
  //     "SalesOrder__c.ContactBilling__r.MailingPostalCode",
  //     "SalesOrder__c.ContactBilling__r.MailingCountry",
  //     "SalesOrder__c.ContactBilling__r.MX_Customer_Id__c"
  //   ]
  // })
  // wiredRecord({ error, data }) {
  //   if (error) {
  //     console.error(error);
  //   } else if (data) {
  //     this.paymentAmount = data.fields.Net_Due__c.value;
  //     this.contactId = data.fields.ContactBilling__c.value;
  //     this.accountId = data.fields.Account__c.value;
  //     for (const [key, value] of Object.entries(data.fields)) {
  //       if (key[key.length - 1] != "r") {
  //       } else if (value.value.hasOwnProperty("fields")) {
  //         for (const [childKey, childValue] of Object.entries(
  //           value.value.fields
  //         )) {
  //           this.paymentEntry[childKey] = childValue.value;
  //           this.contactRecord[childKey] = childValue.value;
  //         }
  //       }
  //     }
  //   }
  // }

  handleChange(evt) {
    this.paymentEntry[evt.target.dataset.name] = evt.target.value;
  }

  setDate() {
    return new Date(
      this.paymentEntry.ExpiryYear,
      this.paymentEntry.ExpiryMonth,
      0
    ).getDate();
  }

  async handleSaveCustomer() {
    const contactRecord = { ...this.contactRecord };
    const CustomerResource = {
      name: contactRecord.FirstName + " " + contactRecord.FirstName,
      firstName: contactRecord.FirstName,
      lastName: contactRecord.FirstName,
      REPLACE_number: this.contactId,
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
      Id: this.contactId
    };
    const savedContact = await saveRecord({ record: updatedContact });
    console.log("savedContact", savedContact);
    return savedContact;
  }

  async handleSavePaymentMethod() {
    const CreditCardResource = {
      customerId: parseInt(this.paymentEntry.MX_Customer_Id__c),
      isDefault: false, // convert to boolean if undefined
      // last4: last4,
      expiryMonth: "" + this.paymentEntry.ExpiryMonth,
      expiryYear: "" + this.paymentEntry.ExpiryYear,
      name: this.paymentEntry.FirstName + " " + this.paymentEntry.LastName,
      avsStreet: "" + this.paymentEntry.MailingStreet,
      avsZip: "" + this.paymentEntry.MailingPostalCode,
      REPLACE_number: "" + this.paymentEntry.CardNumber,
      alias:
        this.paymentEntry.FirstName +
        " " +
        this.paymentEntry.LastName +
        " " +
        this.paymentEntry.CardType,
      cvv: "" + this.paymentEntry.SecurityCode
    };
    console.log(CreditCardResource);
    const res = await savePaymentMethod({ creditCard: CreditCardResource });
    console.log(res);
    if (!res.isSuccess) {
      console.error(res.errorMessage);
      this.errorMessage =
        "An error has occured. We apologize for the inconvenience.";
      return;
    }
    return res.creditCard;
  }

  async handlePayment() {
    this.isProcessing = true;
    if (this.paymentEntry.MX_Customer_Id__c == "Unavailable") {
      const updatedContact = await this.handleSaveCustomer();
      this.paymentEntry.MX_Customer_Id__c = updatedContact.MX_Customer_Id__c;
    }

    const paymentMethod = await this.handleSavePaymentMethod();
    if (!paymentMethod.token) {
      this.isProcessing = false;
      this.errorMessage =
        "Unable to process this card. We apologize for the inconvenience.";
      return;
    }
    const paymentMethodData = {
      sobjectType: "Payment_Method__c",
      Card_Type__c: this.paymentEntry.CardType,
      Billing_First_Name__c: this.paymentEntry.FirstName,
      Billing_Last_Name__c: this.paymentEntry.LastName,
      Billing_Street__c: this.paymentEntry.MailingStreet,
      Billing_City__c: this.paymentEntry.MailingCity,
      Billing_State__c: this.paymentEntry.MailingState,
      Billing_Country__c: this.paymentEntry.MailingCountry,
      Billing_Postal_Code__c: this.paymentEntry.MailingPostalCode,
      Expiration_Date__c: new Date(this.paymentEntry.ExpiryMonth + "-" + this.setDate() + "-" + this.paymentEntry.ExpiryYear),
      Last_4_Digits_of_Card__c: this.paymentEntry.CardNumber.substring(this.paymentEntry.CardNumber.length - 4),
      ExternalId__c: "" + paymentMethod.id,
      Merchant_Token__c: paymentMethod.token,
      Contact__c: this.contactId,
    };

    let paymentMethodres = {};

    try {
      paymentMethodres = await saveRecord({ record: paymentMethodData });
    } catch(err) {
      console.error(err);
      this.errorMessage =
        "Unable to process this card. We apologize for the inconvenience.";
      return;
    }

    if(!paymentMethodres.Id){
      this.isProcessing = false;
      this.errorMessage =
        "An unexpected error has occured. We apologize for the inconvenience.";
      return;
    };


    const newRecord = {
      sobjectType: "Payment__c",
      Payment_Method__c: paymentMethodres.Id,
      Account__c: this.accountId,
      Amount__c: Number(this.paymentAmount).toFixed(2),
      Sales_Order__c: this.orderId,
      Contact__c: this.contactId,
      Date__c: new Date(Date.now()),
      Payment_Type__c: "Credit Card"
    };


    const paymentResource = {
      amount: this.paymentAmount,
      paymentType: "Sale",
      entryClass: "WEB",
      cardAccountToken: paymentMethod.token,
      clientReference: this.soName,
      invoice: this.soName
    };
    console.log(paymentResource);
    const pmtData = await makePayment({ payment: paymentResource });
    if (!pmtData.isSuccess) {
      if (pmtData.errorMessage && pmtData.errorCode) {
        this.isProcessing = false;
        console.error(pmtData.errorCode + " : " + pmtData.errorMessage);
        this.errorMessage = "Your payment could not be processed at this time.";
        return;
      }
      newRecord.Status__c = "Error";
    } else {
      if (pmtData.payment.status == "Approved") {
        newRecord.Status__c = "Completed";
      } else if (pmtData.payment.status == "Declined") {
        this.isProcessing = false;
        this.errorMessage =
          "Your payment was declined. Please try another card.";
        return;
      }
      newRecord.Payment_Token__c = "" + pmtData.payment.paymentToken;
    }
    newRecord.MX_Payment_Id__c = "" + pmtData.payment.id;
    newRecord.Transaction_Id__c = "" + pmtData.payment.reference;
    newRecord.Authorization_Id__c = "" + pmtData.payment.authCode;
    newRecord.Transaction_Type__c = "Payment";
    await saveRecord({ record: newRecord });
    this.isSuccess = true;
  }

  async handleClick(evt) {
    const title = evt.target.title;
    if (title == "Cancel") {
      window.history.back();
    } else if (title == "ReviewTransaction") {
      if (Object.values(this.paymentEntry).some((v) => !v)) {
        console.log(this.paymentEntry);
        this.errorMessage = "Please complete all fields.";
        return;
      } else {
        this.errorMessage = "";
        this.isReview = true;
      }
    } else if (title == "Back") {
      this.errorMessage = "";
      this.isReview = false;
    } else if (title == "SubmitPayment") {
      try {
        await this.handlePayment();
      } catch (err) {
        console.error(err);
        this.errorMessage =
          "An error has occured. Please contact the sender and try again later. We apologize for the inconvenience.";
      }
    }
  }
}