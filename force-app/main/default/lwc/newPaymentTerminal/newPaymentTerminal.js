import getRecordData from "@salesforce/apex/BoomPaymentTerminal_LightningController.getRecordData";
import handleSinglePayment from "@salesforce/apex/BoomPaymentTerminal_LightningController.handleSinglePayment";
import handleMultiplePayments from "@salesforce/apex/BoomPaymentTerminal_LightningController.handleMultiplePayments";
import returnPaymentMethods from "@salesforce/apex/BoomPaymentTerminal_LightningController.returnPaymentMethods";
import returnRelatedContact from "@salesforce/apex/BoomPaymentTerminal_LightningController.returnRelatedContact";
import saveCustomer from "@salesforce/apex/BoomPaymentTerminal_LightningController.saveCustomer";
import savePaymentMethod from "@salesforce/apex/BoomPaymentTerminal_LightningController.savePaymentMethod";
import { api, LightningElement } from "lwc";

/**
 * @typedef {Object<string,any> } SalesOrderRecord
 * @property {boolean} allowMultiple
 * @property {boolean} isAmProfile
 * @property {date} firstPaymentDate
//  * @property {decimal} financeFeeRate
 * @property {decimal} totalAmount
 * @property {decimal} amountDue
 * @property {decimal} amountPaid
 * @property {boolean} waveFinanceFee
 * @property {string} contactId
 * @property {string} accountName
 **/

export default class NewPaymentTerminal extends LightningElement {
  @api recordId;
  /**
   * @type {SalesOrderRecord} record
   */
  record;
  paymentMethods = [];
  paymentMethodsMap = {};
  currentContactIdLocal;
  selectedContact;
  showComponent = false;
  errorMessages = [];
  showCardForm = false;
  showMainForm = true;
  selectedPaymentMethod;
  firstPaymentPercentLocal = 20;
  isMultiple = false;
  showLookup = false;
  multiplePayment = {
    paymentAmount: 0,
    numberOfPayments: "",
    firstPayment: 0
  };
  totalScheduledAmountLocal = 0;
  firstPaymentChange = 0;
  firstPaymentPercentChange = 0;
  firstPaymentLocal = 0;
  numberOfSchedulePaymentsLocal = 0;
  scheduledPaymentComboboxValue = "";
  financeFeeWaved = false;

  get noPaymentMethods() {
    return !this.paymentMethods || this.paymentMethods.length === 0;
  }

  get currentContactId() {
    let contactId = this.currentContactIdLocal;
    if (!this.currentContactIdLocal && this.record.contactId) {
      contactId = this.record.contactId;
    }

    return contactId;
  }

  set currentContactId(value) {
    this.currentContactIdLocal = value;
  }

  get hasErrors() {
    return this.errorMessages.length > 0;
  }

  async connectedCallback() {
    await this.loadRecordData();
    await this.loadPaymentMethods(this.record.contactId);
    this.paymentMethods = Object.values(this.paymentMethodsMap).map((pm) => {
      const expDate = new Date(pm.Expiration_Date__c);
      const expMonth =
        expDate.getMonth() + 1 < 10
          ? "0" + (expDate.getMonth() + 1)
          : expDate.getMonth() + 1;
      const expYear = expDate.getFullYear();
      return {
        ...pm,
        _expiration: `${expMonth}/${expYear}`
      };
    });
    await this.loadContactRecord(this.record.contactId);
    this.showComponent = true;
  }

  async loadRecordData() {
    try {
      const res = await getRecordData({ recordId: this.recordId });
      if(!res.allowPayments && res.status !== "Released") {
        let alertMessage = '';
        switch (res.status) {
          case "Draft":{
            alertMessage = "Payments cannot be applied to this order in draft status. Please submit for approval.";
            break;
          }
          case "Submitted for Approval": {
            alertMessage = "Payments cannot be applied to this order while it is awaiting approval.";
            break;
          }
        }
        alert(alertMessage);
        this.returnToRecord();
        return;
      }
      this.record = res;
      
      if (res.hasOwnProperty("firstPaymentDate")) {
        this.multiplePayment = {
          ...this.multiplePayment,
          newFirstPaymentDate: res.firstPaymentDate
        };
      }
      this.firstPayment = Number(
        (res.amountDue * (this.firstPaymentPercent / 100)).toFixed(2)
      );
    } catch (error) {
      this.handleError(
        error,
        "An error has occured while loading the order data."
      );
    }
  }

  async loadPaymentMethods(contactId) {
    try {
      const res = await returnPaymentMethods({ contactId });
      this.paymentMethodsMap = res;
    } catch (error) {
      this.handleError(
        error,
        "An error has occured while loading payment methods."
      );
    }
  }

  async loadContactRecord(contactId) {
    try {
      const res = await returnRelatedContact({ contactId });
      if (!res.MailingCountry) {
        res.MailingCountry = "United States";
      }
      this.selectedContact = res;
    } catch (error) {
      this.handleError(
        error,
        "An error has occured while loading the contact record."
      );
    }
  }

  handleFirstPaymentChange(event) {
    const local = event.target.dataset.local;
    console.log(local, event.detail.value);
    switch (local) {
      case "percent": {
        this.firstPaymentPercentChange = Number(event.detail.value);
        break;
      }
      case "number": {
        this.firstPaymentChange = Number(event.detail.value);
        break;
      }
    }
  }

  handleFirstPaymentCommit() {
    if (
      this.firstPaymentChange &&
      this.firstPaymentChange != this.firstPayment
    ) {
      this.firstPayment = this.firstPaymentChange;
      this.firstPaymentPercentChange =
        Number((this.firstPaymentChange / this.amountDue).toFixed(2)) *
        100;
      this.firstPaymentPercent =
        Number((this.firstPaymentChange / this.amountDue).toFixed(2)) *
        100;
      this.totalScheduledAmount = this.amountDue - this.firstPayment;
      console.log("firstPaymentChange", this.firstPaymentChange);
    }
    if (
      this.firstPaymentPercentChange &&
      this.firstPaymentPercentChange != this.firstPaymentPercent
    ) {
      this.firstPaymentPercent = this.firstPaymentPercentChange;
      this.firstPaymentChange = Number(
        (
          (this.firstPaymentPercentChange / 100) *
          this.amountDue
        ).toFixed(2)
      );
      this.firstPayment = Number(
        (
          (this.firstPaymentPercentChange / 100) *
          this.amountDue
        ).toFixed(2)
      );
      this.totalScheduledAmount = this.amountDue - this.firstPayment;
    }
  }

  toggleFinanceFeeWaiver() {
    const beforeAmount = this.amountDue;
    this.financeFeeWaved = !this.financeFeeWaved;
    const afterAmount = this.amountDue;
    const difference = afterAmount - beforeAmount;
    this.firstPayment = this.firstPayment + difference;
  }

  handleError(error, defaultMessage) {
    let errorMessages = [...this.errorMessages, defaultMessage];
    if (error && error.body && Array.isArray(error.body)) {
      errorMessages = error.body.map((e) => e.message);
    } else if (
      error &&
      error.body &&
      error.body.message &&
      typeof error.body.message === "string"
    ) {
      errorMessages = [error.body.message];
    }
    this.errorMessages = errorMessages;
    this.showComponent = true;
    this.isMultiple = this.isMultiple;
  }

  async handlePaymentMethodCustomLookupSelect(event) {
    const contactId = event.detail.value;
    if (contactId) {
      this.currentContactId = contactId;
      await this.loadPaymentMethods(contactId);
      this.paymentMethods = Object.values(this.paymentMethodsMap).map((pm) => {
        const expDate = new Date(pm.Expiration_Date__c);
        const expMonth =
          expDate.getMonth() + 1 < 10
            ? "0" + (expDate.getMonth() + 1)
            : expDate.getMonth() + 1;
        const expYear = expDate.getFullYear();
        return {
          ...pm,
          _expiration: `${expMonth}/${expYear}`
        };
      });
      await this.loadContactRecord(contactId);
      this.showLookup = false;
    }
  }

  handleClick(event) {
    const title = event.target.title;

    switch (title) {
      case "return to order": {
        this.returnToRecord();
        break;
      }
      case "add card to vault": {
        this.toggleForm();
        break;
      }
      case "select payment method": {
        this.selectedPaymentMethod =
          this.paymentMethodsMap[event.target.dataset.id];
        break;
      }
      case "change payment method": {
        this.selectedPaymentMethod = null;
        this.isMultiple = false;
        this.financeFeeWaved = false;
        break;
      }
      case "toggle lookup": {
        this.showLookup = !this.showLookup;
        break;
      }
      case "submit transaction": {
        this.showComponent = false;
        if (this.isMultiple) {
          this.handleMultiplePayments();
        } else {
          this.handleSinglePayment();
        }
        break;
      }
    }
  }

  async handleSinglePayment() {
    this.errorMessages = [];
    const inp = this.template.querySelector(`[data-name='amountfield']`);
    inp.reportValidity();
    if (!inp.checkValidity()) {
      this.showComponent = true;
      this.errorMessages = ["Please enter a valid amount."];
      return;
    }

    const amount = Number(Number(inp.value).toFixed(2));

    if(amount < 0.01) {
      this.showComponent = true;
      this.errorMessages = ["You cannot make negative payments here. Please refund an existing one instead."];
      return;
    }
    const singlePayment = {
      amount,
      salesOrderId: this.recordId,
      paymentMethodId: this.selectedPaymentMethod.Id,
      contactId: this.selectedContact.Id
    };
    try {
      const res = await handleSinglePayment({ singlePayment });
      if (!res.error) {
        setTimeout(() => {
          alert(
            "Payment Successful. You will now be redirected back to the record."
          );  
          this.returnToRecord();
          this.showComponent = true;  
        }, 3500)
      } else {
        console.error(res.message);
        this.handleError(null, res.message);
      }
    } catch (err) {
      console.error(err)
      this.handleError(
        err,
        "An error has occured while submitting the payment."
      );
      this.showComponent = true;
    }
  }

  async handleMultiplePayments() {
    const inputs = this.template.querySelectorAll(
      `[data-type="multiplePayment"]`
    );
    const allValid = [...inputs].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    if (!allValid) {
      this.errorMessages = ["Please fill out all required fields."];
      this.showComponent = true;
      return;
    }

    this.errorMessages = [];
    const fields = {};
    inputs.forEach((ip) => {
      let value = ip.value;
      if (ip.type === "checkbox") {
        value = ip.checked;
      } else if (!isNaN(value)) {
        value = Number(value);
      }
      fields[ip.dataset.key] = value;
    });

    if(fields.paymentAmount < 0.01) {
      this.errorMessages = ["Please enter a valid amount."];
      this.showComponent = true;
      return;
    }

    const financeFee = this.financeFeeWaved || Number(fields.numberOfPayments) <= 1 ? 0 : fields.financeFee;
    if(financeFee) {
      fields.paymentAmount = Number(fields.paymentAmount + Number((financeFee / fields.numberOfPayments).toFixed(2)))
    }
    
    const changeDifference = this.calculateChange(
      this.amountDue - fields.firstPayment + financeFee,
      fields.numberOfPayments,
      fields.paymentAmount
    );
    console.log(fields);
    if (changeDifference) {
      const newvalue = Number(
        (fields.firstPayment + changeDifference).toFixed(2)
      );
      if (
        !confirm(
          `The first payment amount will be adjusted to ${newvalue} to account for rounding discrepancies. Do you want to continue?`
        )
      ) {
        return;
      }
      fields.firstPayment = newvalue;
    }

    try { 
      const multiplePayment = {...fields, contactId: this.selectedContact.Id, salesOrderId: this.recordId, paymentMethodId: this.selectedPaymentMethod.Id};
      const res = await handleMultiplePayments({ multiplePayment });
      if(!res.error) {
        setTimeout(() => {
          alert(
            "Payment Successful. You will now be redirected back to the record."
          );  
          this.returnToRecord();
          this.showComponent = true;
        }, 3500)


      } else {
        this.handleError(null, res.message);
      }
    } catch(err) {
      this.handleError(err, "An error has occured while submitting the payment.");
      this.showComponent = true;
    }
  }

  async handleFormSubmit(evt) {
    evt.preventDefault();
    const customInputFields = this.template.querySelectorAll(
      `[data-type='_paymentMethod']`
    );
    const defaultFields = this.template.querySelectorAll(
      `[data-type='Payment_Method__c']`
    );
    let fields = evt.detail.fields;

    const allValid = [...customInputFields, ...defaultFields].reduce(
      (validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
      },
      true
    );
    if (allValid) {
      this.showComponent = false;
      this.errorMessages = [];
      
      defaultFields.forEach((inp) => {
        fields[inp.dataset.field] = inp.value;
      });

      if (!this.selectedContact["MX_Customer_Id__c"]) {
        await this.addCustomerToMerchant();
      }
      const customRecord = {
        customerMerchantId: this.selectedContact["MX_Customer_Id__c"]
      };

      customInputFields.forEach((inpt) => {
        customRecord[inpt.dataset.field.replace("_", "")] = inpt.value;
      });

      await this.savePaymentMethodToMerchant(fields, customRecord);
    } else {
      this.errorMessages = ["Please fill out all required fields and make sure your inputs are valid."];
    }
  }

  async handleFormSuccess(evt) {
    await this.loadPaymentMethods(this.selectedContact.Id);
    this.paymentMethods = Object.values(this.paymentMethodsMap).map((pm) => {
      const expDate = new Date(pm.Expiration_Date__c);
      const expMonth =
        expDate.getMonth() + 1 < 10
          ? "0" + (expDate.getMonth() + 1)
          : expDate.getMonth() + 1;
      const expYear = expDate.getFullYear();
      return {
        ...pm,
        _expiration: `${expMonth}/${expYear}`
      };
    });
    this.showComponent = true;
    this.showCardForm = false;
  }

  async addCustomerToMerchant() {
    try {
      console.log("add customer to merchant");
      console.log(this.selectedContact);
      const res = await saveCustomer({ record: this.selectedContact });
      console.log(res);
      this.selectedContact = res;
    } catch (err) {
      this.handleError(
        err,
        "An error has occured while retrieving customer data from the merchant."
      );
    }
  }

  async savePaymentMethodToMerchant(record, customRecord) {
    try {
      const fields = await savePaymentMethod({ record, customRecord });
      console.log(fields);
      this.handleFormSuccess();
    } catch (err) {
      console.error(err);
      this.handleError(
        err,
        "An error has occured while saving the payment method to the merchant."
      );
    }
  }

  handleCardNumberCommit() {
    const fieldData = "_cardNumber";
    const field = this.template.querySelector(`[data-field="${fieldData}"]`);

    const value = field.value;
    const cardNumber = value.replace(/[^0-9]/g, "");
    console.log(cardNumber);
    if (this.validateCardNumber(cardNumber)) {
      field.value = cardNumber;
      field.setCustomValidity("");
    } else {
      field.setCustomValidity("Invalid card number");
      field.reportValidity();
    }
  }

  handleTotalScheduledAmountChange(event) {
    const val = event.detail.value;
    const differenceChange = this.totalScheduledAmount - val;
    this.totalScheduledAmount = val;
    const newFirstPayment = this.firstPayment + differenceChange;
    this.firstPayment = newFirstPayment;
    this.firstPaymentPercent = Number(
      ((newFirstPayment / this.amountDue) * 100).toFixed(2)
    );
  }

  validateCardNumber(number) {
    //Check if the number contains only numeric value
    //and is of between 13 to 19 digits
    const regex = new RegExp("^[0-9]{13,19}$");
    if (!regex.test(number)) {
      return false;
    }

    return this.luhnCheck(number);
  }

  luhnCheck(val) {
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
  }

  toggleForm() {
    this.errorMessages = [];
    this.showCardForm = !this.showCardForm;
    this.showMainForm = !this.showMainForm;
    if (this.showCardForm) {
      this.showComponent = false;
      setTimeout(() => {
        this.showComponent = true;
      }, 1000);
    }
  }

  toggleMultiple() {
    this.isMultiple = !this.isMultiple;
  }

  returnToRecord() {
    window.location.pathname = "/" + this.recordId;
  }

  calculateChange(x, y, z) {
    return Number((x - Number((y * z).toFixed(2))).toFixed(2));
  }

  handleSchedPaymentsChange(evt) {
    this.numberOfSchedulePayments = evt.detail.value;
    this.scheduledPaymentComboboxValue = evt.detail.value;
  }

  get totalScheduledAmount() {
    const numberOfPayments =
      !isNaN(this.multiplePayment.numberOfPayments) ||
      this.multiplePayment.numberOfPayments != ""
        ? Number(this.multiplePayment.numberOfPayments)
        : 0;
    // this.scheduledPaymentAmount = Number(
    //   (this.totalScheduledAmountLocal / numberOfPayments).toFixed(2)
    // );

    return Number(parseFloat(this.totalScheduledAmountLocal).toFixed(2)) || Number(parseFloat(this.maxTotalScheduledAmount).toFixed(2));
  }

  set totalScheduledAmount(val) {
    this.totalScheduledAmountLocal = val;
  }

  get maxTotalScheduledAmount() {
    return this.amountDue - this.firstPayment;
  }

  // get scheduledPaymentAmount() {
  //   return this.multiplePayment.paymentAmount;
  // }

  // set scheduledPaymentAmount(value) {
  //   this.multiplePayment = {
  //     ...this.multiplePayment,
  //     paymentAmount: value
  //   };
  // }

  get numberOfSchedPaymentsOptions() {
    let options = [];
    // if(!this.record.allowWaiver) {
    //   options.push({ label: "2 Scheduled Payments (No Fee)", value: "2" });
    // } else {
      options = [{ label: "1 Scheduled Payment", value: "1" }];
      if (Number(this.amountDue) >= 500 && this.record.allowWaiver) {
        options.push({ label: "2 Scheduled Payments", value: "2" });
      }
  
      if (!this.record.allowWaiver) {
        options.push({ label: "2 Scheduled Payments (No Fee)", value: "2" });
      }
  
      if (Number(this.amountDue) >= 1000) {
        options.push({ label: "5 Scheduled Payments", value: "5" });
      }  
    // }

    return options;
  }

  get minFirstPayPercent() {
    return this.record.isAmProfile ? 10 : 0.01;
  }

  get maxFirstPayPercent() {
    return 100;
  }

  get firstPaymentPercent() {
    return this.firstPaymentPercentLocal;
  }

  set firstPaymentPercent(val) {
    this.firstPaymentPercentLocal = Number(val.toFixed(2));
  }

  get firstPayment() {
    return this.firstPaymentLocal;
  }

  set firstPayment(val) {
    console.log("val numeric", val);
    this.firstPaymentLocal = Number(val.toFixed(2));
    // this.scheduledPaymentAmount = Number(
    //   (this.amountDue - val).toFixed(2)
    // );
  }

  get amountDue() {
    // return !this.isMultiple
    //   ? this.record.amountDue
    //   : this.financeFeeWaved
    //   ? this.record.amountDue
    //   : this.record.amountDue + Number(this.financeFee.toFixed(2));
    return this.record.amountDue;
  }

  get financeFeeRate() {
    return this.numberOfSchedulePayments &&
     this.numberOfSchedulePayments == 2 ?
     (this.record.allowWaiver ? 0.015 : 0) : this.numberOfSchedulePayments == 5 ?
     0.03 : 0;
  }

  get showWaiveCheckbox() {
    return !(this.numberOfSchedulePayments == 2 && !this.record.allowWaiver)
  }

  get financeFee() {
    return this.numberOfSchedulePayments > 1 ?
    Number(
        (this.record.orderTotal - this.firstPayment) *
        (this.financeFeeRate)
      
    ):
    0;
  }

  get contactLookupButtonLabel() {
    return this.showLookup ? "Cancel" : "Choose from a Different Contact";
  }

  get numberOfSchedulePayments() {
    return this.numberOfSchedulePaymentsLocal;
  }

  set numberOfSchedulePayments(val) {
    this.numberOfSchedulePaymentsLocal = Number(val);
  }

  get scheduledPaymentAmount() {
    return this.numberOfSchedulePayments
      ? Number(
          (this.totalScheduledAmount / this.numberOfSchedulePayments).toFixed(2)
        )
      : 0;
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
    for (let i = 0; i < 11; i++) {
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
}