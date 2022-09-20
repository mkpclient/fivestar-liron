import { LightningElement, api, track } from "lwc";
import doQuery from "@salesforce/apex/LWC.doQuery";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ModalWidthCSS from "@salesforce/resourceUrl/ModalWidthCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import { getMLRecord } from "c/manageLinesHelpers";
import saveRecord from "@salesforce/apex/LWC.saveRecord";
import deleteRecordWithQuery from "@salesforce/apex/LWC.deleteRecordWithQuery";

// TODO: Implement better search
// TODO: Clean up code -- remove all unused variables and refactor duplicates.

export default class ManageLinesComponent extends LightningElement {
  @api recordId;
  @api fromPriceBookComponent;
  @api isVFPage;
  recordLink;
  headerTitle;
  SalesOrder__c;
  isLoaded = false;
  isButtonDisabled = false;
  isAddRecipient = false;
  currentPriceBookName;
  componentReady = false;
  orderLineId;
  isEditable = true;

  toggleRecipientView = () => {
    this.isAddRecipient = !this.isAddRecipient;
    this.isButtonDisabled = !this.isButtonDisabled;
  };

  handleOrderLineEdit = (evt) => {
    console.log(evt.detail);
    this.isButtonDisabled = true;
    this.orderLineId = evt.detail;
  };

  handleFormCancel = () => {
    this.isButtonDisabled = false;
    this.orderLineId = null;
  };

  handleFormSuccess = () => {
    this.orderLineId = null;
    this.isButtonDisabled = false;
  };

  loadSalesOrder = async () => {
    const [salesOrder, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "SalesOrder__c",
      fields:
        "Name, Account__c, Account__r.Name, Id, ContactBilling__c, Price_Book__c, Opportunity__r.Contact__c, DiscountPercent__c, Status_Picklist__c, Market__r.Publication_Year__c, Market__c",
      hasConditions: true,
      conditions: `WHERE Id='${this.recordId}'`
    });
    if (error !== null) {
      console.error("SALES ORDER ERROR: " + error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Loading Sales Order",
          message: "An internal error has occured. Please contact support.",
          variant: "error"
        })
      );
    } else {
      this.SalesOrder__c = salesOrder[0];
      // this.currentPriceBookName =salesOrder[0].PriceBookName__c;
      this.headerTitle = `Manage Products for ${salesOrder[0].Name}`;
      if (
        salesOrder &&
        salesOrder[0].Status_Picklist__c &&
        (salesOrder[0].Status_Picklist__c != "Draft" && salesOrder[0].Status_Picklist__c != "Unreleased" && salesOrder[0].Status_Picklist__c != "Pending Renewal")
      ) {
        this.isEditable = false;
        this.headerTitle =
          this.headerTitle + ` (This Sales Order is read-only.)`;
      }
    }
  };

  /* handleSave = async () => {
    this.componentReady = false;
    if (
      this.currentPriceBookName &&
      this.SalesOrder__c.PriceBookName__c !== this.currentPriceBookName
    ) {
      const modifiedSalesOrder = {
        sobjectType: "SalesOrder__c",
        Id: this.recordId,
        PriceBookName__c: this.currentPriceBookName
      };
      try {
        const newSalesOrder = await saveRecord({ record: modifiedSalesOrder });
        await this.loadSalesOrder();
        const queries = [
          `SELECT Id FROM Order_Line_Recipient__c WHERE Order__c='${this.recordId}'`,
          `SELECT Id FROM SalesOrderProductLine__c WHERE SalesOrder__c='${this.recordId}'`
        ];
        for (let i = 0; i < queries.length; i++) {
          await deleteRecordWithQuery({ queryString: queries[i] });
        }
      } catch (err) {
        console.log("ERROR UPSERTING SALES ORDER : ");
        console.error(err);
      }
    }
    const [isSuccess, newDiscount] = await this.template
      .querySelector("c-manage-lines-recipients")
      .saveData();
    if (!isSuccess) {
      this.componentReady = true;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save Failed",
          message:
            "An internal error occured during save. Please contact support.",
          variant: "error"
        })
      );
      return;
    }
    if (newDiscount) {
      const modifiedSalesOrder = {
        sobjectType: "SalesOrder__c",
        Id: this.recordId
      };
      modifiedSalesOrder.DiscountPercent__c = newDiscount;
      try {
        await saveRecord({ record: modifiedSalesOrder });
      } catch (err) {
        console.error(" ERROR UPDATING SALES ORDER : " + err);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Save Failed",
            message:
              "An internal error occured during save. Please contact support.",
            variant: "error"
          })
        );
        return;
      }
    }
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Save Success",
        message: "Save success!",
        variant: "success"
      })
    );
    this.componentReady = true;
  }; */

  handleCloseAction() {
    // if (this.fromPriceBookComponent) {
    //   this.dispatchEvent(new CustomEvent("close"));
    // } else {
    //   this.dispatchEvent(new CloseActionScreenEvent());
    // }
    window.location.replace('/' + this.recordId);
  }

  /* handleSaveAndClose = async () => {
    await this.handleSave();
    this.handleCloseAction();
  }; */

  connectedCallback() {
    Promise.all([loadStyle(this, ModalWidthCSS)]);
    document.addEventListener("click", () => console.log("CLICKED OUTSIDE"));

    // TODO: ADD CUSTOM CLICK EVENT FOR THE TREE GRID EDIT
  }

  disconnectedCallback() {
    this.isLoaded = false;
    this.SalesOrder__c = [];
  }

  handleChangePriceBook = async () => {
    this.componentReady = false;
    try {
      await this.loadSalesOrder();
      this.template.querySelector("c-manage-lines-recipients").clearData();
    } catch (err) {
      console.log("ERROR UPSERTING SALES ORDER : ");
      console.error(err);
    }
    this.componentReady = true;
  };

  // handleChangePriceBook = async (evt) => {
  //   const newPriceBookName = evt.detail;
  //   this.currentPriceBookName = newPriceBookName;
  //   const modifiedSalesOrder = {
  //     sobjectType: "SalesOrder__c",
  //     Id: this.recordId,
  //     PriceBookName__c: newPriceBookName
  //   };
  //   this.componentReady = false;
  //   try {
  //     const newSalesOrder = await saveRecord({ record: modifiedSalesOrder });
  //     await this.loadSalesOrder();
  //     const queries = [
  //       `SELECT Id FROM Order_Line_Recipient__c WHERE Order__c='${this.recordId}'`,
  //       `SELECT Id FROM SalesOrderProductLine__c WHERE SalesOrder__c='${this.recordId}'`
  //     ];
  //     for (let i = 0; i < queries.length; i++) {
  //       await deleteRecordWithQuery({ queryString: queries[i] });
  //     }
  //     this.template.querySelector("c-manage-lines-recipients").clearData();
  //   } catch (err) {
  //     console.log("ERROR UPSERTING SALES ORDER : ");
  //     console.error(err);
  //   }
  //   this.componentReady = true;
  // };

  handleAddLine = async (evt) => {
    const newOrderLine = {
      ...evt.detail,
      ContactShipping__c: this.SalesOrder__c.ContactBilling__c,
      SalesOrder__c: this.recordId,
      sobjectType: "SalesOrderProductLine__c"
    };
    delete newOrderLine.Product__r;
    console.log(newOrderLine);
    try {
      await saveRecord({ record: newOrderLine });
      this.template
        .querySelector("c-manage-lines-recipients")
        .transformData(true);
    } catch (err) {
      console.error(JSON.stringify(err));
    }
  };

  async renderedCallback() {
    if (!this.isLoaded && this.recordId) {
      this.isLoaded = true;
      await this.loadSalesOrder();
      this.recordLink = "/" + this.recordId;
      this.componentReady = true;
    }
  }
}