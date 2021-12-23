import { LightningElement, api, track, wire } from "lwc";
import { deleteRecord, getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import strUserId from "@salesforce/user/Id";
import PROFILE_NAME_FIELD from "@salesforce/schema/User.Profile.Name";
import makePayment from "@salesforce/apex/Zealynx.makePayment";
import doQuery from "@salesforce/apex/LWC.doQuery";
import saveRecord from "@salesforce/apex/LWC.saveRecord";
import saveMultipleRecords from "@salesforce/apex/LWC.saveMultipleRecords";
import saveCustomer from "@salesforce/apex/Zealynx.saveCustomer";
import savePaymentMethod from "@salesforce/apex/Zealynx.savePaymentMethod";
import deletePaymentMethod from "@salesforce/apex/Zealynx.deletePaymentMethod";
import TickerSymbol from "@salesforce/schema/Account.TickerSymbol";
import voidPayment from "@salesforce/apex/Zealynx.voidPayment";
/**
 * @todo Zealynx currently work in progress.
 * @todo makePayment - to change parameters, search for the variable paymentResource and change it from there.
 * @todo saveCustomer - to change parameters, search for the variable CustomerResource and change it from there
 * @todo deletePaymentMethod - in the action handler, currently just feeding the customer id and card id.
 */
const labelNameMap = {
  Amount: "amount",
  "Card Number": "cardNumber",
  cvv: "cvv",
  "First Name": "firstName",
  "Billing Street": "billingStreet",
  "Billing Postal Code": "billingPostalCode"
};

const paymentMethodFields = [
  "Id",
  "Billing_Street__c",
  "Billing_City__c",
  "Billing_Country__c",
  "Billing_Postal_Code__c",
  "Billing_State__c",
  "ExternalId__c",
  "Billing_First_Name__c",
  "Billing_Last_Name__c",
  "Default__c",
  "Contact__c",
  "Contact__r.Name",
  "Contact__r.MX_Customer_Id__c",
  "Card_Type__c",
  "Last_4_Digits_of_Card__c",
  "Expiration_Date__c",
  "Merchant_Token__c"
];

const contactFields = [
  "Id",
  "Name",
  "FirstName",
  "LastName",
  "MailingStreet",
  "MailingPostalCode",
  "MailingState",
  "MailingCity",
  "MailingCountry",
  "MX_Customer_Id__c"
];

const actions = [
  { label: "Go To Record", name: "view_record" },
  { label: "Delete Record", name: "delete" }
];

export default class PaymentTerminal extends NavigationMixin(LightningElement) {
  @api recordId;
  @track salesOrder;
  disableForUser = true;
  unhideToast = false;
  showPaymentSuccess = false;
  toastVariant = "success";
  toastMessage = "";
  toastTitle = "";
  showSpinner = true;
  isDisabled = false;
  enablePayments = true;
  userData = {};
  paymentMethods = [];
  selectedPaymentMethod = { Contact__c: null, cardNumber: null };
  showNewPaymentMethod = true;
  showNewCardScreen = false;
  showAmountScreen = false;
  showScheduledPayment = false;
  accountContacts = {};
  shouldRequireAmount = true;
  contactOptions = [];
  existingPayments;
  isSubmittingTransaction = false;
  totalAmount;
  maxAllowed;
  payment = {
    amount: null,
    expiryMonth: "",
    expiryYear: "",
    cardType: "",
    orderIds: [],
    isMultiple: false,
    scheduledDate: null,
    numberOfPayments: 0,
    contactId: null
  };
  totalScheduledPayment = 0;
  paymentMethodColumns = [
    { type: "action", typeAttributes: { rowActions: actions } },
    { label: "Card Holder Name", fieldName: "__CardHolderName" }, // ? joining first + last names
    { label: "Related Contact", fieldName: "__ContactName" }, // ? changed from contact__r.name : datatable columns don't recognise children records
    { label: "Card Type", fieldName: "Card_Type__c" },
    { label: "Last 4", fieldName: "Last_4_Digits_of_Card__c" },
    { label: "Expiration Date", type: "date", fieldName: "Expiration_Date__c" },
    { label: "Default", type: "boolean", fieldName: "Default__c" }
  ];

  async renderedCallback() {
    // if (!this.isRendered && this.recordId) {
    //   const [data, error] = await this.queryExistingMethods();
    //   if (error) {
    //     console.error(error);
    //   } else {
    //     this.paymentMethods = data;
    //   }
    //   this.isRendered = true;
    // }
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "SalesOrder__c.Name",
      "SalesOrder__c.Account__c",
      "SalesOrder__c.ContactBilling__c",
      "SalesOrder__c.ContactBilling__r.FirstName",
      "SalesOrder__c.ContactBilling__r.LastName",
      "SalesOrder__c.ContactBilling__r.MailingStreet",
      "SalesOrder__c.ContactBilling__r.MailingPostalCode",
      "SalesOrder__c.ContactBilling__r.MailingCity",
      "SalesOrder__c.ContactBilling__r.MailingCountry",
      "SalesOrder__c.ContactBilling__r.MailingState",
      "SalesOrder__c.NetAmount__c",
      "SalesOrder__c.ExistingPayments__c",
      "SalesOrder__c.BalanceDueAmount__c",
      "SalesOrder__c.Status_Picklist__c",
      "SalesOrder__c.Net_Due__c"
    ]
  })
  async parentRecord({ error, data }) {
    if (data) {
      if (
        data.fields.Status_Picklist__c.value == "Draft" ||
        data.fields.Status_Picklist__c.value == "Submitted for Approval"
      ) {
        this.enablePayments = false;
        alert("Unable to make payments on unapproved sales orders.");
        window.location.replace("/" + this.recordId);
        return;
      }
      if (!data.fields.ContactBilling__c.value) {
        window.alert("Please select a Billing Contact first.");
        window.location.replace("/" + data.id);
      }
      // console.log("data", data);
      this.salesOrder = {
        Id: data.id,
        Name: data.fields.Name.value,
        Account__c: data.fields.Account__c.value,
        ContactBilling__c: data.fields.ContactBilling__c.value,
        Net_Due__c: data.fields.Net_Due__c.value
      };
      // console.log("userData");
      this.selectedPaymentMethod = {
        Contact__c: data.fields.ContactBilling__c.value,
        firstName: data.fields.ContactBilling__r.value.fields.FirstName.value,
        lastName: data.fields.ContactBilling__r.value.fields.LastName.value,
        billingStreet:
          data.fields.ContactBilling__r.value.fields.MailingStreet.value,
        billingCity:
          data.fields.ContactBilling__r.value.fields.MailingCity.value,
        billingState:
          data.fields.ContactBilling__r.value.fields.MailingState.value,
        billingCountry:
          data.fields.ContactBilling__r.value.fields.MailingCountry.value ||
          "United States",
        billingPostalCode:
          data.fields.ContactBilling__r.value.fields.MailingPostalCode.value
      };
      this.totalAmount = data.fields.NetAmount__c.value;
      this.existingPayments = data.fields.ExistingPayments__c.value;
      this.shouldRequireAmount = data.fields.ExistingPayments__c.value == 0;
      this.payment.amount = Number(
        (
          data.fields.NetAmount__c.value - data.fields.ExistingPayments__c.value
        ).toFixed(2)
      );
      this.payment.orderIds.push(data.id);
      const [contactsdata, contactserror] = await this.getRelatedContacts();
      if (contactserror) {
        console.error(contactserror);
      } else if (contactsdata.length > 0) {
        const contactsMap = {};
        contactsdata.forEach((d) => {
          contactsMap[d.Id] = {
            firstName: d.FirstName,
            lastName: d.LastName,
            billingStreet: d.MailingStreet,
            billingPostalCode: d.MailingPostalCode,
            billingCity: d.MailingCity,
            billingCountry: d.MailingCountry,
            billingState: d.MailingState,
            isDefault: false,
            Contact__c: d.Id,
            MX_Customer_Id__c: d.MX_Customer_Id__c
          };
        });
        this.accountContacts = contactsMap;
        this.contactOptions = contactsdata.map((d) => ({
          label: d.Name,
          value: d.Id
        }));
      }
      const [methodsdata, methodserror] = await this.queryExistingMethods();
      if (methodserror) {
        console.error(methodserror);
      } else {
        this.paymentMethods = methodsdata.map((v) => ({
          ...v,
          __ContactName: v.Contact__r.Name,
          __CardHolderName:
            v.Billing_Last_Name__c &&
            v.Billing_First_Name__c &&
            v.Billing_First_Name__c + " " + v.Billing_Last_Name__c
        }));
      }

      this.showSpinner = false;
    } else if (error) {
      console.error(error);
    }
  }

  @wire(getRecord, {
    recordId: strUserId,
    fields: [PROFILE_NAME_FIELD]
  })
  wireUser({ error, data }) {
    if (error) {
      console.error(error);
    } else if (data) {
      if (
        ["FSP - Accounting +", "System Administrator"].includes(
          data.fields.Profile.value.fields.Name.value
        )
      ) {
        this.disableForUser = false;
      }
    }
  }

  displayError() {
    this.toastTitle = "Error";
    this.toastVariant   = "error";
    this.toastMessage  = "Unexpected error occured. Please refresh your page and try again.";
    this.unhideToast = true;
  }

  async queryExistingMethods() {
    let queryString = "SELECT " + paymentMethodFields.join(",");
    queryString +=
      " FROM Payment_Method__c WHERE Contact__r.AccountId = '" +
      this.salesOrder.Account__c +
      "'";
    try {
      const res = await doQuery({ queryString: queryString });
      // console.log(res);
      return [res, null];
    } catch (err) {
      return [null, err];
    }
  }

  async getRelatedContacts() {
    let queryString = "SELECT " + contactFields.join(",");
    queryString +=
      " FROM Contact WHERE AccountId = '" + this.salesOrder.Account__c + "'";
    try {
      const res = await doQuery({ queryString: queryString });
      // console.log(res);
      return [res, null];
    } catch (err) {
      return [null, err];
    }
  }

  handleRowSelection(event) {
    let selectedRows = event.detail.selectedRows;
    // console.log(selectedRows);
    if (selectedRows.length > 1) {
      var el = this.template.querySelector("lightning-datatable");
      selectedRows = el.selectedRows = el.selectedRows.slice(1);
      event.preventDefault();
      return;
    } else if (selectedRows.length > 0) {
      this.selectedPaymentMethod = {
        Contact__c: selectedRows[0].Contact__c,
        Id: selectedRows[0].Id,
        ExternalId__c: selectedRows[0].ExternalId__c,
        Merchant_Token__c: selectedRows[0].Merchant_Token__c
      };
      this.showAmountScreen = true;
      this.showNewPaymentMethod = true;
      this.showNewCardScreen = false;
      this.payment.contactId = selectedRows[0].Contact__c;
    } else {
      this.selectedPaymentMethod = { Contact__c: null };
      this.showAmountScreen = false;
    }
  }

  async handleOnClick(event) {
    let label = event.target.label;
    // console.log(label);
    if (label === "New Payment Method") {
      this.showNewCardScreen = true;
      this.showNewPaymentMethod = false;
    } else if (label === "Cancel") {
      this.showNewCardScreen = false;
      this.showNewPaymentMethod = true;
    } else if (label === "Save Payment Method") {
      await this.savePaymentMethod();
    } else if (label === "Submit Transaction") {
      await this.savePayment();
    } else if (label === "Return to Order") {
      window.location.pathname = "/" + this.salesOrder.Id;
    }
    /*
    if (this.lironIsTesting) {
      // console.log(JSON.stringify([this.userData, this.payment]));
    } else {
      let inputs = this.template.querySelectorAll("lightning-input");
      for (let i = 0; i < inputs.length; i++) {
        // console.log(inputs[i].label);
        // console.log(inputs[i].value);
        if (labelNameMap.hasOwnProperty(inputs[i].label)) {
          this.payment[labelNameMap[inputs[i].label]] = inputs[i].value;
        }
      }
      // console.log(JSON.stringify(this.payment));
      this.isDisabled = true;
      let response = await makePayment({ payment: payment });
      // console.log( response );
      this.showToast("Confirmation", "Payment Submitted");
    }
*/
  }

  showToast(title, message, variant = "info", messageData) {
    let event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    if (messageData) {
      event.messageData = messageData;
    }
    this.dispatchEvent(event);
  }

  handleOnChange(event) {
    let name = event.target.name;
    if (!name) {
      name = event.target.dataset.name;
    }
    const value = event.target.value;
    const objectName = event.target.dataset.objectname;
    // console.log(objectName, name, value);
    if (objectName === "paymentMethod") {
      if (name === "Contact__c") {
        this.selectedPaymentMethod = {
          ...this.selectedPaymentMethod,
          ...this.accountContacts[value]
        };
      } else {
        this.selectedPaymentMethod[name] =
          name === "isDefault" ? event.target.checked : value;
      }
    } else if (objectName === "payment") {
      if (name === "isMultiple") {
        this.payment[name] = event.target.checked;
        this.showScheduledPayment = event.target.checked;
        this.totalScheduledPayment = this.allowedTotalScheduled;
      } else if (name === "totalScheduledPayment") {
        // console.log(value);
        this.totalScheduledPayment = value;
        this.template.querySelector(
          'lightning-input[data-name="scheduledPayment"]'
        ).value = this.scheduledPayment;
      } else {
        this.payment[name] = value;
        if (
          name === "numberOfPayments" ||
          (name === "amount" && this.showScheduledPayment)
        ) {
          this.template.querySelector(
            'lightning-input[data-name="totalScheduledPayment"]'
          ).max = this.allowedTotalScheduled;
          if (
            this.totalScheduledPayment > this.allowedTotalScheduled ||
            !this.totalScheduledPayment
          ) {
            this.totalScheduledPayment = this.allowedTotalScheduled;
          }
          this.template.querySelector(
            'lightning-input[data-name="scheduledPayment"]'
          ).value = this.scheduledPayment;
          window.setTimeout(() => {
            this.template
              .querySelector(
                'lightning-input[data-name="totalScheduledPayment"]'
              )
              .reportValidity();
          }, 10);
        }
      }
    } else {
      let dataType = Object.keys(this.userData).includes(name)
        ? "userData"
        : "payment";
      this[dataType][name] = value;
    }
  }

  handleCloseToast() {
    this.unhideToast = false;
  }

  // async handleSave() {
  //   "Card_Type__c, Last_4_Digits_of_Card__c, Expiration_Date__c, Contact__c";
  //   let proceed = true;

  //   const { expiryMonth, expiryYear, cardType } = this.payment;
  //   let ccNum = this.template.querySelector(
  //     "lightning-input[data-name='cardNumber'"
  //   ).value;
  //   let lastFour;
  //   if (ccNum.length < 4 || /[a-z]/i.test(ccNum)) {
  //     window.alert("Please enter a valid credit card number.");
  //     return;
  //   }
  //   lastFour = ccNum.substring(ccNum.length - 4);
  //   ccNum = null;
  //   if (!expiryMonth || !expiryYear || !cardType) {
  //     window.alert("Please fill out all fields.");
  //     return;
  //   }
  //   const newRecord = {
  //     sobjectType: "Payment_Method__c",
  //     Card_Type__c: cardType,
  //     Last_4_Digits_of_Card__c: lastFour,
  //     Expiration_Date__c: new Date(`${expiryMonth}/01/${expiryYear}`),
  //     Contact__c: this.salesOrder.ContactBilling__c
  //   };
  //   const createdRecord = await saveRecord({ record: newRecord });
  //   this.paymentMethods = [...this.paymentMethods, createdRecord];
  // }

  async savePayment() {
    this.isSubmittingTransaction = true;
    let newRecords = [];
    if (
      (Number(this.payment.amount) < 0.01 && !this.payment.isMultiple) ||
      (Number(this.payment.amount) < 0.01 &&
        this.payment.isMultiple &&
        this.shouldRequireAmount)
    ) {
      this.toastMessage = "Invalid amount.";
      this.toastTitle = "Nothing to pay";
      this.toastVariant = "error";
      this.unhideToast = true;
      this.isSubmittingTransaction = false;
      return;
    } else if (Number(this.payment.amount > this.existingPayments)) {
    }
    if (this.payment.isMultiple) {
      if (!this.payment.scheduledDate) {
        this.toastTitle = "Error";
        this.toastMessage =
          "Please select a day of the month to process the payment on.";
        this.toastVariant = "error";
        this.unhideToast = true;
        this.isSubmittingTransaction = false;
        return;
      }
      if (!this.payment.numberOfPayments || this.payment.numberOfPayments < 1) {
        this.toastTitle = "Error";
        this.toastMessage = "Please enter a valid number of payments.";
        this.toastVariant = "error";
        this.unhideToast = true;
        this.isSubmittingTransaction = false;
        return;
      }

      if (this.totalScheduledPayment > this.allowedTotalScheduled) {
        alert(
          "Your total scheduled payment is higher than the maximum allowed ($" +
            this.allowedTotalScheduled +
            ")"
        );
        this.isSubmittingTransaction = false;
        return;
      }

      const fullDate = new Date(this.payment.scheduledDate);
      // console.log(fullDate);
      // console.log(this.scheduledPayment);
      let day = fullDate.getDate() + 1;
      let year = fullDate.getFullYear();
      let month = fullDate.getMonth() + 1;
      let accumulatedPayments = 0;
      for (let i = 0; i < this.payment.numberOfPayments; i++) {
        let actualDay = day;
        if (month > 12) {
          year++;
          month = month % 12 > 0 ? month % 12 : 12;
        }

        let lastDay = new Date(year, month, 0).getDate();

        if (day > lastDay) {
          actualDay = lastDay;
        }

        const newRecord = {
          sobjectType: "Payment__c",
          Account__c: this.salesOrder.Account__c,
          Amount__c: Number(this.scheduledPayment).toFixed(2),
          Payment_Method__c: this.selectedPaymentMethod.Id,
          Sales_Order__c: this.salesOrder.Id,
          Contact__c: this.payment.contactId,
          Payment_Type__c: "Credit Card",
          Scheduled_Payment_Date__c: new Date(
            month + "-" + actualDay + "-" + year
          ),
          Date__c: new Date(year + "-" + month + "-" + actualDay),
          Status__c: "Scheduled"
        };
        accumulatedPayments += Number(newRecord.Amount__c);
        newRecords.push(newRecord);
        month++;
      }
      // console.log(accumulatedPayments);
      if (accumulatedPayments !== this.totalScheduledPayment) {
        const updatedAmount =
          Number(newRecords[0].Amount__c) +
          Number(this.totalScheduledPayment - accumulatedPayments);
        newRecords[0].Amount__c = Number(updatedAmount.toFixed(2));
        alert(
          "First scheduled payment is going to be $" + newRecords[0].Amount__c
        );
      }
    }

    let newRecord = {
      sobjectType: "Payment__c",
      Account__c: this.salesOrder.Account__c,
      Amount__c: this.payment.amount,
      Payment_Method__c: this.selectedPaymentMethod.Id,
      Sales_Order__c: this.salesOrder.Id,
      Contact__c: this.payment.contactId,
      Status__c: "Pending",
      Payment_Type__c: "Credit Card"
    };

    if (!this.accountContacts[newRecord.Contact__c].MX_Customer_Id__c) {
      const contactResult = await this.handleSaveCustomer(newRecord.Contact__c);
      this.accountContacts[newRecord.Contact__c].MX_Customer_Id__c =
        contactResult.MX_Customer_Id__c;
    }

    if (!this.selectedPaymentMethod.Merchant_Token__c) {
      this.toastMessage = "Payment method not in merchant database. Please create a new one and try agian.";
      this.toastTitle = "Error";
      this.toastVariant = "error";
      this.unhideToast = true;
      return;
    }

    const paymentResource = {
      amount: newRecord.Amount__c,
      paymentType: "Sale",
      entryClass: "WEB",
      cardAccountToken: this.selectedPaymentMethod.Merchant_Token__c,
      clientReference: this.salesOrder.Name,
      invoice: this.salesOrder.Name
      // customerId: parseInt(this.accountContacts[this.selectedPaymentMethod.Contact__c]
      //     .MX_Customer_Id__c)
    };
    // console.log(paymentResource);

    let caughtError = false;

    const savedRecord = await saveRecord({ record: newRecord }).catch(
      err => {
        console.error(err);
        this.displayError();
        return;
      }
    );
    
    const pmtData = await makePayment({ payment: paymentResource }).catch(
      err => { 
        console.error(err);
        savedRecord.Status__c = "Error";
        caughtError = true;
        this.displayError();
      }
    );


    if(caughtError) {
      await saveRecord({ record: savedRecord });
      return;
    }

    const rawSavedRecord = {...savedRecord};


    if (!pmtData.isSuccess) {
      if (pmtData.errorMessage) {
        console.error(pmtData.errorCode + " : " + pmtData.errorMessage);
        alert("Payment error:" + pmtData.errorMessage);
      }
      savedRecord.Status__c = "Error";
      newRecords = [];
    } else {
      if (pmtData.payment.status == "Approved") {
        savedRecord.Status__c = "Completed";
        savedRecord.Authorization_Id__c = "" + pmtData.payment.authCode;
      } else if (pmtData.payment.status == "Declined") {
        savedRecord.Status__c = "Declined";
        this.toastTitle = "Declined";
        this.toastVariant = "error";
        this.toastMessage =
          "This payment was declined." +
          (newRecords.length > 0 ? " No scheduled payment will be made." : "");
        this.unhideToast = true;
        newRecords = [];
      }
      savedRecord.Payment_Token__c = "" + pmtData.payment.paymentToken;
    }

    savedRecord.MX_Payment_Id__c = "" + pmtData.payment.id;
    savedRecord.Transaction_Id__c = "" + pmtData.payment.reference;
    savedRecord.Transaction_Type__c = "Payment";
    savedRecord.sobjectType = "Payment__c";
    newRecords.push(savedRecord);

    const results = await saveMultipleRecords({ records: newRecords }).catch(err => {
      console.error(err);
      this.displayError();
      rawSavedRecord.Status__c = "Error";
      
    });

    if (rawSavedRecord.Status__c == "Error") {
      await saveRecord({ record: rawSavedRecord }).catch(err => {console.error(err)});
      const voidRequest = {
        id: pmtData.payment.id
      };
      await voidPayment({ payment: voidRequest }).catch(err => {console.error(err)});
      return;
    }


    // let result = await saveRecord({ record: newRecord });
    // console.log(results);

    if (results && results[results.length - 1].Id) {
      // console.log("success");
      this.payment.Id = results[results.length - 1].Id;
      this.payment.url = "/" + results[results.length - 1].Id;
      this.showAmountScreen = false;
      this.payment.isMultiple = false;
      this.showScheduledPayment = false;
      if (results[results.length - 1].Status__c == "Completed") {
        this.showPaymentSuccess = true;
        setTimeout(() => {
          window.location.reload();
        }, 3000);
      }
      this.isSubmittingTransaction = false;
    }
  }

  setDate() {
    return new Date(
      this.selectedPaymentMethod.expiryYear,
      this.selectedPaymentMethod.expiryMonth,
      0
    ).getDate();
  }

  async handleZealynxSavePaymentMethod(last4) {
    const paymentMethodCopy = { ...this.selectedPaymentMethod };
    const CreditCardResource = {
      customerId: parseInt(
        this.accountContacts[paymentMethodCopy.Contact__c].MX_Customer_Id__c
      ),
      isDefault: !!paymentMethodCopy.isDefault, // convert to boolean if undefined
      // last4: last4,
      expiryMonth: "" + paymentMethodCopy.expiryMonth,
      expiryYear: "" + paymentMethodCopy.expiryYear,
      name: paymentMethodCopy.firstName + " " + paymentMethodCopy.lastName,
      avsStreet: "" + paymentMethodCopy.billingStreet,
      avsZip: "" + paymentMethodCopy.billingPostalCode,
      REPLACE_number: "" + paymentMethodCopy.cardNumber,
      alias:
        paymentMethodCopy.firstName +
        " " +
        paymentMethodCopy.lastName +
        " " +
        paymentMethodCopy.cardType,
      cvv: "" + paymentMethodCopy.cvv
    };
    // console.log(CreditCardResource);
    try {
      const res = await savePaymentMethod({ creditCard: CreditCardResource });
      // console.log(res);
      if (!res.isSuccess) {
        console.error(res.errorMessage);
        return;
      }
      return res.creditCard;
  
    } catch (error) {
      console.error(error);
      this.displayError();
      return;
    }
  }

  async handleSaveCustomer(contactId) {
    const contactRecord = this.accountContacts[contactId];
    // console.log(contactRecord);
    const CustomerResource = {
      name: contactRecord.firstName + " " + contactRecord.lastName,
      firstName: contactRecord.firstName,
      lastName: contactRecord.lastName,
      REPLACE_number: contactRecord.Contact__c,
      address1: contactRecord.billingStreet,
      address2: "",
      city: contactRecord.billingCity,
      state: contactRecord.billingState,
      zip: contactRecord.billingPostalCode,
      customerType: "Business"
    };
    // console.log(CustomerResource);
    try {
      const res = await saveCustomer({ customer: CustomerResource });
      // console.log(res);
      if (!res.isSuccess) {
        if (res.errorMessage && res.errorCode) {
          console.error(res.errorCode + " : " + res.errorMessage);
          return;
        }
      }
      const updatedContact = {
        sobjectType: "Contact",
        MX_Customer_Id__c: res.customer.id + "",
        Id: contactRecord.Contact__c
      };
      const savedContact = await saveRecord({ record: updatedContact });
      // console.log("savedContact", savedContact);
      return savedContact;
    } catch (e) {
      console.error(e);
      this.toastVariant = "error";
      this.toastTitle  = "Error";
      this.toastMessage = "Unexpected error occured. Please refresh your page and try again.";
      this.unhideToast = true;
    }
  }

  async savePaymentMethod() {
    const inputs = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("lightning-combobox")
    ];
    const allValid = inputs.reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    if (!allValid) {
      alert("Please fill in all required fields");
      return;
    }
    let newRecord = {
      sobjectType: "Payment_Method__c",
      Card_Type__c: this.selectedPaymentMethod.cardType,
      Contact__c: this.selectedPaymentMethod.Contact__c,
      Last_4_Digits_of_Card__c: this.selectedPaymentMethod.cardNumber.substring(
        this.selectedPaymentMethod.cardNumber.length - 4
      ),
      Payment_Processor__c: "MX Merchant",
      Billing_First_Name__c: this.selectedPaymentMethod.firstName,
      Billing_Last_Name__c: this.selectedPaymentMethod.lastName,
      Billing_Street__c: this.selectedPaymentMethod.billingStreet,
      Billing_City__c: this.selectedPaymentMethod.billingCity,
      Billing_State__c: this.selectedPaymentMethod.billingState,
      Billing_Country__c: this.selectedPaymentMethod.billingCountry,
      Billing_Postal_Code__c: this.selectedPaymentMethod.billingPostalCode,
      Default__c: this.selectedPaymentMethod.isDefault,
      Expiration_Date__c: new Date(
        this.selectedPaymentMethod.expiryMonth +
          "-" +
          this.setDate() +
          "-" +
          this.selectedPaymentMethod.expiryYear
      )
    };
    //    Expiration_Date__c: this.selectedPaymentMethod.expiryYear+'-'+this.selectedPaymentMethod.expiryMonth+'-30',
    if (!this.accountContacts[newRecord.Contact__c].MX_Customer_Id__c) {
      const contactResult = await this.handleSaveCustomer(newRecord.Contact__c);
      this.accountContacts[newRecord.Contact__c].MX_Customer_Id__c =
        contactResult.MX_Customer_Id__c;
    }
    const cardData = await this.handleZealynxSavePaymentMethod(
      newRecord.Last_4_Digits_of_Card__c
    );
    // console.log("cardData", cardData);
    newRecord.ExternalId__c = "" + cardData.id;
    newRecord.Merchant_Token__c = "" + cardData.token;
    let result = await saveRecord({ record: newRecord });
    // console.log("SAVE RESULT");
    // console.log(result);
    this.selectedPaymentMethod.Id = result.Id;
    const [data, error] = await this.queryExistingMethods();
    if (error) {
      this.toastVariant = "error";
      this.toastTitle = "Error";
      this.toastMessage = "Unexpected error occured. Please refresh your page and try again.";
      this.unhideToast = true;
      console.error(error);
      return;
    } else {
      this.showNewCardScreen = false;
      this.showAmountScreen = true;
      this.showNewPaymentMethod = true;
      this.paymentMethods = data.map((d) => ({
        ...d,
        __CardHolderName:
          d.Billing_Last_Name__c &&
          d.Billing_First_Name__c &&
          d.Billing_First_Name__c + " " + d.Billing_Last_Name__c,
        __ContactName: d.Contact__r.Name
      }));
    }
  }

  async handleRowAction(evt) {
    const actionName = evt.detail.action.name;
    const row = evt.detail.row;
    switch (actionName) {
      case "delete":
        if (row.Contact__r.MX_Customer_Id__c && row.ExternalId__c) {
          await deletePaymentMethod({
            creditCard: {
              id: row.Contact__r.MX_Customer_Id__c,
              subId: row.ExternalId__c
            }
          });
        }

        await deleteRecord(row.Id);
        this.paymentMethods = this.paymentMethods.filter(
          (v) => v.Id !== row.Id
        );
        break;
      case "view_record":
        window.open("/" + row.Id, "_blank").focus();
        break;
    }
  }

  navigateToRecordViewPage(recordId) {
    if (this.toastVariant != "error") {
      const messageData = {
        url: "/" + recordId,
        label: "View"
      };
      this.showToast("Success", "Record Saved: {0}", "success", messageData);
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: recordId,
          actionName: "view"
        }
      });
    }
  }

  get cardTypeOptions() {
    return [
      { label: "Visa", value: "Visa" },
      { label: "Mastercard", value: "Mastercard" },
      { label: "American Express", value: "American Express" },
      { label: "Discover", value: "Discover" }
    ];
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

  get scheduledPayment() {
    return this.payment.numberOfPayments > 0
      ? Number(
          (
            Number(this.totalScheduledPayment) / this.payment.numberOfPayments
          ).toFixed(2)
        )
      : 0;
  }

  get allowedTotalScheduled() {
    return Number(
      (this.salesOrder.Net_Due__c - this.payment.amount).toFixed(2)
    );
  }

  get minDate() {
    const today = new Date();
    return (
      today.getFullYear() +
      "-" +
      ("0" + (today.getMonth() + 1)).slice(-2) +
      "-" +
      ("0" + today.getDate()).slice(-2)
    );
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
}