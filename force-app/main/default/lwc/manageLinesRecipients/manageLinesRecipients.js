import { api, LightningElement, wire } from "lwc";
import saveRecord from "@salesforce/apex/LWC.saveRecord";
import deleteRecord from "@salesforce/apex/LWC.deleteRecord";
import { getRecord } from "lightning/uiRecordApi";
import deleteRecordWithQuery from "@salesforce/apex/LWC.deleteRecordWithQuery";
import { getMLRecord } from "c/manageLinesHelpers";
import doQuery from "@salesforce/apex/LWC.doQuery";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import ModalWidthCSS from "@salesforce/resourceUrl/ModalWidthCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import saveMultipleRecords from "@salesforce/apex/LWC.saveMultipleRecords";
import deleteMultipleRecords from "@salesforce/apex/LWC.deleteMultipleRecords";
import strUserId from "@salesforce/user/Id";
import PROFILE_NAME_FIELD from "@salesforce/schema/User.Profile.Name";

const generateActions = (isEditable, hasPermission) => {
  let editableActions = [
    { label: "Delete", name: "delete" },
    { label: "Make Copy", name: "duplicate" },
    { label: "View Product", name: "view_product" }
  ];

  if (isEditable && hasPermission) {
    editableActions.push({ label: "Edit Line", name: "edit_line" });
  }

  return isEditable
    ? editableActions
    : [{ label: "View Product", name: "view_product" }];
};

const generateColumns = (isEditable) => [
  {
    type: "action",
    cellAttributes: { class: { fieldName: "backgroundColor" } },
    fixedWidth: 30,
    typeAttributes: {
      rowActions: isEditable
        ? { fieldName: "rowActions" }
        : generateActions(false, false)
    }
  },
  {
    type: "button",
    fixedWidth: 100,
    cellAttributes: { class: { fieldName: "backgroundColor" } },
    typeAttributes: {
      iconName: { fieldName: "expandIconName" },
      name: "toggleExpand",
      alternativeText: { fieldName: "expandAltText" },
      label: { fieldName: "expandAltText" },
      variant: "base"
    }
  },
  {
    label: "Product Name",
    fieldName: "ProductUrl",
    sortable: true,
    type: "url",
    wrapText: true,
    fixedWidth: 400,
    cellAttributes: { class: { fieldName: "backgroundColor" } },
    typeAttributes: { label: { fieldName: "ProductName" }, target: "_blank" }
  },
  {
    label: "(Qty) Quantity",
    fieldName: "Quantity__c",
    type: "number",
    sortable: true,
    fixedWidth: 100,
    editable: isEditable,
    cellAttributes: { class: isEditable ? { fieldName: "disableEdit" } : "" }
  },
  {
    label: "Sales Price",
    fieldName: "SalesPrice__c",
    type: "currency",
    sortable: true,
    fixedWidth: 200,
    editable: isEditable,
    cellAttributes: { class: { fieldName: "backgroundColor" } }
  },
  {
    label: "Recipients",
    type: "button",
    fixedWidth: 100,
    typeAttributes: {
      alternativeText: "Add New Recipient",
      class: "slds-var-m-left_xx-small",
      label: { fieldName: "Recipient_Count__c" },
      iconName: "utility:adduser",
      name: "addRecipient",
      title: { fieldName: "Tooltip" },
      variant: "border-filled",
      iconPosition: "right",
      disabled: !isEditable
    },
    cellAttributes: { class: { fieldName: "backgroundColor" } }
  },
  {
    label: "Line Description",
    fieldName: "LineDescription__c",
    fixedWidth: 200,
    wrapText: true,
    editable: isEditable,
    cellAttributes: { class: { fieldName: "backgroundColor" } }
  },
  {
    label: "Date",
    fieldName: "DateRequired__c",
    type: "date-local",
    sortable: true,
    fixedWidth: 150,
    editable: isEditable,
    cellAttributes: { class: { fieldName: "backgroundColor" } }
  },
  {
    label: "Line Discount (%)",
    fieldName: "LineDiscountPercent__c",
    type: "number",
    editable: isEditable,
    fixedWidth: 130,
    cellAttributes: {
      class: { fieldName: "backgroundColor" },
      iconName: "utility:percent",
      iconPosition: "right"
    }
  },
  {
    label: "Total Discount (%)",
    fieldName: "OrderDiscountPercent__c",
    fixedWidth: 100,
    type: "number",
    cellAttributes: {
      class: { fieldName: "backgroundColor" },
      iconName: "utility:percent",
      iconPosition: "right"
    }
  },
  {
    label: "Total Amount",
    fieldName: "TotalAmount__c",
    fixedWidth: 100,
    sortable: true,
    type: "currency",
    cellAttributes: { class: { fieldName: "backgroundColor" } }
  }
];

// const actions = [
//   { label: "Delete", name: "delete" },
//   { label: "Make Copy", name: "duplicate" },
//   { label: "Edit Line", name: "edit_line" },
//   { label: "View Product", name: "view_product" }
// ];

// const columns = [
//   {
//     type: "action",
//     typeAttributes: { rowActions: generateActions() }
//   },
//   {
//     label: "Product Name",
//     fieldName: "ProductUrl",
//     sortable: true,
//     type: "url",
//     typeAttributes: { label: { fieldName: "ProductName" }, target: "_blank" }
//   },
//   {
//     label: "Quantity",
//     fieldName: "Quantity__c",
//     type: "number",
//     sortable: true,
//     editable: true
//   },
//   {
//     label: "Sales Price",
//     fieldName: "SalesPrice__c",
//     type: "currency",
//     sortable: true,
//     editable: true
//   },
//   {
//     label: "Recipients",
//     type: "button",
//     typeAttributes: {
//       alternativeText: "Add New Recipient",
//       class: "slds-var-m-left_xx-small",
//       label: { fieldName: "Recipient_Count__c" },
//       iconName: "utility:adduser",
//       name: "addRecipient",
//       title: "Add New Recipient",
//       variant: "border-filled",
//       iconPosition: "right",
//       disabled: false
//     }
//   },
//   {
//     label: "Line Description",
//     fieldName: "LineDescription__c",
//     editable: true
//   },
//   {
//     label: "Date",
//     fieldName: "DateRequired__c",
//     type: "date-local",
//     sortable: true,
//     editable: true
//   },
//   {
//     label: "Line Discount (%)",
//     fieldName: "LineDiscountPercent__c",
//     type: "number",
//     editable: true
//   },
//   {
//     label: "Total Discount (%)",
//     fieldName: "OrderDiscountPercent__c",
//     type: "number"
//   },
//   {
//     label: "Total Amount",
//     fieldName: "TotalAmount__c",
//     sortable: true,
//     type: "currency"
//   }
// ];

export default class ManageLinesRecipients extends NavigationMixin(
  LightningElement
) {
  @api salesOrder;
  lineRecipients = null;
  addRecipientsActive = false;
  discountPercent;
  isRendered = false;
  @api isEditable;
  columns = [];
  data = [];
  activeOrderLineId;
  orderProductLines = [];
  existingOrderLineRecipients = [];
  lineRecipientsForDeletion = [];
  orderProductLinesToDelete = [];
  recipientLimit;
  sortBy;
  sortDirection;
  searchRecipientQueryItems = {
    isLoaded: false,
    marketId: null,
    publicationYear: null
  };
  hasAdminPermissions = false;

  @wire(getRecord, {
    recordId: strUserId,
    fields: [PROFILE_NAME_FIELD]
  })
  wireUser({error, data}) {
    if(error) {
      console.error(error);
    } else if(data) {
      if(["FSP - Accounting +", "System Administrator"].includes(data.fields.Profile.value.fields.Name.value)) {
        this.hasAdminPermissions = true;
      }
    }
  }

  sortData = (fieldname, direction) => {
    // serialize the data before calling sort function
    let parseData = JSON.parse(JSON.stringify(this.data));

    // Return the value stored in the field
    let keyValue = (a) => {
      return a[fieldname];
    };

    // cheking reverse direction
    let isReverse = direction === "asc" ? 1 : -1;

    // sorting data
    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : ""; // handling null values
      y = keyValue(y) ? keyValue(y) : "";

      // sorting values based on direction
      return isReverse * ((x > y) - (y > x));
    });

    // set the sorted data to data table data
    this.data = parseData;
  };

  handleSortdata = (event) => {
    // field name
    this.sortBy = event.detail.fieldName;

    // sort direction
    this.sortDirection = event.detail.sortDirection;

    // calling sortdata function to sort the data based on direction and selected field
    this.sortData(event.detail.fieldName, event.detail.sortDirection);
  };

  loadOrderProductLines = async () => {
    const [productLines, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "SalesOrderProductLine__c",
      fields: `Id, Product__c, KitBundleLine__c, SalesOrder__c, AllowQuantityChange__c, 
      Kit_Bundle_Member__c, KitBundle__c, Allow_Recipient_Add__c, 
      Product__r.Name, Product__r.Maximum_Quantity__c, Product__r.Minimum_Quantity__c, 
      Product__r.Default_Quantity__c, Product__r.Recipient_Limit__c, Quantity__c, 
      SalesPrice__c, ListPrice__c, Recipient_Count__c, LineDescription__c, 
      DateRequired__c, LineDiscountPercent__c, OrderDiscountPercent__c, 
      TotalAmount__c, (SELECT Id, SalesOrder__c, Product__c, KitBundleLine__c, AllowQuantityChange__c, 
        Kit_Bundle_Member__c, KitBundle__c, Allow_Recipient_Add__c, 
        Product__r.Name, Product__r.Maximum_Quantity__c, Product__r.Minimum_Quantity__c, 
        Product__r.Default_Quantity__c, Product__r.Recipient_Limit__c, Quantity__c, 
        SalesPrice__c, ListPrice__c, Recipient_Count__c, LineDescription__c, 
        DateRequired__c, LineDiscountPercent__c, OrderDiscountPercent__c, 
        TotalAmount__c FROM Sales_Order_Product_Lines__r WHERE Kit_Bundle_Member__c=true)`,
      hasConditions: true,
      conditions: `WHERE SalesOrder__c='${this.salesOrder.Id}' AND Kit_Bundle_Member__c=false ORDER BY CreatedDate`
    });
    if (error !== null) {
      console.error("PRODUCT LINES ERROR: ");
      console.error(JSON.stringify(error));
    } else {
      return productLines;
    }
  };

  loadLineRecipients = async () => {
    const [lineRecipients, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "Order_Line_Recipient__c",
      fields:
        "Id, Recipient__c, Recipient__r.Name, Recipient__r.Account.Name, OrderProductLine__c, Primary__c",
      hasConditions: true,
      conditions: `WHERE Order__c='${this.salesOrder.Id}'`
    });
    if (error !== null) {
      console.error("RECIPIENT LINES ERROR: " + error);
    } else {
      return lineRecipients;
    }
  };

  @api async transformData(newLine = false) {
    if (newLine) {
      this.isRendered = false;
      await this.renderedCallback();
      // let processLine = { ...newLine };
      // processLine.Product__r = { ...newLine.Product__r };
      // processLine.ProductUrl = `/lightning/r/SalesOrderProductLine__c/${processLine.Id}/view`;
      // processLine.ProductName =
      //   processLine.ProductName || processLine.Product__r.Name;
      // processLine.Maximum_Quantity__c =
      //   processLine.Product__r.Maximum_Quantity__c &&
      //   processLine.Product__r.Maximum_Quantity__c;
      // processLine.Minimum_Quantity__c =
      //   processLine.Product__r.Minimum_Quantity__c &&
      //   processLine.Product__r.Minimum_Quantity__c;
      // processLine.Default_Quantity__c =
      //   processLine.Product__r.Default_Quantity__c &&
      //   processLine.Product__r.Default_Quantity__c;
      // processLine.Recipient_Limit__c =
      //   processLine.Product__r.Recipient_Limit__c &&
      //   processLine.Product__r.Recipient_Limit__c;
      // this.data = [...this.data, processLine];
      return;
    }
    const productLines = [...this.orderProductLines];
    console.log("PROD LINES");
    console.log(productLines);

    if (
      productLines.length > 0 &&
      this.lineRecipients &&
      this.lineRecipients.length > 0
    ) {
      productLines.forEach((pL) => {
        let recipients = [];
        let tooltip = "";
        this.lineRecipients.forEach((lR) => {
          const orderId = lR.OrderProductLine__c;
          const isPrimary = lR.Primary__c;
          const recipientId = lR.Recipient__c;
          const lrId = lR.Id;
          if (orderId == pL.Id) {
            tooltip += lR.Recipient__r.Name + "\n";
            recipients.push({
              Id: lrId,
              Primary__c: isPrimary,
              Recipient__c: recipientId,
              Recipient__r: {
                Name: lR.Recipient__r.Name,
                Account: {
                  Name: lR.Recipient__r.Account.Name
                }
              }
            });
          }
        });
        if (recipients.length > 0) {
          pL.lineRecipients = recipients;
          pL.Tooltip = tooltip.trim(0, tooltip.length - 1);
        } else {
          pL.Tooltip = "Add recipients";
        }
      });
    }
    this.data = productLines.map((line, idx) => ({
      ...line,
      Product__r: { ...line.Product__r },
      ProductName: line.Product__r.Name,
      ProductUrl: `/lightning/r/SalesOrderProductLine__c/${line.Id}/view`,
      Maximum_Quantity__c:
        line.Product__r.Maximum_Quantity__c &&
        line.Product__r.Maximum_Quantity__c,
      Minimum_Quantity__c:
        line.Product__r.Minimum_Quantity__c &&
        line.Product__r.Minimum_Quantity__c,
      Default_Quantity__c:
        line.Product__r.Default_Quantity__c &&
      line.Product__r.Default_Quantity__c,
      Recipient_Limit__c:
        line.Product__r.Recipient_Limit__c &&
        line.Product__r.Recipient_Limit__c,
      disableEdit: "",
      expandIconName: line.expandIconName
        ? line.expandIconName
        : line.KitBundle__c == true &&
          line.hasOwnProperty("Sales_Order_Product_Lines__r") &&
          line.Sales_Order_Product_Lines__r.length > 0
        ? "utility:chevronright"
        : "",
      expandAltText: line.expandAltText
        ? line.expandAltText
        : line.KitBundle__c == true &&
          line.hasOwnProperty("Sales_Order_Product_Lines__r") &&
          line.Sales_Order_Product_Lines__r.length > 0
        ? "Expand"
        : "",
      backgroundColor: line.Kit_Bundle_Member__c == true ? "child-element" : "",
      rowActions:
        line.Kit_Bundle_Member__c == true
          ? generateActions(false, false)
          : generateActions(true, this.hasAdminPermissions)
    }));
  }

  @api async clearData() {
    this.orderProductLines = [];
    this.existingOrderLineRecipients = [];
    this.lineRecipientsForDeletion = [];
    this.orderProductLinesToDelete = [];
    await this.transformData();
  }

  //! OBSOLETE:
  /* @api async saveData() {
    console.log(this.data);
    const newData =
      this.data &&
      this.data.map((d) => {
        if (d.lineRecipients) {
          d.lineRecipients.forEach((lR) => {
            delete lR.Recpient__r;
            lR.sobjectType = "Order_Line_Recipient__c";
            lR.Order__c = this.salesOrder.Id;
          });
        }
        const newRecord = {
          sobjectType: "SalesOrderProductLine__c",
          LineDiscountPercent__c: d.LineDiscountPercent__c || 0,
          DateRequired__c: d.DateRequired__c,
          LineDescription__c: d.LineDescription__c && d.LineDescription__c,
          Product__c: d.Product__c,
          Quantity__c: d.Quantity__c,
          Recipient_Count__c: d.Recipient_Count__c,
          SalesPrice__c: d.SalesPrice__c,
          SalesOrder__c: this.salesOrder.Id,
          lineRecipients: d.lineRecipients && d.lineRecipients,
          ListPrice__c: d.ListPrice__c
        };
        if (d.Id) {
          newRecord.Id = d.Id;
        }
        return newRecord;
      });

    if (this.orderProductLinesToDelete.length > 0) {
      const deleteOPL = [...this.orderProductLinesToDelete];
      let queriesRecipient = [];
      for (let i = 0; i < deleteOPL.length; i++) {
        queriesRecipient.push(
          `SELECT Id FROM Order_Line_Recipient__c WHERE OrderProductLine__c='${deleteOPL[i]}'`
        );
        const data = {
          sobjectType: "SalesOrderProductLine__c",
          Id: deleteOPL[i]
        };
        await deleteRecord({ record: data });
        this.orderProductLinesToDelete = [];
      }
    }

    if (this.lineRecipientsForDeletion.length > 0) {
      console.log("DELETE THEM: ");
      console.log(this.lineRecipientsForDeletion);
      const deleteOLR = [...this.lineRecipientsForDeletion];
      for (let i = 0; i < deleteOLR.length; i++) {
        const data = {
          sobjectType: "Order_Line_Recipient__c",
          Id: deleteOLR[i].Id
        };
        try {
          await deleteRecord({ record: data });
          this.lineRecipientsForDeletion = [];
        } catch (err) {
          console.error("DELETE LINE RECIPIENT FAILED : ");
          console.log(err);
          return [false, null];
        }
      }
    }

    console.log(newData);

    for (let i = 0; i < newData.length; i++) {
      const currData = newData[i];
      const lineRecipients = currData.lineRecipients && currData.lineRecipients;
      delete currData.lineRecipients;
      try {
        const returnedData = await saveRecord({ record: currData });
        console.log(returnedData);
        if (lineRecipients) {
          const OrderProductLine__c = await returnedData.Id;
          for (let i = 0; i < lineRecipients.length; i++) {
            const newLR = lineRecipients[i];
            delete newLR.Recipient__r;
            console.log(newLR);
            newLR.OrderProductLine__c = await OrderProductLine__c;
            await saveRecord({ record: newLR });
          }
        }
        this.orderProductLinesToDelete = [];
        this.orderProductLines = await this.loadOrderProductLines();
        this.lineRecipients = await this.loadLineRecipients();
        this.transformData();
        this.columns = [...this.columns];
      } catch (err) {
        console.log("ERROR ON SAVE : ");
        console.error(err);
        return [false, null];
      }
    }
    return [true, this.discountPercent];
  } */

  handleDiscountUpdate = async (evt) => {
    const newDiscount = Number(evt.target.value);
    const currentSalesOrder = {
      ...this.salesOrder,
      sobjectType: "SalesOrder__c",
      DiscountPercent__c: newDiscount
    };
    const newSalesOrder = await saveRecord({ record: currentSalesOrder });

    this.discountPercent = newDiscount;
    const newData = [];
    for (let i = 0; i < this.data.length; i++) {
      const curData = this.data[i];
      const recordToSave = {
        Id: curData.Id,
        sobjectType: "SalesOrderProductLine__c",
        OrderDiscountPercent__c: newDiscount
      };
      await saveRecord({ record: recordToSave });
      newData.push({
        ...curData,
        OrderDiscountPercent__c: newDiscount,
        TotalAmount__c:
          Number(curData.Quantity__c) *
          (Number(curData.SalesPrice__c) *
            ((100 - (newDiscount + Number(curData.LineDiscountPercent__c))) /
              100))
      });
    }
    this.data = newData;
  };

  /* handleDateChange = (evt) => {
    const newDate = evt.target.value;
    console.log(newDate);
    this.data = this.data.map((d) => ({
      ...d,
      DateRequired__c: newDate
    }));
    this.columns = [...this.columns];
  }; */

  async renderedCallback() {
    console.log("Not rendered");
    if (this.isRendered === false && this.salesOrder) {
      if (!this.stylesLoaded) {
        Promise.all([loadStyle(this, ModalWidthCSS)])
          .then(() => {
            this.stylesLoaded = true;
          })
          .catch((error) => {
            console.error("Error loading custom styles");
          });
      }

      console.log("starting render");
      this.orderProductLines = await this.loadOrderProductLines();
      this.lineRecipients = await this.loadLineRecipients();
      this.searchRecipientQueryItems.marketId = !this.salesOrder.Market__c
        ? null
        : this.salesOrder.Market__c;
      this.searchRecipientQueryItems.publicationYear = !this.salesOrder
        .Market__r.Publication_Year__c
        ? null
        : this.salesOrder.Market__r.Publication_Year__c;
      this.searchRecipientQueryItems.contactIdFromOpp = !this.salesOrder
        .Opportunity__r.Contact__c
        ? null
        : this.salesOrder.Opportunity__r.Contact__c;
      this.searchRecipientQueryItems.accountId = !this.salesOrder.Account__c
        ? null
        : this.salesOrder.Account__c;
      this.searchRecipientQueryItems.accountName = !this.salesOrder.Account__r.Name
        ? null
        : this.salesOrder.Account__r.Name;
      this.searchRecipientQueryItems.isLoaded = true;
      this.discountPercent = this.discountPercent
        ? this.discountPercent
        : this.salesOrder.DiscountPercent__c;
      console.log([...this.orderProductLines]);
      console.log([...this.lineRecipients]);
      await this.transformData();
      this.columns = generateColumns(this.isEditable);
      this.isRendered = true;
      console.log("Finished render");
    }
  }

  handleDelete = async (row) => {
    const idToDelete = row.Id;
    const recordToDelete = {
      Id: idToDelete,
      sobjectType: "SalesOrderProductLine__c"
    };
    await deleteRecord({ record: recordToDelete });
    this.data = this.data.filter(
      (d) => d.Id !== idToDelete && d.KitBundleLine__c !== idToDelete
    );
    this.orderProductLines = this.orderProductLines.filter(
      (o) => o.Id !== idToDelete && o.KitBundleLine__c !== idToDelete
    );
  };

  handleDuplicate = async (row) => {
    const newRow = Object.assign({}, row);
    const lineRecipients =
      (newRow.lineRecipients && [...newRow.lineRecipients]) || [];
    delete newRow.lineRecipients;
    delete newRow.Id;
    delete newRow.Tooltip;
    const productInfo = newRow.Product__r;
    // delete newRow.Maximum_Quantity__c;
    // delete newRow.Minimum_Quantity__c;
    // delete newRow.Default_Quantity__c;
    // delete newRow.Recipient_Limit__c;
    delete newRow.ProductName;
    delete newRow.ProductUrl;
    delete newRow.Product__r;
    delete newRow.disableEdit;
    delete newRow.expandIconName;
    delete newRow.expandAltText;
    delete newRow.Recipient_Count__c;
    delete newRow.backgroundColor;
    delete newRow.rowActions;
    delete newRow.Sales_Order_Product_Lines__r;
    newRow.sobjectType = "SalesOrderProductLine__c";
    newRow.ContactShipping__c = this.salesOrder.ContactBilling__c;
    console.log(newRow);
    try {
      await saveRecord({ record: newRow });
      await this.transformData(true);
    } catch (err) {
      console.err(JSON.stringify(err));
    }
  };

  //DONE: share the maximum allowable recipeints to child too
  toggleAddRecipient = (row) => {
    if (row) {
      this.activeOrderLineId = row.Id;
      this.recipientLimit =
        !row.Recipient_Limit__c || row.Recipient_Limit__c === "No Limit"
          ? "No Limit"
          : row.Recipient_Limit__c === "Line Quantity"
          ? row.Quantity__c
          : Number(row.Recipient_Limit__c);
      if (row.lineRecipients) {
        this.existingOrderLineRecipients = row.lineRecipients || [];
      }
    } else {
      this.recipientLimit = null;
      this.activeOrderLineId = null;
      this.existingOrderLineRecipients = [];
      this.recipientLimit = null;
    }
    if (this.addRecipientsActive) {
      this.recipientLimit = null;
      this.activeOrderLineId = null;
      this.existingOrderLineRecipients = [];
      this.recipientLimit = null;
    }
    this.addRecipientsActive = !this.addRecipientsActive;
    const componentChangeViewEvent = new CustomEvent("setcomponentview");
    this.dispatchEvent(componentChangeViewEvent);
  };

  handleAddRecipient = async (evt) => {
    this.toggleAddRecipient(null);
    this.isRendered = false;
    this.existingOrderLineRecipients = [];
    this.data = [];
    this.orderProductLines = [];
    this.lineRecipients = [];
    const records = JSON.parse(JSON.stringify(evt.detail.newRecords));
    const Id = evt.detail.Id;
    const lineRecipientsForDeletion = evt.detail.deleteRecords;

    for (let i = 0; i < records.length; i++) {
      records[i].Order__c = this.salesOrder.Id;
    }
    const newRecords = await saveMultipleRecords({ records: records });
    if (lineRecipientsForDeletion.length > 0) {
      await deleteMultipleRecords({ records: lineRecipientsForDeletion });
    }

    /* this.lineRecipientsForDeletion =
      lineRecipientsForDeletion.length > 0
        ? [
            ...this.lineRecipientsForDeletion,
            ...JSON.parse(JSON.stringify(lineRecipientsForDeletion))
          ]
        : [];
    console.log([...this.lineRecipientsForDeletion]); */
    if (await newRecords) await this.transformData(true);
  };

  handleViewProduct = (row) => {
    const productId = row.Product__c;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        recordId: productId,
        objectApiName: "Product2",
        actionName: "view"
      }
    }).then((url) => {
      window.open(url, "_blank");
    });
  };

  handleEditLine = (row) => {
    this.isRendered = false;
    this.dispatchEvent(
      new CustomEvent("editline", {
        detail: row.Id
      })
    );
  };

  toggleExpand = async (row) => {
    if (row.expandIconName == "utility:chevronright") {
      row.expandIconName = "utility:chevrondown";
      row.expandAltText = "Hide";
      const productLines = [...this.orderProductLines];
      const childrenData = row.Sales_Order_Product_Lines__r;
      const index = productLines.findIndex((o) => o.Id == row.Id);
      productLines[index] = {
        ...row,
        Sales_Order_Product_Lines__r: [...row.Sales_Order_Product_Lines__r]
      };
      productLines.splice(index + 1, 0, ...childrenData);
      this.orderProductLines = productLines;
      await this.transformData();
    } else {
      row.expandIconName = "utility:chevronright";
      row.expandAltText = "Expand";
      this.orderProductLines = [
        ...this.orderProductLines.filter((o) => o.KitBundleLine__c != row.Id)
      ].map((a) =>
        a.Id == row.Id
          ? {
              ...row,
              Sales_Order_Product_Lines__r: [
                ...row.Sales_Order_Product_Lines__r
              ]
            }
          : a
      );
      this.transformData();
    }
  };

  handleRowAction = (event) => {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case "delete":
        this.handleDelete(row);
        break;
      case "duplicate":
        this.handleDuplicate(row);
        break;
      case "addRecipient":
        this.toggleAddRecipient(row);
        break;
      case "view_product":
        this.handleViewProduct(row);
        break;
      case "edit_line":
        this.handleEditLine(row);
        break;
      case "toggleExpand":
        this.toggleExpand(row);
        break;
      default:
    }
  };

  //DONE: if the new value is greater than or less than the allowed quantity then it should revert to the maximum/minimum allowed and deploy a
  // DONE: -- cont -- display toast event warning
  handleSave = async (event) => {
    const newValues = event.detail.draftValues[0];
    let showToast = false;
    const toastParams = {
      title: "",
      message: "",
      variant: "warning",
      mode: "sticky"
    };
    this.data = this.data.map((d) => {
      if (d.Id == newValues.Id) {
        // we need to combine the new values into the old ones first so we have the full object
        const newData = {
          ...d,
          ...newValues
        };
        let quantity = Number(newData.Quantity__c) || 1;
        const maxQuantity =
          newData.Maximum_Quantity__c && Number(newData.Maximum_Quantity__c);
        const minQuantity =
          newData.Minimum_Quantity__c && Number(newData.Minimum_Quantity__c);
        const salesPrice = Number(newData.SalesPrice__c);
        const totalDiscount = Number(newData.OrderDiscountPercent__c);
        const lineDiscount = Number(newData.LineDiscountPercent__c);
        if (maxQuantity && quantity > maxQuantity) {
          quantity = maxQuantity;
          showToast = true;
          newValues.Quantity__c = maxQuantity;
          toastParams.title = `Quantity of ${newData.ProductName} has been adjusted.`;
          toastParams.message = `The quantity entered has been adjusted to the maximum allowed quantity for this product, ${maxQuantity}.`;
        }
        if (minQuantity && quantity < minQuantity) {
          showToast = true;
          quantity = minQuantity;
          newValues.Quantity__c = minQuantity;
          toastParams.title = `Quantity of ${newData.ProductName} has been adjusted.`;
          toastParams.message = `The quantity entered has been adjusted to the minimum allowed quantity for this product, ${minQuantity}.`;
        }
        newData.Quantity__c = quantity;
        newData.TotalAmount__c =
          quantity *
          (salesPrice * ((100 - (totalDiscount + lineDiscount)) / 100));

        if (newData.Sales_Order_Product_Lines__r && newData.Sales_Order_Product_Lines__r.length > 0) { 
          newData.Sales_Order_Product_Lines__r.forEach(so => {so.Quantity__c = quantity; so.DateRequired__c = newData.DateRequired__c;});
        }
        return {
          ...newData
        };
      }
      return d;
    });
    if (showToast) {
      this.dispatchEvent(
        new ShowToastEvent({
          ...toastParams
        })
      );
    }
    await saveRecord({
      record: { ...newValues, sobjectType: "SalesOrderProductLine__c" }
    });
    this.columns = [...this.columns];
  };

  get disableDiscount() {
    return !this.isEditable;
  }
}