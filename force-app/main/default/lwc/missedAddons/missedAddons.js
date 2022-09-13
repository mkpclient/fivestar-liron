import { LightningElement } from 'lwc';

export default class MissedAddons extends LightningElement {}



/* 
    Label: Parent Sub ID / apiName: Subcription__c.Parent_Subscription__c (link to Parent Subscription)

    Label: Parent Sub Name / apiName: Subcription__c.Parent_Subscription__r.Name 

    Label: Addon Sub ID / apiName: Subscription__c.Id (link to Subscription)

    Label: Addon Sub Name / apiName: Subscription__c.Name

    Label: Boom Order / apiName: SalesOrder__c.Name; (link to order)

    Label: Boom Order Status / apiName: SalesOrder__c.Status_Picklist__c
*/