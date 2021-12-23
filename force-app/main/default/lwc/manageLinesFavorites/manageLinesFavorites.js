import { api, LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const columns = [
  {
    label: "Favorite",
    type: "button-icon",
    fieldName: "isFavorite",
    typeAttributes: {
      iconName: "utility:favorite",
      name: "favorite",
      variant: { fieldName: "buttonVariant" },
      alternativeText: "favorite"
    }
  },
  {
    label: "Product Name",
    fieldName: "productUrl",
    type: "url",
    typeAttributes: { label: { fieldName: "productName" }, target: "_blank" }
  },
  {
    label: "Kit/Bundle",
    fieldName: "isKitBundle",
    type: "boolean"
  },
  { label: "List Price", fieldName: "unitPrice", type: "currency" },
  {
    label: "Sales Price",
    fieldName: "salesPrice",
    type: "currency",
    editable: true
  },
  { label: "Quantity", fieldName: "quantity", type: "number", editable: true },
  {
    type: "button-icon",
    typeAttributes: {
      iconName: "utility:add",
      name: "add_line",
      alternativeText: "add product"
    }
  }
];

export default class ManageLinesFavorites extends LightningElement {
  @api favorites;
  columns = columns;
  data = [];

  @api updateData(newdata) {
    this.data = [...newdata];
  }

  handleAddLine = (row) => {
    console.log({ ...row });
    const newOrderLine = {
      Product__c: row.Product__c,
      Product__r: {
        Name: row.productName,
        Maximum_Quantity__c: row.Maximum_Quantity__c,
        Minimum_Quantity__c: row.Minimum_Quantity__c,
        Default_Quantity__c: row.Default_Quantity__c,
        Recipient_Limit__c: row.Recipient_Limit__c
      },
      Quantity__c: row.quantity,
      SalesPrice__c: row.salesPrice,
      ListPrice__c: row.unitPrice,
      Recipient_Count__c: 0,
      LineDiscountPercent__c: 0,
      KitBundle__c: row.isKitBundle
    };
    const addLineEvent = new CustomEvent("lineadd", {
      detail: newOrderLine
    });
    this.dispatchEvent(addLineEvent);
  };

  handleToggleFavorite = (row) => {
    const newRow = { ...row };
    newRow.isFavorite = newRow.isFavorite ? false : true;
    newRow.buttonVariant = newRow.isFavorite ? "brand" : "border";
    this.data = this.data.filter((d) => d.Id !== newRow.Id);
    this.dispatchEvent(
      new CustomEvent("togglefavorite", {
        detail: newRow
      })
    );
  };

  handleRowAction = (event) => {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case "add_line":
        this.handleAddLine(row);
        break;
      case "favorite":
        this.handleToggleFavorite(row);
      default:
    }
  };

  handleSave = (event) => {
    const newValues = event.detail.draftValues;
    console.log(newValues);
    this.data = this.data.map((d) => {
      newValues.forEach((nV) => {
        if (nV.salesPrice) {
          nV.salesPrice = Number(nV.salesPrice);
        }
        if (nV.quantity) {
          nV.quantity = Number(nV.quantity);
        }
        if (nV.Id == d.Id) {
          if (
            d.Maximum_Quantity__c &&
            nV.quantity &&
            Number(nV.quantity) > Number(d.Maximum_Quantity__c)
          ) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: `Quantity Exceeds Maximum Allowed for ${d.productName}`,
                message: `Your quantity will be adjusted to the maximum allowed for this product, ${d.Maximum_Quantity__c}`,
                variant: "Warning",
                mode: "sticky"
              })
            );
          }
          if (
            d.Minimum_Quantity__c &&
            nV.quantity &&
            Number(nV.quantity) < Number(d.Minimum_Quantity__c)
          ) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: `Quantity is Less Than the Minimum Required for ${d.productName}`,
                message: `Your quantity will be adjusted to the minimum required for this product, ${d.Minimum_Quantity__c}`,
                variant: "Warning",
                mode: "sticky"
              })
            );
          }
          d = { ...d, ...nV };
        }
      });
      return d;
    });
  };

  connectedCallback() {
    this.data = this.favorites;
  }
}