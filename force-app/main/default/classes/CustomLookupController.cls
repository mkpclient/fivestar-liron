public without sharing class CustomLookupController {
    private static final integer minLength = 0; 

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getSearchResult(String objectName, String fieldName, String value) {
        return getSearchResult(objectName,fieldName,value,null,null);
    }
    //weakness: can only filter on strings/ids currently
    //This method got kind of screwy once all requirements were revealed over time. Maybe needs refactoring.
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getSearchResult(String objectName, String fieldName, String value, String filterField, String filterValue) {
        system.debug('getSearchResult fired');
        system.debug('fieldName: ' + fieldName);
        system.debug('value: ' + value);
        system.debug('filterField: ' + filterField);
        system.debug('filterValue: ' + filterValue);
        system.debug('objectName: ' + objectName);

        fieldName = string.escapeSingleQuotes(fieldName);
        value = string.escapeSingleQuotes(value);
        objectName = string.escapeSingleQuotes(objectName);
        if (filterValue != null) filterValue = string.escapeSingleQuotes(filterValue);
        if (filterField != null) filterField = string.escapeSingleQuotes(filterField);

        String soql = 'Select Id,';
        if (fieldName != 'Name') soql += 'Name,';
        soql += fieldName + ' FROM ' + objectName + ' WHERE ' + fieldName + ' LIKE \'%' + value + '%\' ';
        if (filterField != null && filterValue != null){
            soql += ' AND ' + filterField + ' = \'' + filterValue + '\'';
        }

        soql += ' ORDER BY ' + fieldName + ' LIMIT 20';
        system.debug('soql: ' + soql);

        List<LookupSearchResult> lookupResult = new List<LookupSearchResult>(); 
        if(String.isNotEmpty(value) && value.length() >= minLength)
            for(sObject so : Database.Query(soql)) {
                String fieldLabel;
                if (fieldName != 'Name') {
                    fieldLabel = (String)so.get('Name') + ' (' + String.valueof(so.get(fieldName)) + ')';
                }
                else {
                    fieldLabel = (String)so.get('Name');
                }
                lookupResult.add(new LookupSearchResult(fieldLabel, so.Id));
            }
        return lookupResult;
    }
    //return entity type for Search Results
    public class LookupSearchResult {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Id value;
        
        public LookupSearchResult(String label, Id value) {
            this.label = label;
            this.value = value;
        }
    }
}