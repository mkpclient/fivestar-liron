import { api, LightningElement } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import doQuery from "@salesforce/apex/LWC.doQuery";
import saveRecord from "@salesforce/apex/LWC.saveRecord";
import deleteRecordWithQuery from "@salesforce/apex/LWC.deleteRecordWithQuery";
import { getMLRecord } from "c/manageLinesHelpers";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ChoosePriceBookQuickAction extends LightningElement {
  isManagedLines = false;
  @api recordId;
  isLoaded = false;
  componentReady = false;
  originalPriceBook;
  selectedPriceBook;
  pricebooks;

  handleCloseAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  retrievePricebooks = async () => {
    const [pricebooks, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "Pricebook2",
      fields: "Id, Name, isActive",
      hasConditions: true,
      conditions: `WHERE isActive=True ORDER BY Name`
    });
    if (error !== null) {
      console.error(error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Loading Pricebooks",
          message: "An internal error has occured. Please contact support.",
          variant: "error"
        })
      );
      return;
    } else {
      return pricebooks;
    }
  };

  loadAllData = async () => {
    const pricebooks = await this.retrievePricebooks();
    const [salesOrder, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "SalesOrder__c",
      fields: "Name, Id, PriceBookName__c",
      hasConditions: true,
      conditions: `WHERE Id='${this.recordId}'`
    });
    if (error) {
      console.error(error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Loading Sales Order",
          message: "An internal error has occured. Please contact support.",
          variant: "error"
        })
      );
      return;
    } else {
      this.selectedPriceBook = salesOrder[0].PriceBookName__c;
      this.originalPriceBook = salesOrder[0].PriceBookName__c;
      this.pricebooks = pricebooks.map((pb) => ({
        label: pb.Name,
        value: pb.Name
      }));
    }
  };

  handleChange = (evt) => {
    this.selectedPriceBook = evt.detail.value;
  };

  handleSave = async (evt) => {
    const type = evt.target.name;
    if (!this.selectedPriceBook) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Pricebook Required",
          message: "You must select a pricebook.",
          variant: "error"
        })
      );
      return;
    }

    if (this.selectedPriceBook === this.originalPriceBook) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "No Changes Made",
          message:
            "Your selected pricebook is the same as the previous pricebook.",
          variant: "success"
        })
      );
      if (type == "manageLines") {
        this.isManagedLines = true;
      } else {
        this.handleCloseAction();
      }

      return;
    }

    this.componentReady = false;
    const newPB = this.selectedPriceBook;
    const modifedSalesOrder = {
      sobjectType: "SalesOrder__c",
      Id: this.recordId,
      PriceBookName__c: newPB
    };
    try {
      const newSalesOrder = await saveRecord({ record: modifedSalesOrder });
      const queries = [
        `SELECT Id FROM Order_Line_Recipient__c WHERE Order__c='${this.recordId}'`,
        `SELECT Id FROM SalesOrderProductLine__c WHERE SalesOrder__c='${this.recordId}'`
      ];
      for (let i = 0; i < queries.length; i++) {
        await deleteRecordWithQuery({ queryString: queries[i] });
      }

      const successEvent = new ShowToastEvent({
        title: "Pricebook Updated",
        message: `This record's pricebook has been changed to ${this.selectedPriceBook}`,
        variant: "success"
      });
      if (type == "manageLines") {
        this.isManagedLines = true;
        this.dispatchEvent(successEvent);
      } else {
        this.handleCloseAction();
        this.dispatchEvent(successEvent);
      }
    } catch (err) {
      console.log("ERROR UPSERTING SALES ORDER : ");
      console.error(err);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Saving Record",
          message: "An internal error has occured. Please contact support.",
          variant: "error"
        })
      );
    }
  };

  async renderedCallback() {
    if (!this.isLoaded && this.recordId) {
      this.isLoaded = true;
      this.loadAllData();
      this.componentReady = true;
    }
  }
}