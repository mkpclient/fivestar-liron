import { LightningElement, api } from 'lwc';
import BILLSTREET from '@salesforce/schema/SalesOrder__c.BillToStreetLong__c';
import BILLCITY from '@salesforce/schema/SalesOrder__c.BillToCity__c';
import BILLSTATE from '@salesforce/schema/SalesOrder__c.BillToStateProvince__c';
import BILLCTRY from '@salesforce/schema/SalesOrder__c.BillToZipPostalCode__c';
import BILLZIP from '@salesforce/schema/SalesOrder__c.BillToCountry__c';
import SHIPSTREET from '@salesforce/schema/SalesOrder__c.ShipToStreetLong__c';
import SHIPCITY from '@salesforce/schema/SalesOrder__c.ShipToCity__c';
import SHIPSTATE from '@salesforce/schema/SalesOrder__c.ShipToStateProvince__c';
import SHIPCTRY from '@salesforce/schema/SalesOrder__c.ShipToZipPostalCode__c';
import SHIPZIP from '@salesforce/schema/SalesOrder__c.ShipToCountry__c';
import CONTACTBUYING from '@salesforce/schema/SalesOrder__c.ContactBuying__c'
import lockRecord from '@salesforce/apex/LWC.lockRecord';
import unlockRecord from '@salesforce/apex/LWC.unlockRecord';
import { updateRecord } from 'lightning/uiRecordApi';

export default class BoomOrderEditAddressesLwc extends LightningElement {
  fields = [BILLSTREET, BILLCITY, BILLSTATE, BILLCTRY, BILLZIP, SHIPSTREET, SHIPCITY, SHIPSTATE, SHIPCTRY, SHIPZIP];
  @api recordId;
  wasLocked;
  isPermanent = false;
  showForm = true;

  handleToggleChange(evt) {
    this.isPermanent = Boolean(evt.detail.checked);
  }

  async handleSubmit(evt) {
    evt.preventDefault();
    console.log("handle submit");
    const fields = evt.detail.fields;
    fields.Use_Billing_Address__c = false;
    
    this.wasLocked = await unlockRecord({ recordId: this.recordId });
    this.showForm = false;
    if(this.isPermanent) {
      const data = JSON.parse(JSON.stringify(fields));
      const newContact = {
        Id: data.ContactBuying__c,
        OtherStreet: data.ShipToStreetLong__c,
        OtherCity: data.ShipToCity__c,
        OtherState: data.ShipToStateProvince__c,
        OtherCountry: data.ShipToCountry__c,
        OtherPostalCode: data.ShipToZipPostalCode__c
      }
      const recordInput = {
        fields: { ...newContact }
      }
  
       updateRecord(recordInput)
        .then(() => {
          this.template.querySelector('lightning-record-edit-form').submit(fields);
        })
        .catch(error => {
          this.showForm = true;
          console.error(error);
        });
    } else {
      this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
  }

  handleClick(evt) {
    const name = evt.target.dataset.name;

    if(name == 'return') {
      window.location.href = '/' + this.recordId;
    }
  }

  handleError(error) {
    this.showForm = true;
    
    console.log(error);
  }

  async handleSuccess() {
    if(this.wasLocked) {
      await lockRecord({ recordId: this.recordId });
    }
    window.location.href = '/' + this.recordId;
  }

}