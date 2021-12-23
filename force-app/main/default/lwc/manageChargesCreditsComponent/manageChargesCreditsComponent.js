import { api, LightningElement, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
// import generateChargesCredits from "@salesforce/apex/ManageChargesCreditsController.generateChargesCredits";
// import generateOrderChargesCredits from "@salesforce/apex/ManageChargesCreditsController.generateOrderChargesCredits";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import addNewOrderChargesCredits from "@salesforce/apex/ManageChargesCreditsController.addNewOrderChargesCredits";
// import saveOrderAdditionalChargeCredit from "@salesforce/apex/ManageChargesCreditsController.saveOrderAdditionalChargeCredit";
// import deleteOrderChargesCredits from "@salesforce/apex/ManageChargesCreditsController.deleteOrderChargesCredits";
import { getRecord } from "lightning/uiRecordApi";
import { getMLRecord } from "c/manageLinesHelpers";
import doQuery from "@salesforce/apex/LWC.doQuery";
import saveMultipleRecords from "@salesforce/apex/LWC.saveMultipleRecords";
import deleteMultipleRecords from "@salesforce/apex/LWC.deleteMultipleRecords";

const linesTableActions = [
  { label: "Duplicate", name: "duplicate" },
  { label: "Delete", name: "delete" }
];

const linesTableColumns = [
  {
    type: "action",
    typeAttributes: { rowActions: linesTableActions }
  },
  {
    label: "Additional Charge/Credit",
    fieldName: "LineURL",
    type: "url",
    typeAttributes: { label: { fieldName: "LineName" }, target: "_blank" }
  },
  {
    label: "Quantity",
    type: "number",
    fieldName: "Quantity__c",
    editable: true
  },
  {
    label: "Price",
    fieldName: "SalesPrice__c",
    type: "currency",
    editable: true
  },
  {
    label: "Line Description",
    fieldName: "LineDescription__c",
    editable: true
  },
  {
    label: "Date",
    type: "date-local",
    fieldName: "Date__c",
    editable: true
  },
  {
    label: "Total Amount",
    type: "currency",
    fieldName: "Line_Total__c"
  }
];

const addLineColumns = [
  {
    label: "Action",
    type: "button-icon",
    typeAttributes: {
      iconName: "utility:add",
      name: "add_line",
      alternativeText: "add product",
      variant: "bare"
    }
  },
  {
    label: "Name",
    fieldName: "AddLineURL",
    type: "url",
    typeAttributes: { label: { fieldName: "Name" }, target: "_blank" }
  },
  {
    label: "Description",
    fieldName: "Description__c"
  },
  {
    label: "Unit Price",
    fieldName: "UnitPrice__c",
    type: "currency"
  }
];
export default class ManageChargesCreditsComponent extends LightningElement {
  @api isVisualForce = false;
  @api recordId;
  isRendered = false;
  lineData = [];
  addLineData = [];
  addLineColumns = addLineColumns;
  allChargesCredits = [];
  selectedItems = [];
  allowEdit = true;
  // totalAmount = 0;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "SalesOrder__c.Status_Picklist__c"
    ]
  })
  returnedRecord({ error, data }) {
    if(error) {
      console.error(error);
    } else if(data) {
      this.allowEdit = ["Draft", "Unreleased"].includes(data.fields.Status_Picklist__c.value);
    }
  }

  get totalAmount() {
    return this.lineData.reduce(
      (sum, d) => sum + d.Line_Total__c,
      0
    );
  };

  get lineColumns() {
    let cols = linesTableColumns;
    if(!this.allowEdit) {
      cols = cols
        .filter(c => c.type != "action")
        .map(v => {
          if(v.hasOwnProperty("editable")) {
            v.editable = false;
          }
         return v; 
        });
    }
    return cols;
  }

  processLineData = (parsedOrderCharges) => {
    if (!parsedOrderCharges || parsedOrderCharges.length < 1) {
      console.log("No data to parse");
      return;
    }

    if (parsedOrderCharges.Error) {
      console.error(parsedOrderCharges.Error);
      return;
    }

    this.lineData = [
      ...this.lineData,
      ...parsedOrderCharges.map((c) => ({
        ...c,
        LineURL: `/${c.Id}`,
        LineName: c.Additional_Charge_Credit__r.Name
      }))
    ];
  };

  handleDeleteRecords = async (records) => {
    const updRecords = records.map(r => ({...r, sobjectType: "SalesOrderAdditionalChargeCredit__c" }));
    try {
      await deleteMultipleRecords({ records: updRecords });
      return { Success: 'Delete success'}
    } catch (err) {
      return { Error: err };
    }
  }

  handleSaveRecords = async (records) => {
    const updRecords = records.map(r => ({...r, sobjectType: 'SalesOrderAdditionalChargeCredit__c'}));
    try {
      const retVals = await saveMultipleRecords({ records: updRecords });
      if(retVals.length > 0) {
        const recIds = `('${retVals.map(r => r.Id).join("','")}')`;
        const [res, er] = await getMLRecord({
          getFunction: doQuery,
          objectType: "SalesOrderAdditionalChargeCredit__c",
          fields: "Id, Additional_Charge_Credit__c, Additional_Charge_Credit__r.Name," + 
                  " Quantity__c, SalesPrice__c, LineDescription__c, Date__c, Line_Total__c," +  
                  " Additional_Charge_Credit__r.LockLineDescription__c,"+  
                  " Additional_Charge_Credit__r.LockQuantity__c, Additional_Charge_Credit__r.LockUnitPrice__c," + 
                  " Additional_Charge_Credit__r.MaximumQuantity__c, Additional_Charge_Credit__r.MinimumQuantity__c",
          hasConditions: true,
          conditions: `WHERE Id IN ${recIds}`
        });

        return {Error: er, Data: res};
      } else {
        return {Error: null, Data: []};
      }
    } catch (err) {
      return {Error: err, Data: []};
    }
  }

  async renderedCallback() {
    if (!this.isRendered && this.recordId) {
      
      // const chargesCredits1 = await generateChargesCredits();
      /*getFunction: doQuery,
      objectType: "SalesOrder__c",
      fields: "Name, Id, PriceBookName__c",
      hasConditions: true,
      conditions: `WHERE Id='${this.recordId}'`*/
      const [chargesCredits, ccError] = await getMLRecord({
        getFunction: doQuery,
        objectType: "AdditionalChargeCredit__c",
        fields: "Id, Name, Description__c, UnitPrice__c",
        hasConditions: true,
        conditions: "WHERE IsActive__c = TRUE"
      });
      if(ccError) {
        console.error(ccError);
        throw new Error(ccError);
      }

      // const existingOrderCharges = await generateOrderChargesCredits({
      //   recordId: this.recordId
      // });

      const [parsedOrderCharges, ocerror] = await getMLRecord({
        getFunction: doQuery,
        objectType: "SalesOrderAdditionalChargeCredit__c",
        fields: "Id, Additional_Charge_Credit__c, Additional_Charge_Credit__r.Name," + 
                " Quantity__c, SalesPrice__c, LineDescription__c, Date__c, Line_Total__c," +  
                " Additional_Charge_Credit__r.LockLineDescription__c,"+  
                " Additional_Charge_Credit__r.LockQuantity__c, Additional_Charge_Credit__r.LockUnitPrice__c," + 
                " Additional_Charge_Credit__r.MaximumQuantity__c, Additional_Charge_Credit__r.MinimumQuantity__c",
        hasConditions: true,
        conditions: `WHERE SalesOrder__c='${this.recordId}'`
      })
      if(ocerror) {
        console.error(ocerror);
        throw new Error(ocerror);
      }

      const parsedChargesCredits = chargesCredits.map(c => {
        if(c.UnitPrice__c == null) {
          c.UnitPrice__c = 0;
        }
        return c;
      });
      // const parsedOrderCharges = await JSON.parse(existingOrderCharges);
      this.allChargesCredits =
        parsedChargesCredits.length > 0 &&
        parsedChargesCredits.map((c) => ({
          ...c,
          AddLineURL: `/${c.Id}`
        }));
      this.processLineData(parsedOrderCharges);
      //this.calculateTotalAmount();
      this.addLineData = parsedChargesCredits.length > 0 && [
        ...this.allChargesCredits
      ];
      this.isRendered = true;
    }
  }

  /**
   * @param {Object} args
   * @param {String} args.title
   * @param {String} args.message
   * @param {String} args.variant
   */
  showNotification = (args) => {
    const { title, message, variant } = args;
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  };

  handleItemRemove = (evt) => {
    const index = evt.detail.index;
    this.selectedItems.splice(index, 1);
  };

  handleSearch = (evt) => {
    const filter = evt.target.value.toLowerCase();
    this.addLineData = this.allChargesCredits.filter((d) =>
      d.Name.toLowerCase().includes(filter)
    );
  };

  handleRowAction = (evt) => {
    const actionName = evt.detail.action.name;
    const row = evt.detail.row;
    switch (actionName) {
      case "duplicate":
        this.handleDuplicate(row);
        break;
      case "delete":
        this.handleDelete(row);
        break;
      case "add_line":
        this.handleAddLine(row);
        break;
      default:
    }
  };

  handleAddSelected = async () => {
    if (this.selectedItems.length > 0) {
      const selectedIds = this.selectedItems.map((i) => i.Id);
      this.selectedItems = [];
      const generatedSOACCs = await addNewOrderChargesCredits({
        ccIds: selectedIds,
        soId: this.recordId
      });
      this.processLineData(JSON.parse(generatedSOACCs));
      //this.calculateTotalAmount();
      this.showNotification({
        title: "Success!",
        message: "New charges and credits added.",
        variant: "success"
      });
    } else {
      this.showNotification({
        title: "Nothing to add",
        message: "You have not selected a charge or a credit.",
        variant: "error"
      });
    }
  };

  handleAddLine = async (row) => {
    this.selectedItems = [
      ...this.selectedItems,
      {
        type: "icon",
        label: row.Name,
        name: row.Name.replace(" ", ""),
        iconName: "standard:account",
        alternativeText: row.Name,
        Id: row.Id
      }
    ];
    await this.handleAddSelected()
  };

  handleSelectAll = async () => {
    this.selectedItems = [
      ...this.selectedItems,
      ...this.addLineData.map((row) => ({
        type: "icon",
        label: row.Name,
        name: row.Name.replace(" ", ""),
        iconName: "standard:account",
        alternativeText: row.Name,
        Id: row.Id
      }))
    ];
    await this.handleAddSelected();
  };



  handleClearSelected = () => {
    this.selectedItems = [];
  };

  handleDeleteAll = async () => {
    const records = this.lineData.map((d) => ({ Id: d.Id }));
    if (window.confirm("Are you sure you want to delete all?")) {
      const { Error, Success } = await this.handleDeleteRecords(records);
      if(Error) {
        console.error(Error);
      } else {
        console.log(Success);
        this.lineData = [];
      }
    } else {
      return;
    }
  };

  handleSave = async (evt) => {
    const newValues = evt.detail.draftValues[0];
    console.log(newValues);

    const currLine = this.lineData.find((d) => d.Id === newValues.Id);
    const error = {
      title: null,
      message: null,
      variant: "error"
    };

    if (
      (currLine.Additional_Charge_Credit__r.LockLineDescription__c &&
        newValues.LineDescription__c) ||
      (currLine.Additional_Charge_Credit__r.LockQuantity__c &&
        newValues.Quantity__c) ||
      (currLine.Additional_Charge_Credit__r.LockUnitPrice__c &&
        newValues.SalesPrice__c)
    ) {
      error.title = "Restricted Field";
      error.message = "This field cannot be edited.";
    }

    if (
      newValues.Quantity__c &&
      newValues.Quantity__c >
        currLine.Additional_Charge_Credit__r.MaximumQuantity__c
    ) {
      error.title = "Quantity exceeds maximum";
      error.message =
        "New quantity exceeds credit/charge's maximum quantity value.";
    }
    if (
      newValues.Quantity__c &&
      newValues.Quantity__c <
        currLine.Additional_Charge_Credit__r.MinimumQuantity__c
    ) {
      error.title = "Quantity is less than minimum";
      error.message =
        "New quantity is less than credit/charge's minimum quantity value.";
    }
    if (error.title) {
      this.showNotification(error);
      if (this.isVisualForce) {
        window.alert(error.title + ": " + error.message);
      }
      return;
    } else {
      // const res = await saveOrderAdditionalChargeCredit({
      //   records: [newValues]
      // });
      const { Error, Data } = await this.handleSaveRecords([newValues]);
      if (Error) {
        console.error();
        return;
      } else {
        const processedData = {
          ...Data[0],
          LineURL: `/${Data[0].Id}`,
          LineName: Data[0].Additional_Charge_Credit__r.Name
        };
        this.lineData = this.lineData.map((d) =>
          d.Id === processedData.Id ? processedData : d
        );
        //this.calculateTotalAmount();

        this.showNotification({
          title: "Success",
          message: "Your data has been saved.",
          variant: "success"
        });
      }
    }
  };

  handleDuplicate = async (row) => {
    const dupeRow = {
      Id: null,
      Additional_Charge_Credit__c: row.Additional_Charge_Credit__c,
      Quantity__c: row.Quantity__c,
      SalesPrice__c: row.SalesPrice__c,
      LineDescription__c: row.LineDescription__c,
      Date__c: row.Date__c,
      Line_Total__c: row.Line_Total__c,
      SalesOrder__c: this.recordId
    };
    // const res = await saveOrderAdditionalChargeCredit({
    //   records: [dupeRow]
    // });
    const { Error, Data } = await this.handleSaveRecords([dupeRow]);
    if (Error) {
      console.error(Error);
    } else {
      const processedData = {
        ...Data[0],
        LineURL: `/${Data[0].Id}`,
        LineName: Data[0].Additional_Charge_Credit__r.Name
      };
      this.lineData = [...this.lineData, processedData];
      //this.calculateTotalAmount();
      this.showNotification({
        title: "Success",
        message: "Your data has been saved.",
        variant: "success"
      });
    }
  };

  handleDelete = async (row) => {
    const deleteRecords = [{ Id: row.Id }];
    if (
      window.confirm("Do you really want to permanently delete this record?")
    ) {
      // const res = await deleteOrderChargesCredits({
      //   records: deleteRecords
      // });
      const { Success, Error } = await this.handleDeleteRecords(deleteRecords);
      if (Error) {
        console.error(Error);
        return;
      } else {
        console.log(Success);
        this.lineData = this.lineData.filter(
          (d) => d.Id !== deleteRecords[0].Id
        );
        //this.calculateTotalAmount();
      }
    } else {
      return;
    }
  };

  handleCancel = () => {
    if (this.isVisualForce) {
      window.location.pathname = `/${this.recordId}`;
    } else {
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  };

  get noData() {
    return this.lineData.length < 1;
  }
}