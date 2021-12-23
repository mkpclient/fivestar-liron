import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import doQuery from "@salesforce/apex/LWC.doQuery";
import { getMLRecord } from "c/manageLinesHelpers";

const columns = [
  {
    type: "button-icon",
    fixedWidth: 40,
    typeAttributes: {
      iconName: "utility:add",
      name: "add_line",
      alternativeText: "add product",
      variant: "bare"
    }
  },
  {
    label: "Favorite",
    type: "button-icon",
    fixedWidth: 80,
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
    fixedWidth: 400,
    wrapText: true,
    type: "url",
    typeAttributes: { label: { fieldName: "productName" }, target: "_blank" }
  },
  {
    label: "Kit/Bundle",
    fieldName: "isKitBundle",
    fixedWidth: 100,
    type: "boolean"
  },
  {
    label: "List Price",
    fixedWidth: 200,
    fieldName: "unitPrice",
    type: "currency"
  },
  {
    label: "Sales Price",
    fieldName: "salesPrice",
    fixedWidth: 200,
    type: "currency",
    editable: true
  },
  {
    label: "Quantity",
    fixedWidth: 150,
    fieldName: "quantity",
    type: "number",
    editable: true
  }
];

export default class ManageLinesProductsList extends LightningElement {
  @api products;
  columns = columns;
  @track data = [];
  tableElement;

  @api removeFavorite(productId) {
    this.data = this.data.map((d) => {
      if (d.Id == productId) {
        return {
          ...d,
          isFavorite: false,
          buttonVariant: "border"
        };
      } else {
        return d;
      }
    });
  }

  @api loadData(searchResult = []) {
    this.data =
      searchResult.length > 0
        ? searchResult.map((prod) => ({
            Id: prod.Product2Id,
            productName: prod.Product2.Name,
            unitPrice: prod.UnitPrice,
            salesPrice: prod.UnitPrice,
            quantity: 0,
            productUrl: `/lightning/r/Product2/${prod.Product2Id}/view`,
            isFavorite: prod.isFavorite,
            buttonVariant: prod.buttonVariant,
            isKitBundle: prod.Product2.IsKitBundle__c,
            Maximum_Quantity__c: prod.Product2.Maximum_Quantity__c,
            Minimum_Quantity__c: prod.Product2.Minimum_Quantity__c,
            Default_Quantity__c: prod.Product2.Default_Quantity__c,
            Recipient_Limit__c: prod.Product2.Recipient_Limit__c
          }))
        : [];
  }

  connectedCallback() {
    this.data.length === 0 && this.loadData(this.products);
  }

  // getChildrenRecords = async (parentId) => {
  //   const [bundleRecords, error] = await getMLRecord({
  //     getFunction: doQuery,
  //     objectType: "Kit_Bundle_Member__c",
  //     fields: "Quantity__c, AllowQuantityChange__c, ReferenceKitBundle__c, ReferenceMemberProduct__c, Required__c",
  //     hasConditions: true,
  //     conditions: `WHERE ReferenceKitBundle__c='${parentId}'`
  //   });

  //   if(error) {
  //     console.error(error)
  //     return;
  //   } else {
  //     return JSON.stringify(bundleRecords);
  //   }
  // };

  handleAddLine = async (row) => {
    console.log({ ...row });
    console.log("Is kit bundle? " + row.isKitBundle);
    // let children;
    // // TODO: if kit bundle, then we load all children using an API call to make all the related order lines
    // if(row.isKitBundle) {
    //   const res = await this.getChildrenRecords(row.Id);
    //   children = await JSON.parse(res);
    // }

    const newOrderLine = {
      Product__c: row.Id,
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
      LineDiscountPercent__c: 0,
      KitBundle__c: row.isKitBundle
    };

    // if(children) {
    //   newOrderLine.bundleRecords = JSON.stringify(children);
    // }

    const addLineEvent = new CustomEvent("lineadd", {
      detail: newOrderLine
    });
    this.dispatchEvent(addLineEvent);
  };

  handleToggleFavorite = (row) => {
    const newRow = { ...row };
    newRow.isFavorite = newRow.isFavorite ? false : true;
    newRow.buttonVariant = newRow.isFavorite ? "brand" : "border";
    console.log(newRow);
    this.data = this.data.map((prod) => {
      if (prod.Id === row.Id) {
        return newRow;
      } else {
        return prod;
      }
    });
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
}