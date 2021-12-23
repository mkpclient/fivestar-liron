/*****************************************************************************************
*    Class Name:        kuga_ImportHelper
*
*    Class Type:        Batch
*    
*    Description:       This class is used to parse the csv file to capture missing Authorize.Net payments via "Authorize.Net Subscription Email Handler" Email Service
*
*   Test Methods:       kuga_AuthNetEmailHandlerTests
*
*   Class History:      Created by Kiran Kurella Nov 20th 2017
*
*   Copyright 2017 Kugamon.  All rights reserved.
*****************************************************************************************/

public with sharing class kuga_ImportHelper {    

    public static String getFieldValue(list<String> fieldValues, Integer index) {
        try {
            return (fieldValues[index]==null ? null : fieldValues[index].trim());
        } catch (Exception e) {
            return null;
        }
    }

    public static Decimal convert(String newVal, Decimal defaultVal) {
        try {
            if (kugo2p.Util.isNullOrEmpty(newVal)) return defaultVal;
            return Decimal.valueOf(newVal.replace('$','').replace(',',''));
        } catch (Exception e) {
        	system.debug(' ### error in converting String value ' + newVal);
            return null;
        }
    }

    public static Integer convertInt(String newVal, Integer defaultVal) {
        try {
            if (kugo2p.Util.isNullOrEmpty(newVal)) return defaultVal;
            return Integer.valueOf(newVal.replace('$','').replace(',',''));
        } catch (Exception e) {
        	system.debug(' ### error in converting String value to Integer ' + newVal);
            return null;
        }
    }

    public static list<list<String>> parseCSV(String contents) {
        list<list<String>> allFields = new list<list<String>>();
        
        if (contents == null) contents = '';
        
        contents = contents.replace('"','');

        //system.debug(' ### contents before ' + contents);
        contents = contents.replace('&quot;','"');

        //multiple replace - evaluates from left to right
        contents = contents.replace(',"""',',"DBLQT').replace('""",','DBLQT",');
        contents = contents.replace('""','DBLQT');

        //system.debug(' ### contents after ' + contents);

        list<String> lines = new list<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines) {
            if (line.replace(',','').trim().length() == 0) break;
            
            list<String> fields = line.split(',');
            list<String> cleanFields = new list<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            
            //system.debug(' ### fields.size ' + fields.size() + ' => ' + fields);
            for(String field : fields) {
                
                //system.debug(' ### field ' + field);
                //if (field == '"') system.debug(' ### field is a double quote ' + field.endsWith('"'));
                
                if (field.startsWith('"') && field.endsWith('"') && field != '"') {
                    //field = field.substring(1);
                    //if (field.length() > 0) field = field.substring(0, field.length()-1);                 
                    cleanFields.add(field.replace('DBLQT','"'));
                } else if (field.startsWith('"') && field != '"') {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    //system.debug(' ### compositeField ' + compositeField);
                    compositeField += ',' + field;                  
                    compositeField = compositeField.substring(1);                   
                    compositeField = compositeField.substring(0, compositeField.length()-1);                    
                    //system.debug(' ### compositeField ' + compositeField.replace('DBLQT','"'));
                    cleanFields.add(compositeField.replace('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replace('DBLQT','"'));
                }
            }
            
            //system.debug(' ### cleanFields.size ' + cleanFields.size() + cleanFields);
            allFields.add(cleanFields);
        }
        
        //if (skipHeaders) allFields.remove(0);
        //system.debug(' ### allFields.size ' + allFields.size() + ' => ' + allFields);
        
        //for (list<String> ls: allFields) {
            //system.debug(' ### allFields per row owner: ' + ls[4] + ' origin name: ' + ls[14] + ' Dest Name: ' + ls[20]);
            //system.debug(' ### allFields per row owner: ' + ls[4]);
        //}
        
        return allFields;
    }
}