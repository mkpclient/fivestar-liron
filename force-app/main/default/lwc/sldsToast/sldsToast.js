import { api, LightningElement } from 'lwc';

export default class SldsToast extends LightningElement {
  @api title;
  @api message;
  @api variant;

  get privateClass() {
    return "slds-notify slds-notify_toast slds-theme_"  + this.variant;
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}