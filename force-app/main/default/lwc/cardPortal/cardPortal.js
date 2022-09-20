import { getRecord } from 'lightning/uiRecordApi';
import { LightningElement, api, track, wire } from 'lwc';
import saveCustomer from "@salesforce/apex/Zealynx.saveCustomer";
import savePaymentMethod from "@salesforce/apex/Zealynx.savePaymentMethod";
import doQuery from "@salesforce/apex/LWC.doQuery";
import saveRecord from "@salesforce/apex/LWC.saveRecord";

const CONTACT_FIELDS = ['Contact.FirstName', 'Contact.LastName', 'Contact.MailingStreet', 'Contact.MailingCity', 'Contact.MailingState', 'Contact.MailingPostalCode', 'Contact.MailingCountry', 'Contact.MX_Customer_Id__c'];

const STAGE_MAP = {
  1: 'billing',
  2: 'payment',
  3: 'review',
  4: 'success'
}

const SECTION_HEADER_MAP = {
  1: 'Billing Information',
  2: 'Card Information',
  3: 'Review & Submit',
  4: 'Success'
}

const FIELD_LABEL_MAP = {
  Billing_First_Name__c: 'First Name',
  Billing_Last_Name__c: 'Last Name',
  Billing_Street__c: 'Billing Street',
  Billing_City__c: 'Billing City',
  Billing_State__c: 'Billing State',
  Billing_Postal_Code__c: 'Billing Postal Code',
  Billing_Country__c: 'Billing Country',
  Card_Type__c: 'Card Type',
  _cardNumber: 'Card Number',
  _expMonth: 'Expiration Month',
  _expYear: 'Expiration Year',
}

export default class CardPortal extends LightningElement {
  @api recordId;
  @api orderId;

  mxCustId;
  isLoading = true;
  paymentAmount;
  errorMessage;
  loadingErrorMessage;
  stageNumber = 1;
  logoUrl =
  "https://fivestarprofessional--c.na169.content.force.com/servlet/servlet.ImageServer?id=015d00000060AVl&oid=00Dd0000000gsfl";
  pmData = {
    Billing_First_Name__c: '',
    Billing_Last_Name__c: ' ',
    Billing_Street__c: '',
    Billing_City__c: '',
    Billing_State__c: '',
    Billing_Postal_Code__c: '',
    Billing_Country__c: 'United States',
    Card_Type__c: '',
    _cardNumber: '',
    _expMonth: '',
    _expYear: ''
  }

  @wire(getRecord, { recordId: '$recordId', fields: CONTACT_FIELDS })
  wiredRecord({ error, data }) {
    if(error) {
      let message = 'Unable to load the page. Please try again later.';
      if(Array.isArray(error.body)) {
        message = error.body.map(e => e.message).join(', ');
      } else if (typeof error.body.message === 'string') {
        message = error.body.message;
      }
      this.loadingErrorMessage = message;
      this.isLoading = false;
    } else if (data) {
      this.pmData = {
        Billing_First_Name__c: data.fields.FirstName.value,
        Billing_Last_Name__c: data.fields.LastName.value,
        Billing_Street__c: data.fields.MailingStreet.value,
        Billing_City__c: data.fields.MailingCity.value,
        Billing_State__c: data.fields.MailingState.value,
        Billing_Postal_Code__c: data.fields.MailingPostalCode.value,
        Billing_Country__c: data.fields.MailingCountry.value || 'United States'
      };

      if(data.fields.MX_Customer_Id__c && data.fields.MX_Customer_Id__c.value) {
        this.mxCustId = data.fields.MX_Customer_Id__c.value;
      }
      this.isLoading = false;
    }
  }

  connectedCallback() {
    this.isLoading = false;
  }

  handleClick(evt) {
    if(evt.target.dataset.name == 'previous') {
      this.stageNumber--;
    } else if (evt.target.dataset.name == 'next') {
      if(this.stageNumber < 3) {
        this.handleNext();
      } else {
        this.handleSubmit();
      }
    }
  }

  setDate() {
    return new Date(
      parseFloat(this.pmData._expYear) + 2000,
      parseFloat(this.pmData._expMonth),
      0
    );
  }

  async handleSubmit() { 
    this.isLoading = true;
    if(!this.mxCustId) {
      const updContact = await this.handleSaveCustomer();
      this.mxCustId = updContact.MX_Customer_Id__c;
    }

    const paymentMethod = await this.handleSavePaymentMethod();
    if (!paymentMethod.token) {
      this.isLoading = false;
      this.errorMessage =
        "Unable to process this card. We apologize for the inconvenience.";
      return;
    }
    
    let paymentMethodData = {};

    for(const [key, value] of Object.entries(this.pmData)) {
      if(key[0] != '_') {
        paymentMethodData[key] = value;
      }
    }

    paymentMethodData.Expiration_Date__c = this.setDate();
    paymentMethodData.Last_4_Digits_of_Card__c = this.pmData._cardNumber.substring(this.pmData._cardNumber.length - 4);
    paymentMethodData.ExternalId__c = "" + paymentMethod.id;
    paymentMethodData.Merchant_Token__c = paymentMethod.token;
    paymentMethodData.Contact__c = this.recordId;

    let paymentMethodres = {};

    try {
      let queryString = `SELECT Id FROM Payment_Method__c WHERE Merchant_Token__c = '${paymentMethod.token}'`;
      const queriedRecords = await doQuery({ queryString: queryString });
      if(queriedRecords.length > 0) { 
        paymentMethodData.Id = queriedRecords[0].Id;
      } else {
        paymentMethodData.sobjectType = "Payment_Method__c";
      }
      paymentMethodres = await saveRecord({ record: paymentMethodData });
      this.stageNumber++;
      this.isLoading = false;
    } catch (error) {
      let message = 'Unable to process this card. Please try again later.';
      if(Array.isArray(error.body)) {
        message = error.body.map(e => e.message).join(', ');
      } else if (typeof error.body.message === 'string') {
        message = error.body.message;
      }
      this.errorMessage = message;
      this.isLoading =false;
      console.error(error);
    }
  }

  async handleSaveCustomer() {
    const contactRecord = { ...this.pmData };
    const CustomerResource = {
      name: contactRecord.Billing_First_Name__c + " " + contactRecord.Billing_Last_Name__c,
      firstName: contactRecord.Billing_First_Name__c,
      lastName: contactRecord.Billing_Last_Name__c,
      REPLACE_number: this.recordId,
      address1: contactRecord.Billing_Street__c,
      address2: "",
      city: contactRecord.Billing_City__c,
      state: contactRecord.Billing_State__c,
      zip: contactRecord.Billing_Postal_Code__c.length == 5 ? contactRecord.Billing_Postal_Code__c : "0" + contactRecord.Billing_Postal_Code__c,
      customerType: "Business"
    };
    try {
      const res = await saveCustomer({ customer: CustomerResource });
      if (!res.isSuccess) {
      if (res.errorMessage && res.errorCode) {
        console.error(res.errorCode + " : " + res.errorMessage);
        this.errorMessage = res.errorMessage;
        this.isLoading =false;
        return;
      }
    }
    const updatedContact = {
      sobjectType: "Contact",
      MX_Customer_Id__c: res.customer.id + "",
      Id: this.recordId
    };
    const savedContact = await saveRecord({ record: updatedContact });
    return savedContact;
    } catch (error) {
      let message = 'Unable to process your request. Please try again later.';
      if(Array.isArray(error.body)) {
        message = error.body.map(e => e.message).join(', ');
      } else if (typeof error.body.message === 'string') {
        message = error.body.message;
      }
      this.errorMessage = message;
      this.isLoading =false;
      console.error(error);
    }
  }

  async handleSavePaymentMethod() {
    const CreditCardResource = {
      customerId: parseInt(this.mxCustId),
      isDefault: false, // convert to boolean if undefined
      // last4: last4,
      expiryMonth: "" + this.pmData._expMonth,
      expiryYear: "" + this.pmData._expYear,
      name: this.pmData.Billing_First_Name__c + " " + this.pmData.Billing_Last_Name__c,
      avsStreet: "" + this.pmData.Billing_Street__c,
      avsZip: this.pmData.Billing_Postal_Code__c.length == 5 ? "" + this.pmData.Billing_Postal_Code__c : "0" + this.pmData.Billing_Postal_Code__c,
      REPLACE_number: "" + this.pmData._cardNumber,
      alias:
        this.pmData.Billing_First_Name__c +
        " " +
        this.pmData.Billing_Last_Name__c +
        " " +
        this.pmData.Card_Type__c,
      // cvv: "" + this.paymentEntry.SecurityCode
    };
    try {
      const res = await savePaymentMethod({ creditCard: CreditCardResource });
      if (!res.isSuccess) {
        console.error(res.errorMessage);
        this.isLoading = false;
        this.errorMessage =
          "An error has occured. We apologize for the inconvenience.";
        return;
      }
      return res.creditCard;
    } catch (error) {
      let message = 'Unable to process your request. Please try again later.';
      if(Array.isArray(error.body)) {
        message = error.body.map(e => e.message).join(', ');
      } else if (typeof error.body.message === 'string') {
        message = error.body.message;
      }
      this.errorMessage = message;
      this.isLoading =false;
      console.error(error);
    }
  }

  handleNext() {
    const inputs = [...this.template.querySelectorAll(`[data-stage="${this.stage}"]`)];
    let isValid = true;

    isValid = inputs.reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    if(isValid) {
      const inputData = {};
      inputs.forEach(input => {
        inputData[input.dataset.field] = input.value;
      });
      if(this.isPayment) {
        let rawCardNumber = inputData._cardNumber.replaceAll(' ', '').replaceAll('-', '');
        if(!this.validateCardNumber(rawCardNumber)) {
          this.errorMessage = 'Please enter a valid card number.';
          return;
        } else {
          this.errorMessage = null;
          inputData._cardNumber = rawCardNumber;
        }
        
      }
      this.pmData = { ...this.pmData, ...inputData };
      console.log('stage number increase');
      this.stageNumber++;
    } else { 
      return;
    }
  }

 validateCardNumber(number) {
    //Check if the number contains only numeric value  
    //and is of between 13 to 19 digits
    const regex = new RegExp("^[0-9]{13,19}$");
    if (!regex.test(number)){
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
    return (checksum % 10) == 0;
}

  get successHeader() {
    return this.orderId ? 'Thank you for your payment!' : 'Your payment method has been saved!';
  }

  get successBody() {
    return this.orderId ? 'Your payment has been processed successfully. You may now close this window.' : 'You may now close this window.';
  }


  get isBilling() {
    return this.stage === 'billing';
  }

  get stage() {
    return STAGE_MAP[this.stageNumber];
  }

  get isPayment(){
    return this.stage === 'payment';
  }

  get isReview(){
    return this.stage === 'review';
  }

  get isSuccess() {
    return this.stage === 'success';
  }

  get reviewData() {
    if(!this.isReview) {
      return [];
    } else {
      return Object.entries(this.pmData).map(([key, value]) => ({ label: FIELD_LABEL_MAP[key], value }));
    }
  }

  get nextButtonLabel() {
    return this.isReview ? 'Submit' : 'Next';
  }

  get sectionHeader() {
    return SECTION_HEADER_MAP[this.stageNumber];
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
      { label: "01 - Jan", value: "01" },
      { label: "02 - Feb", value: "02" },
      { label: "03 - Mar", value: "03" },
      { label: "04 - Apr", value: "04" },
      { label: "05 - May", value: "05" },
      { label: "06 - Jun", value: "06" },
      { label: "07 - Jul", value: "07" },
      { label: "08 - Aug", value: "08" },
      { label: "09 - Sep", value: "09" },
      { label: "10 - Oct", value: "10" },
      { label: "11 - Nov", value: "11" },
      { label: "12 - Dec", value: "12" }
    ];
  }

  get yearOptions() {
    const yearValues = [];
    for (let i = 0; i <= 10; i++) {
      yearValues.push({
        label: new Date().getFullYear() + i,
        value: ("" + (new Date().getFullYear() + i)).slice(-2)
      });
    }
    return yearValues;
  }

  get header() { 
    return this.orderId ? 'Checkout' : 'Add Payment Method';
  }

}