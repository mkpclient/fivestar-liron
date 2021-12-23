import cloneBoomOrder from '@salesforce/apex/BoomOrderCloneController.cloneBoomOrder';
import { api, LightningElement } from 'lwc';

export default class CloneBoomOrder extends LightningElement {
  @api recordId;
  
  async connectedCallback() {
   try {
    const result = await cloneBoomOrder({
      recordId: this.recordId
    });
    window.location.replace("/" + result);
   } catch(err) {
      console.log(err);
   }
    
  }
}