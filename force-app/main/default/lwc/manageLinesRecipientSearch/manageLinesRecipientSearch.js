import { api, LightningElement, track } from "lwc";
import { getMLRecord } from "c/manageLinesHelpers";
import doQuery from "@salesforce/apex/LWC.doQuery";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

/* 
 ? pretend this is typescript
 *interface IRecipient = {
  *Recipient__c: String;
  *Primary__c: Boolean;
  *OrderProductLine__c: String;
  *Id?: String;
  *}; ›
 
 *interface SelectedRecipient = {
   *label: String;
   *value: String;
   *Name: String;
   *Account: String;
 }
*/

const columns = [
  {
    type: "button-icon",
    typeAttributes: {
      iconName: { fieldName: "iconName" },
      name: "toggle_selected",
      alternativeText: { fieldName: "buttonLabel" },
      variant: { fieldName: "buttonVariant" }
    }
  },
  {
    label: "Contact Name",
    fieldName: "ContactUrl",
    type: "url",
    typeAttributes: { label: { fieldName: "Name" }, target: "_blank" }
  },
  { label: "Account", fieldName: "Account" }
];

export default class ManageLinesRecipientSearch extends LightningElement {
  @api currentOrderLineId;
  @api recipientsLimit;
  @track selectedRecipients = [];
  @api existingRecipients = [];
  @api queryItems = {
    isLoaded: false,
    marketId: null,
    publicationYear: null,
    contactIdFromOpp: null,
    accountId: null,
    accountName: null
  };
  @track errorMessage;
  @track onAddRecipient = false;
  isReady = false;
  contactOptions = [];
  data = [];
  columns = columns;
  searchTerm;
  rowLimit = 10;
  maxRows;
  loadMoreStatus;
  // selectedRows = [];
  selectedPrimary;
  primaryOptions = [];
  recipientsToDelete = [];

  handleCancel = () => {
    const cancelAddRecipient = new CustomEvent("cancel");
    this.dispatchEvent(cancelAddRecipient);
  };

  handlePrimarySelect = (evt) => {
    this.selectedPrimary = evt.target.value;
  };

  /*  handleAddRecipient = (evt) => {
    const selectedRecipients = evt.detail.selectedRows;
    this.selectedRecipients = selectedRecipients;
    if (this.primaryOptions.length < 1) {
      this.primaryOptions = selectedRecipients;
    } else {
      this.primaryOptions = [
        ...this.primaryOptions,
        ...this.selectedRecipients.filter(
          (sR) => !this.primaryOptions.some((pO) => pO.value == sR.value)
        )
      ];
    }
  }; */

  /**
   * @param {Object} toastParams
   * @param {String} toastParams.title
   * @param {String} toastParams.message
   * @param {String} toastParams.variant
   * @param {String} toastParams.mode
   */
  handleToastEvent = (toastParams) => {
    this.dispatchEvent(
      new ShowToastEvent({
        ...toastParams
      })
    );
  };

  handleSubmit = () => {
    const selectedRecipients = [...this.selectedRecipients];
    const recipientsToDelete = this.recipientsToDelete.map((id) => ({
      Id: id,
      sobjectType: "Order_Line_Recipient__c"
    }));
    const noPrimaryError = () =>
      this.handleToastEvent({
        title: "Missing Required Field",
        message: "Please select a primary recipient.",
        variant: "error",
        mode: "sticky"
      });
    if (!this.selectedPrimary) {
      noPrimaryError();
      return;
    }
    if (
      this.recipientsLimit !== "No Limit" &&
      selectedRecipients.length > this.recipientsLimit
    ) {
      this.handleToastEvent({
        title: "Limit Exceeded",
        message: `You have chosen more than the maximum allowed number of recipients for this product line ( ${this.recipientsLimit} ).`,
        variant: "error",
        mode: "sticky"
      });
      return;
    }
    /* if (!selectedRecipients.some((sR) => sR.value == this.selectedPrimary)) {
      if (
        confirm(
          "Your primary recipient is not in the list of selected recipients. If you proceed, they will be added into the list and assigned as primary."
        )
      ) {
        selectedRecipients.push(
          this.data.find((d) => d.value == this.selectedPrimary)
        );
      } else {
        noPrimaryError();
        return;
      }
    } */
    this.isReady = !this.isReady;
    this.selectedRecipients = [];
    this.recipientsToDelete = [];
    // const existingRecipients = [...this.existingRecipients];
    const Id = this.currentOrderLineId;
    const newRecipientRecord = selectedRecipients.map((sR) => {
      let newSr = {
        sobjectType: "Order_Line_Recipient__c",
        Recipient__c: sR.value,
        OrderProductLine__c: Id
      };
      if (sR.Id) {
        newSr.Id = sR.Id;
      }
      if (this.selectedPrimary == sR.value) {
        newSr.Primary__c = true;
      } else {
        newSr.Primary__c = false;
      }
      return newSr;
    });
    /* const newIds = newRecipientRecord.filter((record) => record.Id);
    console.log(newRecipientRecord);
    existingRecipients.forEach((existing) => {
      if (existing.Id && !newIds.includes(existing.Id)) {
        recordToDelete.push({
          Id: existing.Id
        });
      }
    }); */
    const recipientRecords = {
      newRecords: newRecipientRecord,
      Id: Id,
      deleteRecords: recipientsToDelete
    };
    const submitEvent = new CustomEvent("addrecipient", {
      detail: recipientRecords
    });
    this.dispatchEvent(submitEvent);
  };

  getContacts = async () => {
    // const hasConditions =
    //   this.queryItems.marketId && this.queryItems.publicationYear;

    const hasConditions = this.queryItems.accountId != null;
    let whereCondition = null;
    if (hasConditions) {
      whereCondition = `WHERE Id = '${this.queryItems.contactIdFromOpp}' OR Account.Name = '${(this.queryItems.accountName).replace(/'/g, "\\'")}' OR AccountId = '${this.queryItems.accountId}'`;
      // whereCondition = `WHERE (Market_Project__c = '${this.queryItems.marketId}' AND Awarded_Years__c INCLUDES('${this.queryItems.publicationYear}')) OR Id='${this.queryItems.contactIdFromOpp}'`;
    }
    whereCondition += " ORDER BY LastName LIMIT 10000";
    const [contacts, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "Contact",
      fields: "Id, Name, Account.Name",
      hasConditions: hasConditions,
      conditions: whereCondition
    });
    if (error !== null) {
      console.error("CONTACT GET ERROR :" + JSON.stringify(error));
      return;
    } else {

      return contacts;
      // const [soleContact, err] = await getMLRecord({
      //   getFunction: doQuery,
      //   objectType: "Contact",
      //   fields: "Id, Name, Account.Name",
      //   hasConditions: true,
      //   conditions: `WHERE Id = '${this.queryItems.contactIdFromOpp}' LIMIT 1`
      // });
      // // console.log(contacts);
      
      // if (err) {
      //   console.error("CONTACT GET ERROR :" + JSON.stringify(err));
      //   return;
      // } else if (soleContact) {
      //     contacts.unshift(soleContact[0]);
      //     return contacts;
      // }
    }
  };

  loadData = (data) => {
    const searchTerm = this.searchTerm;
    let currentData;
    if (searchTerm) {
      currentData = data.filter(
        (d) =>
          d.Name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          d.Account.toLowerCase().includes(searchTerm.toLowerCase())
      );
    } else {
      currentData = data;
    }
    // this.selectedRows = [...this.selectedRows];
    // console.log(this.selectedRows);
    this.maxRows = currentData.length;
    this.data =
      currentData.length > 0 ? currentData.slice(0, this.rowLimit) : [];
  };

  handleSearch = (evt) => {
    this.searchTerm = evt.target.value;
    // console.log(evt.target.value);
    this.loadData(this.contactOptions);
  };

  handleLoadMore = (evt) => {
    if (evt.target) {
      evt.target.isLoading = true;
    }
    this.loadData(this.contactOptions);
    this.rowLimit = this.rowLimit + this.rowLimit;
    evt.target.isLoading = false;
    if (this.data.length >= this.maxRows) {
      this.enableInfiniteLoading = false;
      this.loadMoreStatus = "No more data to load";
    } else {
      this.loadMoreStatus = "";
    }
  };

  handleToggleSelected = (row) => {
    const selectedRow = { ...row };
    if (selectedRow.isSelected) {
      // iconName, buttonLabel, isSelected
      selectedRow.isSelected = false;
      selectedRow.buttonLabel = "Add Recipient";
      selectedRow.iconName = "utility:add";
      selectedRow.buttonVariant = "neutral";
      this.contactOptions = this.contactOptions.map((contact) => {
        if (contact.value == selectedRow.value) {
          return selectedRow;
        } else {
          return contact;
        }
      });
      this.loadData([...this.contactOptions]);
      this.selectedRecipients = this.selectedRecipients.filter(
        (rec) => rec.value !== selectedRow.value
      );
      if (selectedRow.Id) {
        this.recipientsToDelete = [...this.recipientsToDelete, selectedRow.Id];
      }
      this.primaryOptions = [...this.selectedRecipients];
      if (this.selectedPrimary == selectedRow.value) {
        this.selectedPrimary =
          [...this.primaryOptions].length > 0
            ? [...this.primaryOptions][0].value
            : null;
      }
    } else {
      selectedRow.isSelected = true;
      selectedRow.buttonLabel = "Remove Recipient";
      selectedRow.iconName = "utility:check";
      selectedRow.buttonVariant = "brand";
      this.contactOptions = this.contactOptions.map((contact) => {
        if (contact.value == selectedRow.value) {
          return selectedRow;
        } else {
          return contact;
        }
      });
      this.loadData([...this.contactOptions]);
      this.selectedRecipients = [...this.selectedRecipients, selectedRow];
      if (selectedRow.Id) {
        this.recipientsToDelete = this.recipientsToDelete.filter(
          (rec) => rec !== selectedRow.Id
        );
      }
      this.primaryOptions = [...this.selectedRecipients];
      if (!this.selectedPrimary) {
        this.selectedPrimary = selectedRow.value;
      }
    }
  };

  handleRowAction = (event) => {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case "toggle_selected":
        this.handleToggleSelected(row);
        break;
      default:
    }
  };

  async renderedCallback() {
    if (!this.isReady && this.currentOrderLineId && this.queryItems.isLoaded) {
      try {
        if (this.existingRecipients && this.existingRecipients.length > 0) {
          const existingRecipients = JSON.parse(
            JSON.stringify(this.existingRecipients)
          );
          // console.log(existingRecipients);
          const primary = existingRecipients.find(
            (data) => data.Primary__c == true
          );
          console.log(primary);
          this.selectedPrimary = primary.Recipient__c;
          /*  this.selectedRows = existingRecipients.map(
            (data) => data.Recipient__c
          );
          console.log({
            existing: existingRecipients
          }); */
          this.selectedRecipients = existingRecipients.map((data) => {
            const recipient = {
              label: data.Recipient__r.Name,
              value: data.Recipient__c,
              Name: data.Recipient__r.Name,
              Account: data.Recipient__r.Account.Name,
              ContactUrl: `/lightning/r/Contact/${data.Recipient__c}/view`,
              isSelected: true,
              iconName: "utility:check",
              buttonVariant: "brand",
              buttonLabel: "Remove Recipient"
            };
            if (data.Id) {
              recipient.Id = data.Id;
            }

            return recipient;
          });
          this.primaryOptions = [...this.selectedRecipients];
        }
        const allContacts = await this.getContacts();
        const selectedRecipients = [...this.selectedRecipients];
        const changedContacts = allContacts.map((all) => {
          if (selectedRecipients.some((sR) => sR.value == all.Id)) {
            return selectedRecipients.find((sR) => sR.value === all.Id);
          }
          return {
            label: all.Name,
            value: all.Id,
            Name: all.Name,
            Account: all.Account.Name,
            ContactUrl: `/lightning/r/Contact/${all.Id}/view`,
            isSelected: false,
            iconName: "utility:add",
            buttonVariant: "neutral",
            buttonLabel: "Add Recipient"
          };
        });
        this.contactOptions = changedContacts;
        this.loadData(changedContacts);
      } finally {
        this.isReady = true;
      }
    }
  }
}