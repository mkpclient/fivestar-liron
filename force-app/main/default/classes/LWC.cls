public without sharing class LWC {
  @AuraEnabled
  public static Object getFieldLabels(String tables) {
    Map<String, Set<String>> fields = new Map<String, Set<String>>();
    List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(
      tables.split(', ')
    ); // either split string or deserialize into list of Schema.D...etc

    for (Schema.DescribeSobjectResult result : results) {
      List<Schema.SObjectField> keys = result.fields.getMap().values();
      Set<String> labels = new Set<String>();
      for (Schema.SObjectField key : keys) {
        labels.add(String.valueOf(key));
      }
      fields.put(result.getName(), labels);
    }

    return (Object) JSON.deserializeUntyped(JSON.serialize(fields));
  }

  @auraEnabled
  public static List<sObject> doQuery(String queryString) {
    System.debug(queryString);
    return database.query(queryString);
  }

  @AuraEnabled
  public static void deleteRecord(sObject record) {
    try {
      delete record;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=false)
  public static sObject saveRecord(sObject record) {
    system.debug(record);
    try {
      upsert record;
      return record;
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Boolean unlockRecord(String recordId) {
    if(Approval.isLocked(recordId)) {
      Approval.unlock(recordId);
      return true;
    } else {
      return false;
    }
  }

  @AuraEnabled
  public static void lockRecord(String recordId){
    Approval.lock(recordId);
  }
  


  @AuraEnabled
  public static List<SObject> saveMultipleRecords(List<SObject> records){
    try {
      upsert records;
      return records;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteMultipleRecords(List<SObject> records){
    try {
      delete records;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteRecordWithQuery(String queryString) {
    List<SObject> recordToDelete;
    try {
      recordToDelete = database.query(queryString);
      delete recordToDelete;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void attachPDF(Id recordId, String soName){
    PageReference p = Page.SalesOrderPDF;
    p.getParameters().put('id',recordId);

    Blob body;
    if(Test.isRunningTest()) {
      body = Blob.valueOf('testblob');
    } else {
      body = p.getContent();
    }

    Attachment a = new Attachment();
    a.ParentId = recordId;
    a.Body = body;
    a.Name = soName+'.pdf';
    insert a;
  }
}