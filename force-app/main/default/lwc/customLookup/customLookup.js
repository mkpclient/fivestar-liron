import { LightningElement,track,api } from 'lwc';
import getSearchResult from '@salesforce/apex/CustomLookupController.getSearchResult';


const DELAY = 100; 
const MIN_SEARCH_LEN = 3;
export default class poCustomLookup extends LightningElement {
    // api fields enabled for external access -- if nothing bind it defaults to Account.
    @api objectName = 'Contact';
    @api fieldName = 'Name';
    @api inputLabel = '';
    @api inputValue = '';
    @api iconName = 'standard:account';
    @api fieldLabel = '';
    @api searchPlaceholder = 'Search...';
    @api filterField;
    @api filterValue;
    @api required = false;


    ariaHidden = true;
    ariaExpanded = false;  
    isOptionSelected = false;
    selectedItem ; 
    isSearchResultLoading = false; 
    isFirstLoad = true; 
    listItems =  [ ]; // single sample input {label : 'Burlington Textiles Corp of America', value :'AA1231231231231'},
    isOverList = false;
    delayTimeout;
    hasBeenFocused = false;

    // these get parameters are generally for layout & visibility purposes
    get showFieldLabel(){
        return this.fieldLabel.length > 0;
    }
    get isSearchInProgress(){
        return this.isSearchResultLoading;
    }
    get noResultsReturned(){
        return this.listItems.length < 1;
    }
    get parentDivClass(){
        return 'slds-combobox__form-element slds-input-has-icon ' + (this.isOptionSelected ? 'slds-input-has-icon_left-right' : ' slds-input-has-icon_right');
    }
    get comboBoxContainerClass(){
        return 'slds-combobox_container ' + (this.isOptionSelected ? 'slds-has-selection' : '');
    }
    get showSearchIcon(){
        return !this.isOptionSelected;
    }
    get showCloseIcon(){
        return this.isOptionSelected;
    } 
    get inputClass() {  
        return 'slds-input slds-combobox__input ' + (this.ariaExpanded ? 'slds-has-focus ' : ' ') + (this.isOptionSelected ? 'slds-combobox__input-value' : '');
    }
    get comboBoxClass(){
        return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ' + ( this.ariaExpanded ? 'slds-is-open' : '');
    }
    get hasError () {
        return this.hasBeenFocused && this.required && !this.isOptionSelected;
    }

    get formClass() {
        return 'slds-form-element__control ' + (this.hasError ? 'slds-has-error' : '');
    }

    @api
    setListVisibility(visibility){
        this.ariaHidden = !visibility;
        this.ariaExpanded = visibility;
    }
    handleInputClick(event){
        console.log('handleInputClick');
        if(!this.hasBeenFocused) {
            this.hasBeenFocused = true;
        }
        if(!this.isOptionSelected){
            this.setListVisibility(true);
            this.inputLabel = '';
        }   
    }
    triggerChangeEvent(){ // to dispatch the event outside of this lwc(lookup) controller
        var label = this.inputLabel;
        var value = this.inputValue;
        var objectname = this.objectName;
        const optionchangedEvent = new CustomEvent('select', { detail: {label , value, objectname}, });
        this.dispatchEvent(optionchangedEvent); 
    }

    @api
    emptySelection(){
        this.isOptionSelected = false;
        this.selectedItem = null;
        this.inputLabel = '';
        this.inputValue = '';
        this.setListVisibility(true);
        this.triggerChangeEvent();
    }
    
    handleSelectRemoval(event){
       if(!this.isOptionSelected){
            return;
       }
       this.emptySelection();
    }
    delayedFireFilterChangeEvent() { 
        console.log('delayedFireFilterChangeEvent');
        window.clearTimeout(this.delayTimeout); 
        this.delayTimeout = setTimeout(() => {
            this.searchRecords();
        }, DELAY);
    }
    handleKeyUp(e){
        //console.log('e.keyCode==>',e.keyCode);
        console.log("YOUR KEY CODE IS: " + e.keyCode);
        let value = e.target.value;
        if(value.length > 0 && value[0] == ' '){
            value=  value.replace(' ', '');
        }
        this.inputLabel = value;
        if(value < MIN_SEARCH_LEN){ // do not search before min chars required
            // if (e.keyCode == 8) this.listItems = []; //backspace
            return;
        }
        // if (!this.isSearchChar(e.keyCode) && e.keyCode != 8) {
        //     this.inputLabel = e.target.value.slice(0,-1); //remove last char
        //     return;
        // }
        this.delayedFireFilterChangeEvent();
    } 
    isSearchChar(code) {
        if (code > 13 && code < 17) return true; //shift sequence (caps)
        if (!(code > 31 && code < 123) //most of the keyboard
            && !(code == 45) 
            && !(code == 34) 
            && !(code == 37) 
            && !(code == 39) 
            && !(code == 42) 
            && !(code == 44)) { //hyphen, double quote, percent, single quote, asterisk, backtick
                console.log(code + ' is not a legit search character');
                return false;
        }
        return true;
    }
    selectionChanged(item,defaultValueSelected){ // sets statuses for all fields 
        this.selectedItem = item.detail;
        if(!this.hasBeenFocused) {
            this.hasBeenFocused = true;
        }
        // selected items fields.
        this.inputLabel = this.selectedItem.label;
        this.inputValue = this.selectedItem.value;

        this.isOptionSelected = true;
        this.setListVisibility(false); 
        if(!defaultValueSelected) // if it's default value is bind from a parent, it should't re-trigger change event to parent..
            this.triggerChangeEvent();
        this.listItems = [];
    }

    handleOutEvent(event){    // to close the list result of lookup
        console.log('handleOutEvent');
        if(this.isOverList){  // unless user is over the list component.
            return;
        }
        this.setListVisibility(false);
        if (!this.isOptionSelected) this.listItems = [];
    }
    overList(){
        this.isOverList = true;
    }

    @api
    outList(){ 
        this.isOverList = false;
    }
    searchRecords() { 
        console.log('searchRecords');
        this.isSearchResultLoading = true; 
        if (this.filterField && this.filterValue && this.filterField.length > 0 && this.filterValue.length > 0){
            getSearchResult({ objectName: this.objectName, fieldName: this.fieldName, value: this.inputLabel, filterField: this.filterField, filterValue: this.filterValue })
            .then(result => { 
                this.listItems = result;
                this.isSearchResultLoading = false; 
                if(!this.isOptionSelected)
                    this.setListVisibility(true);
            })
            .catch(error => {
                console.log('getSearchResult error:', JSON.stringify(error));
                const errorEvent = new CustomEvent('lookuperror', { detail: error });
                this.dispatchEvent(errorEvent); 
            });
        } else {
            getSearchResult({ objectName: this.objectName, fieldName: this.fieldName, value: this.inputLabel })
            .then(result => { 
                this.listItems = result;
                this.isSearchResultLoading = false; 
                if(!this.isOptionSelected)
                    this.setListVisibility(true);
            })
            .catch(error => {
                console.log('getSearchResult error:', JSON.stringify(error));
                const errorEvent = new CustomEvent('lookuperror', { detail: error });
                this.dispatchEvent(errorEvent); 
            });
        }

    }
    connectedCallback(){
        if(this.isFirstLoad){  // 
           this.isFirstLoad = false;
           if(this.inputValue != ''){ // if default data is bound , to set statuses of all components act like selectionChanged event occured.
                this.selectionChanged({ detail : {label:this.inputLabel,value:this.inputValue}},true); // simulate like selected from layout
           }
        }
   }

   @api
   checkForErrors() {
       if(this.required && !this.isOptionSelected) {
            this.template.querySelector('input').focus();
       }
       if(!this.hasBeenFocused) {
            this.hasBeenFocused = true;
       }
       return this.required && !this.isOptionSelected;
   }
}