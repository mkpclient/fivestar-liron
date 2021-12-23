import { LightningElement, api } from 'lwc';

export default class ManageLinesEditLine extends LightningElement {
  @api orderLineId;

  handleFormSuccess = () => {
    this.dispatchEvent(
      new CustomEvent("success")
    );
  };

  handleFormCancel = () => {
    this.dispatchEvent(
      new CustomEvent("cancel")
    )
  }
}