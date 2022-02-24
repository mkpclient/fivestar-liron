import { LightningElement,api } from 'lwc';

export default class poCustomLookupItem extends LightningElement {
    @api key;
    @api item;
    @api iconname = 'standard:account'; 

    // in each child item, it handles the change event and throws up to parent component which is the component itself
    handleSelected(event){
        var value = event.currentTarget.dataset.id;
        var label = event.currentTarget.dataset.name;
        const selectedEvent = new CustomEvent('selected', { detail: {label , value}, }); 
        this.dispatchEvent(selectedEvent);
    }
}