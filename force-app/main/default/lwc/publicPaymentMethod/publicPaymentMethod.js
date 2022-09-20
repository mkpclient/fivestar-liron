import { api, LightningElement } from 'lwc';

export default class PublicPaymentMethod extends LightningElement {
  @api recordId;
  @api orderId;
}