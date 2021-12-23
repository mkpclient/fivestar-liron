@istest 
public with sharing class FlowHelperTEST {
    @istest 
    static void test_get_values() {
        FlowHelper.queryForPicklistValues('Post Host', 'Opportunity', 'StageName');
    }

    @istest 
    static void test_handle_response_method() {
        HttpResponse res = new HttpResponse();
        res.setBody('{"controllerValues":{},"defaultValue":null,"eTag":"1fb39889b5165870a9eba7af9ff3c35f","url":"/services/data/v44.0/ui-api/object-info/Opportunity/picklist-values/012d0000002204yAAA/StageName","values":[{"attributes":{"closed":true,"defaultProbability":100.0,"forecastCategoryName":"Closed","picklistAtrributesValueType":"OpportunityStage","won":true},"label":"Purchased","validFor":[],"value":"Purchased"},{"attributes":{"closed":true,"defaultProbability":0.0,"forecastCategoryName":"Omitted","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"NON PURCHASER - No Response","validFor":[],"value":"NON PURCHASER - No Response"},{"attributes":{"closed":true,"defaultProbability":0.0,"forecastCategoryName":"Omitted","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"NON PURCHASER - Not Interested","validFor":[],"value":"NON PURCHASER - Not Interested"},{"attributes":{"closed":false,"defaultProbability":100.0,"forecastCategoryName":"Pipeline","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"Purchased - Follow up needed","validFor":[],"value":"Purchased - Follow up needed"},{"attributes":{"closed":false,"defaultProbability":25.0,"forecastCategoryName":"Pipeline","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"Follow Up - Appointment Scheduled","validFor":[],"value":"Follow Up - Appointment Scheduled"},{"attributes":{"closed":false,"defaultProbability":25.0,"forecastCategoryName":"Pipeline","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"Follow Up - Group","validFor":[],"value":"Follow Up - Group"},{"attributes":{"closed":false,"defaultProbability":25.0,"forecastCategoryName":"Pipeline","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"Follow Up - Low Interest","validFor":[],"value":"Follow Up - Low Interest"},{"attributes":{"closed":false,"defaultProbability":20.0,"forecastCategoryName":"Pipeline","picklistAtrributesValueType":"OpportunityStage","won":false},"label":"Alive","validFor":[],"value":"Alive"}]}');
        FlowHelper.handleResponse(res);
    }
}