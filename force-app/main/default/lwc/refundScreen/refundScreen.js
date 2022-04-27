import saveRecord from "@salesforce/apex/LWC.saveRecord";
import refundPayment from "@salesforce/apex/Zealynx.refundPayment";
import savePaymentMethod from "@salesforce/apex/Zealynx.savePaymentMethod";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { api, LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import voidPayment from "@salesforce/apex/Zealynx.voidPayment";
import ID_FIELD from "@salesforce/schema/Payment__c.Id";
import STATUS_FIELD from "@salesforce/schema/Payment__c.Status__c";
import doQuery from "@salesforce/apex/LWC.doQuery";
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';


export default class RefundScreen extends NavigationMixin(LightningElement) {
  @api recordId;
  restrictedMessage = "This is not a valid credit card payment transaction."
  showScreen = true;
  isVoid = false;
  isRefund = false;
  paymentInfo = {};
  sectionDisabled = false;
  refundAmount = 0;
  allowRefund = true;
  errorMessage;
  showLink = false;
  recordLink;
  disableRefundButton = false;
  isLoading = true;
  disableVoidButton = false;
  showNotification = false;
  toastTitle;
  toastMessage;
  toastVariant = "success";
  disallowUpdatePaymentMethod = false;

  currentPaymentMethod;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Payment__c.Amount__c",
      "Payment__c.Payment_Method__c",
      "Payment__c.Payment_Method__r.Billing_First_Name__c",
      "Payment__c.Payment_Method__r.Billing_Last_Name__c",
      "Payment__c.Payment_Method__r.Merchant_Token__c",
      "Payment__c.CardType__c",
      "Payment__c.Last_Four_Digits__c",
      "Payment__c.Date__c",
      "Payment__c.Status__c",
      "Payment__c.Payment_Token__c",
      "Payment__c.Sales_Order__c",
      "Payment__c.Sales_Order__r.Name",
      "Payment__c.Contact__c",
      "Payment__c.Account__c",
      "Payment__c.Transaction_Type__c",
      "Payment__c.Transaction_Id__c",
      "Payment__c.MX_Payment_Id__c",
      "Payment__c.Payment_Method__r.MX_Customer_Id__c",
    ]
  })
  wiredRecord({ error, data }) {
    if (error) {
      console.error(error);
      this.sectionDisabled = true;
      this.isLoading = false;
    } 
    else if (data && (!data.fields.hasOwnProperty("Payment_Method__c") || data.fields.Payment_Method__c.value == null)) {
      this.showScreen = false;
    } else if (data && data.fields.hasOwnProperty("Payment_Method__c") && data.fields.Payment_Method__c.value != null) {
      if(data.fields.Transaction_Type__c.value != "Payment" || data.fields.Status__c.value == "Voided") {
        this.showScreen = false;
      } else if (data.fields.Status__c.value != "Completed" && data.fields.Transaction_Type__c.value == "Payment" ) {
        this.sectionDisabled = true;
      } else {
        this.disallowUpdatePaymentMethod = true;
      }

      if(new Date(data.fields.Date__c.value + "T01:00:00").toDateString() == new Date().toDateString()) {
        this.allowRefund = false;
      } else {
        this.allowRefund = true;
      }
      let paymentRecord = {};
      for (const [key, value] of Object.entries(data.fields)) {
        if (key[key.length - 1] != "r") {
          paymentRecord[key] = value.value;
        } else if (value.value.hasOwnProperty("fields")) {
          let childRecords = {};
          for (const [childKey, childValue] of Object.entries(
            value.value.fields
          )) {
            childRecords[childKey] = childValue.value;
          }
          paymentRecord[key] = childRecords;
        }
      }
      this.currentPaymentMethod = paymentRecord["Payment_Method__c"];
      this.refundAmount = paymentRecord["Amount__c"];
      this.paymentInfo = paymentRecord;
      this.isLoading = false;
    } 
  }

  @wire(getRecord, {
    recordId: strUserId,
    fields: [PROFILE_NAME_FIELD]
  })
  wireUser({error, data}) {
    if(error) {
      console.error(error);
    } else if(data) {
      if(!["FSP - Accounting +", "System Administrator"].includes(data.fields.Profile.value.fields.Name.value)) {
        this.sectionDisabled = true;
      }
    }
  }

  handleChange(evt) {
    const record = evt.target.dataset.record;
    const name = evt.target.dataset.name;
    if (name == "refund") {
      this.refundAmount = evt.detail.value;
    } else if (name == "current-method") {
      this.currentPaymentMethod = evt.target.value;
    } else if (record == "paymentMethod") {
      this.paymentMethodData[name] = evt.target.value;
    }
  }
  formatDate() {
    let d = new Date();
    let month = "" + (d.getMonth() + 1);
    let day = "" + d.getDate();
    let year = d.getFullYear();

    if (month.length < 2) month = "0" + month;
    if (day.length < 2) day = "0" + day;
    return [year, month, day].join("-");
  }

  async handleVoid() {
    this.isLoading = true;
    this.disableVoidButton = true;
    const voidRequest = {
      id: Number(this.paymentInfo.MX_Payment_Id__c)
    };
    try {
      const retVal = await voidPayment({ payment: voidRequest });
      const fields = {};
      fields[ID_FIELD.fieldApiName] = this.recordId;
      fields[STATUS_FIELD.fieldApiName] = "Voided";
      const recordInput = { fields };
      await updateRecord(recordInput);
      this.restrictedMessage = "This payment has been voided successfully. Please refresh the page to see the changes."
      this.showScreen = false;
    } catch (err) {
      console.error(err);
      await this.handleRefund();
    }
  }

  async handleRefund(isFromVoid = false) {
    let addedMessage = "";
    if (this.refundAmount <= 0) {
      this.toastVariant = "error";
      this.toastMessage = "This amount is invalid.";
      this.toastTitle = "Error";
      this.showNotification = true;
      this.isLoading = false;
      return;
    }
    if (isFromVoid) {
      addedMessage = "This payment has been settled and could not be voided. ";
    }
    if (
      confirm(
        addedMessage +
          "Are you sure that you want to process a refund of " +
          this.refundAmount +
          " on card ending in " +
          this.paymentInfo.Last_Four_Digits__c +
          "?"
      )
    ) {
      this.disableRefundButton = true;
      const newRefundPayment = {
        paymentToken: this.paymentInfo.Payment_Token__c,
        amount: 0 - Number(this.refundAmount),
        customerId: parseInt(this.paymentInfo.Payment_Method__r.MX_Customer_Id__c)
      };
      try {
        const returnedVal = await refundPayment({ payment: newRefundPayment });
        if (returnedVal.isSuccess) {
          if (returnedVal.payment.status != "Approved") {
            alert("We cannot process this refund.");
            this.isLoading = false;
            this.disableRefundButton = false;
            return;
          }
          let newPaymentRecord = {
            sobjectType: "Payment__c",
            Sales_Order__c: this.paymentInfo.Sales_Order__c,
            Status__c: "Completed",
            Amount__c: newRefundPayment.amount,
            Contact__c: this.paymentInfo.Contact__c,
            Account__c: this.paymentInfo.Account__c,
            Date__c: this.formatDate(),
            Payment_Method__c: this.paymentInfo.Payment_Method__c,
            Payment_Token__c: returnedVal.payment.paymentToken,
            Transaction_Type__c: "Refund",
            Payment_Type__c: "Credit Card",
            MX_Payment_Id__c: "" + returnedVal.payment.id,
            Transaction_Id__c: "" + returnedVal.payment.reference,
            Authorization_Id__c: "" + returnedVal.payment.authCode,
            RelatedPayment__c: this.recordId
          };
          const savedPmtRecord = await saveRecord({ record: newPaymentRecord });
          if (savedPmtRecord.hasOwnProperty("Id")) {
            this.isLoading = false;
            this.disableRefundButton = false;
            this.navigateToRecordViewPage(savedPmtRecord.Id);
            this.errorMessage = "";
            this.showLink = true;
            this.recordLink = "/" + savedPmtRecord.Id;
            this.isRefund = false;
            this.isVoid = false;
          }
        } else {
          if (returnedVal.errorMessage) {
            this.errorMessage = returnedVal.errorMessage;
            console.error(returnedVal.errorMessage);
            this.isLoading = false;
            return;
          }
        }
      } catch (err) {
        console.error(err);
        this.errorMessage = "A server error has occured.";
        this.isLoading = false;
      }
    }
    this.isLoading = false;
  }

  async handleClick(evt) {
    const title = evt.target.title;
    if (this.showLink) {
      this.showLink = false;
    }
    if (title == "refund") {
      this.isRefund = true;
      this.isVoid = false;
    } else if (title == "void") {
      this.isRefund = false;
      this.isVoid = true;
    } else if (title == "completeRefund") {
      this.isLoading = true;
      await this.handleRefund();
    } else if (title == "voidPayment") {
      await this.handleVoid();
    } else if (title == "paymentMethod") {
      // open link to VF Page
      window.open(
        "/apex/updatePaymentMethodVfPage?id=" + this.recordId,
        "_blank"
      );
    }
  }

  handleCloseToast() {
    this.showNotification = false;
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

  navigateToRecordViewPage(recordId) {
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