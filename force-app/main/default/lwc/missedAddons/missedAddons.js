import { LightningElement, wire } from 'lwc';
import retrieveMissingAddons from '@salesforce/apex/missedAddonsHelper.retrieveMissingAddons';

export default class MissedAddons extends LightningElement {
    sortDirection='asc';
    sortedBy;
    missedAddonData = [];
    missedAddonCol = [
        {
            label: 'Parent Sub ID', 
            fieldName: 'Parent_Subscription__c_URL',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Parent_Subscription__c'
                }
            },
            sortable: true
        }, 
        {
            label: 'Parent Sub Name', 
            fieldName: 'Parent_Subscription__c_Name',
            sortable: true
        },
        {
            label: 'Addon Sub ID', 
            fieldName: 'Subscription__c_Id_URL',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Subscription__c_Id'
                }
            },
            sortable: true
        },
        {
            label: 'Addon Sub Name', 
            fieldName: 'Subscription__c_Name',
            sortable: true
        },
        {
            label: 'Boom Order', 
            fieldName: 'SalesOrder__c_Id_URL',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'SalesOrder__c_Name'
                }
            },
            sortable: true
        },
        {
            label: 'Boom Order Status', 
            fieldName: 'SalesOrder__c_Status_Picklist__c'
        }
    ];

    connectedCallback(){
        retrieveMissingAddons().then(result => {
            console.log(result);
            this.missedAddonData =  this.setMissedAddonData(result);
            console.log(this.missedAddonData);
        }).catch(e => {
            console.log(e);
        });
    }

    setMissedAddonData(missingAddonsArr) {
        let newArr = [];
        for(let i = 0; i < missingAddonsArr.length; i++) {
            let currObj = missingAddonsArr[i];
            let orderArr = currObj.salesorders;
            let subscription = currObj.subscription;

            let missingAddon = {};
            missingAddon.Parent_Subscription__c = subscription.Parent_Subscription__c;
            missingAddon.Parent_Subscription__c_URL = "/" + subscription.Parent_Subscription__c;
            missingAddon.Parent_Subscription__c_Name = subscription.Parent_Subscription__r.Name;
            missingAddon.Subscription__c_Id = subscription.Id;
            missingAddon.Subscription__c_Id_URL = "/" + subscription.Id;
            missingAddon.Subscription__c_Name = subscription.Name;
            
            for(let i = 0; i < orderArr.length; i++) {
                missingAddon.SalesOrder__c_Name = orderArr[i].Name;
                missingAddon.SalesOrder__c_Id_URL = "/" + orderArr[i].Id;
                missingAddon.SalesOrder__c_Status_Picklist__c = orderArr[i].Status_Picklist__c;
                newArr.push(missingAddon);
            }
        }
        return newArr;
    }

    handleSort( event ) {

        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.missedAddonData];

        cloneData.sort( this.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1 ) );
        this.missedAddonData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;

    }

    sortBy( field, reverse, primer ) {

        const key = primer
            ? function( x ) {
                  return primer(x[field]);
              }
            : function( x ) {
                  return x[field];
              };

        return function( a, b ) {
            a = key(a);
            b = key(b);
            return reverse * ( ( a > b ) - ( b > a ) );
        };

    }
}



/* 
    Label: Parent Sub ID / apiName: Subcription__c.Parent_Subscription__c (link to Parent Subscription)

    Label: Parent Sub Name / apiName: Subcription__c.Parent_Subscription__r.Name 

    Label: Addon Sub ID / apiName: Subscription__c.Id (link to Subscription)

    Label: Addon Sub Name / apiName: Subscription__c.Name

    Label: Boom Order / apiName: SalesOrder__c.Name; (link to order)

    Label: Boom Order Status / apiName: SalesOrder__c.Status_Picklist__c
*/