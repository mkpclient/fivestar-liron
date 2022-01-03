import doQuery from "@salesforce/apex/LWC.doQuery";
import saveMultipleRecords from "@salesforce/apex/LWC.saveMultipleRecords";
import { getRecord } from "lightning/uiRecordApi";
import { api, LightningElement, wire } from "lwc";
import makePayment from "@salesforce/apex/Zealynx.makePayment";
import savePaymentMethod from "@salesforce/apex/Zealynx.savePaymentMethod";

const FIELD_MAP = {
  FirstName: "Billing_First_Name__c",
  LastName: "Billing_Last_Name__c",
  MailingStreet: "Billing_Street__c",
  MailingCity: "Billing_City__c",
  MailingState: "Billing_State__c",
  MailingCountry: "Billing_Country__c",
  MailingPostalCode: "Billing_Postal_Code__c"
};

export default class UpdatePaymentMethod extends LightningElement {
  @api recordId;
  allowPayment = false;
  chooseExisting = false;
  paymentMethodOptions = [];
  currentPaymentMethod;
  disableSave = false;
  isCreateNew = false;
  paymentMethodData = {
    Id: "",
    Card_Type__c: "",
    _cardNumber: "",
    _expiryMonth: "",
    _expiryYear: "",
    _cvv: 123,
    Billing_First_Name__c: "",
    Billing_Last_Name__c: "",
    Billing_Street__c: "",
    Billing_City__c: "",
    Billing_State__c: "",
    Billing_Country__c: "",
    Billing_Postal_Code__c: ""
  };
  paymentInfo = {};
  showNotification = false;
  toastTitle;
  toastMessage;
  paymentAmount;
  toastVariant = "success";
  MX_Customer_Id__c;
  isUpdateExisting = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Payment__c.Amount__c",
      "Payment__c.Payment_Method__c",
      "Payment__c.Payment_Method__r.Billing_First_Name__c",
      "Payment__c.Payment_Method__r.Billing_Last_Name__c",
      "Payment__c.Payment_Method__r.Default__c",
      "Payment__c.Payment_Method__r.ExternalId__c",
      "Payment__c.Payment_Method__r.Merchant_Token__c",
      "Payment__c.Payment_Method__r.Expiration_Date__c",
      "Payment__c.CardType__c",
      "Payment__c.Last_Four_Digits__c",
      "Payment__c.Date__c",
      "Payment__c.Status__c",
      "Payment__c.Payment_Token__c",
      "Payment__c.Sales_Order__c",
      "Payment__c.Contact__c",
      "Payment__c.Contact__r.FirstName",
      "Payment__c.Contact__r.LastName",
      "Payment__c.Contact__r.MailingStreet",
      "Payment__c.Contact__r.MailingCity",
      "Payment__c.Contact__r.MailingState",
      "Payment__c.Contact__r.MailingCountry",
      "Payment__c.Contact__r.MailingPostalCode",
      "Payment__c.Contact__r.MX_Customer_Id__c",
      "Payment__c.Account__c",
      "Payment__c.Transaction_Type__c",
      "Payment__c.Transaction_Id__c"
    ]
  })
  wiredRecord({ error, data }) {
    if (error) {
      console.error(error);
    } else if (data) {
      if (
        data.fields.Status__c.value == "Declined" &&
        data.fields.Transaction_Type__c.value == "Payment"
      ) {
        this.allowPayment = true;
      }
      let paymentRecord = {};
      let methodData = {
        ...this.paymentMethodData
      };
      for (const [key, value] of Object.entries(data.fields)) {
        if (key[key.length - 1] != "r") {
          paymentRecord[key] = value.value;
        } else if (value.value.hasOwnProperty("fields")) {
          let childRecords = {};
          for (const [childKey, childValue] of Object.entries(
            value.value.fields
          )) {
            if (key == "Contact__r") {
              if (childKey == "MX_Customer_Id__c") {
                this.MX_Customer_Id__c = childValue.value;
                continue;
              }
              methodData[FIELD_MAP[childKey]] = childValue.value;
            } else {
              childRecords[childKey] = childValue.value;
            }
          }
          paymentRecord[key] = childRecords;
        }
      }
      this.currentPaymentMethod = paymentRecord["Payment_Method__c"];
      this.paymentMethodData = methodData;
      this.paymentAmount = paymentRecord["Amount__c"];
      this.paymentInfo = paymentRecord;
    }
  }

  setDate() {
    return new Date(
      this.paymentMethodData._expiryYear,
      this.paymentMethodData._expiryMonth,
      0
    ).getDate();
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

  async handleRetrievePaymentMethods() {
    const soql = `
      SELECT Id, Card_Type__c, ExternalId__c, Last_4_Digits_of_Card__c, Expiration_Date__c, Merchant_Token__c
      FROM Payment_Method__c
      WHERE Id != '${this.paymentInfo.Payment_Method__c}'
      AND Contact__c = '${this.paymentInfo.Contact__c}'
    `;
    try {
      const paymentMethods = await doQuery({ queryString: soql });
      if (paymentMethods.length < 1) {
        return [
          null,
          "There are no payment methods saved to this Contact record."
        ];
      } else {
        return [paymentMethods, null];
      }
    } catch (err) {
      console.error(err);
      return [null, err];
    }
  }

  async handleSave(records) {
    const res = await saveMultipleRecords({ records: records });
    return res;
  }

  handleCloseToast() {
    this.showNotification = !this.showNotification;
  }

  async handlePay(token) {
    let newRecord = {
      sobjectType: "Payment__c",
      Id: this.recordId,
      Payment_Method__c: this.currentPaymentMethod
    };
    const paymentResource = {
      amount: this.paymentAmount,
      paymentType: "Sale",
      entryClass: "WEB",
      cardAccountToken: token
    };
    const pmtData = await makePayment({ payment: paymentResource });
    if (!pmtData.isSuccess) {
      if (pmtData.errorMessage && pmtData.errorCode) {
        throw new Error(pmtData.errorCode + " : " + pmtData.errorMessage);
      }
    } else {
      if (pmtData.payment.status == "Approved") {
        newRecord.Status__c = "Completed";
      } else if (pmtData.payment.status == "Declined") {
        throw new Error(
          "This payment method was declined. Please select a different one or click 'Cancel' to go back to the previous screen."
        );
      }
      newRecord.Payment_Token__c = "" + pmtData.payment.paymentToken;
    }
    newRecord.Transaction_Id__c = "" + pmtData.payment.reference;
    newRecord.Authorization_Id__c = "" + pmtData.payment.authCode;
    newRecord.MX_Payment_Id__c = "" + pmtData.payment.id;
    newRecord.Transaction_Type__c = "Payment";
    return newRecord;
  }

  async loadAllRelatedPayments() {
    const soql = `
      SELECT Id
      FROM Payment__c
      WHERE Payment_Method__c = '${this.paymentInfo.Payment_Method__c}'
      AND Status__c='Scheduled'
      AND Sales_Order__c='${this.paymentInfo.Sales_Order__c}'
      AND Id != '${this.recordId}'
    `;

    const records = await doQuery({ queryString: soql });
    if (records.length > 0) {
      const retVal = [
        {
          sobjectType: "Payment__c",
          Id: this.recordId,
          Payment_Method__c: this.currentPaymentMethod
        }
      ];
      return [
        ...retVal,
        ...records.map((v) => ({
          sobjectType: "Payment__c",
          Id: v.Id,
          Payment_Method__c: this.currentPaymentMethod
        }))
      ];
    } else {
      return records;
    }
  }

  async vaultPaymentMethod() {
    let CreditCardResource = {
      customerId: parseInt(this.MX_Customer_Id__c),
      isDefault: this.paymentInfo.Payment_Method__r.Default__c,
      ...(this.paymentMethodData._expiryMonth && {
        expiryMonth: "" + this.paymentMethodData._expiryMonth
      }),
      ...(this.paymentMethodData._expiryYear && {
        expiryYear: "" + this.paymentMethodData._expiryYear
      }),
      ...(this.paymentMethodData.Billing_First_Name__c &&
        this.paymentMethodData.Billing_Last_Name__c && {
          name:
            this.paymentMethodData.Billing_First_Name__c +
            " " +
            this.paymentMethodData.Billing_Last_Name__c
        }),
      ...(this.paymentMethodData.Billing_Street__c && {
        avsStreet: "" + this.paymentMethodData.Billing_Street__c
      }),
      ...(this.paymentMethodData.Billing_Postal_Code__c && {
        avsZip: "" + this.paymentMethodData.Billing_Postal_Code__c
      }),
      ...(this.paymentMethodData._cardNumber &&
        this.isCreateNew && {
          REPLACE_number: "" + this.paymentMethodData._cardNumber
        }),
      ...(this.isCreateNew && {
        alias:
          this.paymentMethodData.Billing_First_Name__c +
          " " +
          this.paymentMethodData.Billing_Last_Name__c +
          " " +
          this.paymentMethodData.Card_Type__c
      }),
      ...(this.paymentMethodData._cvv && {
        cvv: "" + this.paymentMethodData._cvv
      })
    };

    console.log(this.paymentInfo);

    if (this.isUpdateExisting) {
      CreditCardResource.id = Number(
        this.paymentInfo.Payment_Method__r.ExternalId__c
      );
      CreditCardResource.token =
        this.paymentInfo.Payment_Method__r.Merchant_Token__c;
    }
    console.log(CreditCardResource);
    const res = await savePaymentMethod({ creditCard: CreditCardResource });
    console.log(res);
    if (!res.isSuccess && !this.isUpdateExisting) {
      console.error(res.errorMessage);
      throw new Error(res.errorMessage);
    }
    return res.creditCard;
  }

  async handleSavePaymentMethod(title) {
    this.disableSave = true;
    const isNew = title.includes("createPaymentMethod");
    const pmData = { ...this.paymentMethodData };
    let sfRecord = {};
    for (const [key, value] of Object.entries(pmData)) {
      if (key[0] != "_") {
        if (isNew && key == "Id") {
          continue;
        }

        if (!isNew && !value) {
          continue;
        }

        sfRecord[key] = value;
      }
    }

    if (!isNew && !sfRecord.hasOwnProperty("Id") && !sfRecord.Id) {
      sfRecord.Id = this.currentPaymentMethod;
    }

    if (!pmData._expiryMonth && this.paymentInfo.Payment_Method__r.Expiration_Date__c) {
      let month = "0" + new Date(this.paymentInfo.Payment_Method__r.Expiration_Date__c).getMonth() + 1;
      if(month.length > 2) {
        month = month.slice(1);
      }
      this.paymentMethodData._expiryMonth = month;
      pmData._expiryMonth = month;
    }

    if (!pmData._expiryYear && this.paymentInfo.Payment_Method__r.Expiration_Date__c) {
      let year = new Date(this.paymentInfo.Payment_Method__r.Expiration_Date__c).getFullYear();
      this.paymentMethodData._expiryYear = year;
      pmData._expiryYear = year;
    }



    if (pmData._expiryMonth || pmData._expiryYear) {
      sfRecord["Expiration_Date__c"] = new Date(
        this.paymentMethodData._expiryMonth +
          "-" +
          this.setDate() +
          "-" +
          pmData._expiryYear
      );
    }

    if (isNew) {
      sfRecord["Last_4_Digits_of_Card__c"] =
        this.paymentMethodData._cardNumber.slice(
          this.paymentMethodData._cardNumber.length - 4
        );
    }

    const cardData = await this.vaultPaymentMethod();

    if (!this.isUpdateExisting && cardData.id && cardData.token) {
      sfRecord["ExternalId__c"] = "" + cardData.id;
      sfRecord["Merchant_Token__c"] = "" + cardData.token;
    }
    sfRecord["sobjectType"] = "Payment_Method__c";
    sfRecord["Contact__c"] = this.paymentInfo.Contact__c;
    console.log(sfRecord);
    const res = await this.handleSave([sfRecord]);
    console.log(res);
    const pmtMethodId = res[0].Id;
    this.currentPaymentMethod = pmtMethodId;
    let pmtRecord = {
      sobjectType: "Payment__c",
      Id: this.recordId,
      Payment_Method__c: pmtMethodId
    };

    let compiledPmtRecords =
      title == "createPaymentMethodAll"
        ? await this.loadAllRelatedPayments()
        : [pmtRecord];

    if (this.allowPayment) {
      compiledPmtRecords[0] = await this.handlePay(cardData.token);
    }

    await this.handleSave(compiledPmtRecords);

    alert("Payment Method Saved");
    location.replace("/" + this.recordId);
  }

  async handleClick(evt) {
    const title = evt.target.title;

    if (title == "returnToRecord") {
      window.location.replace("/" + this.recordId);
    } else if (title == "fromExisting") {
      if (this.chooseExisting) {
        this.chooseExisting = false;
        this.isCreateNew = false;
        this.isUpdateExisting = false;
      } else {
        const [data, error] = await this.handleRetrievePaymentMethods();
        if (error) {
          this.toastTitle = "Error";
          this.toastMessage = error;
          this.toastVariant = "error";
          this.showNotification = true;
        } else {
          this.showNotification = false;
          this.paymentMethodOptions = data.map((v) => {
            const expMonth = new Date(v.Expiration_Date__c).getMonth() + 1;
            const expYear = new Date(v.Expiration_Date__c).getFullYear();
            let retVal = {
              id: v.ExternalId__c,
              token: v.Merchant_Token__c,
              value: v.Id,
              last4: v.Last_4_Digits_of_Card__c,
              label:
                v.Card_Type__c +
                "-" +
                v.Last_4_Digits_of_Card__c +
                "-exp" +
                ("0" + expMonth).substring(expMonth.length + 1 - 2) +
                "/" +
                expYear
            };
            return retVal;
          });
          this.chooseExisting = true;
        }
      }
    } else if (title == "saveExisting" || title == "saveAll") {
      if (
        !this.paymentMethodOptions.some(
          (v) => v.value == this.currentPaymentMethod
        )
      ) {
        this.toastVariant = "error";
        this.toastMessage = "Please make a valid selection.";
        this.toastTitle = "Error";
        this.showNotification = true;
        return;
      }
      this.showNotification = false;
      const record = {
        sobjectType: "Payment__c",
        Payment_Method__c: this.currentPaymentMethod,
        Id: this.recordId
      };

      let updatedRecords =
        title == "saveAll" ? await this.loadAllRelatedPayments() : [record];

      try {
        this.disableSave = true;
        if (
          this.allowPayment &&
          confirm(
            "This will process a payment of $" +
              this.paymentAmount +
              " to settle an outstanding balance before attaching this payment method to this payment."
          )
        ) {
          updatedRecords[0] = await this.handlePay(
            this.paymentMethodOptions.find(
              (v) => v.value == this.currentPaymentMethod
            ).token
          );
          await this.handleSave(updatedRecords);
        } else if (!this.allowPayment) {
          await this.handleSave(updatedRecords);
        } else {
          this.disableSave = false;
        }
        window.location.replace("/" + this.recordId);
      } catch (err) {
        this.toastVariant = "error";
        this.toastMessage = err;
        this.toastTitle = "Error";
        this.showNotification = true;
        console.error(err);
        return;
      }
    } else if (title == "updateExistingPaymentMethod") {
      this.isUpdateExisting = true;
      this.isCreateNew = false;
    } else if (title == "createNewPaymentMethod") {
      this.isCreateNew = true;
      this.isUpdateExisting = false;
    } else if (
      title == "createPaymentMethod" ||
      title == "createPaymentMethodAll" ||
      title == "updatePaymentMethod"
    ) {
      console.log(this.paymentMethodData);

      if (title != "updatePaymentMethod") {
        const inputs = [
          ...this.template.querySelectorAll("lightning-input"),
          ...this.template.querySelectorAll("lightning-combobox")
        ];
        const allValid = inputs.reduce((validSoFar, inputCmp) => {
          inputCmp.reportValidity();
          return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
          this.toastTitle = "Error";
          this.toastMessage = "Please fill in all required fields.";
          this.toastVariant = "error";
          this.showNotification = true;
          return;
        }
        if (!this.validateCardNumber(this.paymentMethodData._cardNumber)) {
          this.toastTitle = "Error";
          this.toastMessage = "This card is invalid.";
          this.toastVariant = "error";
          this.showNotification = true;
          return;
        }
        if (this.paymentMethodData._cvv < 100) {
          this.toastTitle = "Error";
          this.toastMessage = "This card's cvv is invalid.";
          this.toastVariant = "error";
          this.showNotification = true;
          return;
        }
      } else {
        const proceedWithSave = Object.entries(this.paymentMethodData).some(
          ([key, value]) => !!value
        );
        if (!proceedWithSave) {
          this.toastTitle = "Error";
          this.toastMessage = "You did not make any changes.";
          this.toastVariant = "error";
          this.showNotification = true;
          return;
        }

        if (this.paymentMethodData._cvv && this.paymentMethodData._cvv < 100) {
          this.toastTitle = "Error";
          this.toastMessage = "This card's cvv is invalid.";
          this.toastVariant = "error";
          this.showNotification = true;
          return;
        }
      }

      try {
        let shouldProceed = true;
        if (
          title == "createPaymentMethodAll" &&
          !confirm(
            "This will update all related scheduled payments to this record. Proceed?"
          )
        ) {
          shouldProceed = false;
        }
        if (
          this.allowPayment &&
          !confirm(
            "This will process a payment of $" +
              this.paymentAmount +
              " to settle an outstanding balance before attaching this payment method to this payment."
          )
        ) {
          shouldProceed = false;
        }

        if (shouldProceed) {
          await this.handleSavePaymentMethod(title);
          // window.location.replace("/" + this.recordId);
        } else {
          return;
        }
      } catch (err) {
        console.error(err);
        this.toastTitle = "Error";
        this.toastMessage = err;
        this.toastVariant = "error";
        this.showNotification = true;
      }
    }
  }

  handleChange(evt) {
    const record = evt.target.dataset.record;
    const name = evt.target.dataset.name;
    if (record == "paymentMethod") {
      this.paymentMethodData[name] = evt.target.value;
    } else if (name == "current-method") {
      this.disableSave = false;
      this.currentPaymentMethod = evt.target.value;
    }
  }

  get stateOptions() {
    return [
      { label: "", value: "" },
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
    for (let i = 0; i < 6; i++) {
      let y = new Date().getFullYear() + i;
      options.push({ label: "" + y, value: "" + y });
    }
    return options;
  }


  get showForm() {
    return this.isUpdateExisting || this.isCreateNew;
  }

}