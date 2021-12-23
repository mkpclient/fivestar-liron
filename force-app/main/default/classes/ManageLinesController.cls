public with sharing virtual class ManageLinesController {
  public String lineType { get; set; }
  protected list<String> deleteLineIds { get; set; }

  public map<Id, list<kugo2p__Tier__c>> mapProductTiers;
  public map<Id, list<RecommendedProduct__c>> mapproductId_to_RecommendedProducts;
  
  // Five Star changes
  protected map<Id, list<Contact>> mapProductId_To_Recipients;
  protected map<Id, list<LineRecipient__c>> mapProductId_To_SOPLRecipients;
  protected map<Id, Contact> mapUsedRecipients;
  public ManageRecipientController manageRecipientCon {get; set;}
  public boolean showRecipient {get; set;}
  protected String mode;
	protected Id recordId;
	protected Contact contactBuying;
	//private String marketId = getPageParameter('marketId');
	public String marketId;
	public String publicationYear;    

  public ManageLinesController(){
    ProductLines = new list<LineItemInfo>();
    SelectedLines = new list<LineItemInfo>();
    StartIndex = 0;
    PageSize = 100;
    CurrentPage = 1;
    TotalProductsQty = '';
    TotalServicesQty = '';
    TotalProductsAmount = '';
    TotalServicesAmount = '';
    QueryKey = '';
    ExactMatch = false;
    isPriceBookValid = true;
    isPriceBookActive = true;
    dummyStartDate = new OpportunityLineItem();

    this.sortDirection = 'asc';
    showMoreFilters = false;
  }
    
  public list<LineItemInfo> SelectedLines { get; set; }
  public list<LineItemInfo> ProductLines { get; set; }
  public Integer StartIndex { get; set; }
  public Integer PageSize { get; set; }
  public Integer CurrentPage { get; set; }
  public String TotalProductsQty { get; private set; }
  public String TotalServicesQty { get; private set; }
  public String TotalProductsAmount { get; private set; }
  public String TotalServicesAmount { get; private set; }
  public boolean hasInactiveLines = false;
  public String QueryKey { get; set; }    
  public boolean ExactMatch {get; set;}
  public String PricebookName { get; set; }
  public String PricebookNameOptionValue { get; set; }
  public String recordStatus { get; set; }
  public String currencyCode  { get; set; }
  public String currencySymbol  { get; set; }
  public OpportunityLineItem dummyStartDate { get; set; }
  public List<FilterWrapper> filters {get; set;}
  public boolean showMoreFilters {get; set;}    
  public Decimal headerDiscountValue { get; set; }
  public String headerDiscount {
    get {
      return convertToFormattedString(headerDiscountValue, 2);
    }
    set {
      try {
        headerDiscountValue = convertToDecimal(value);
      } catch(Exception ex) {
        headerDiscountValue = 0;
      }
    }
  }
    
  public map<Id, list<kugo2p__Tier__c>> getProductIdToTiers() {
    return mapProductTiers != null ? mapProductTiers : new map<Id, list<kugo2p__Tier__c>>();    
  }

	public boolean hasTieredPricingProducts {
		get {
			boolean retVal = false;
			if (SelectedLines != null) {
        for (LineItemInfo lineItem : SelectedLines) {
          if (lineItem.tiers != null && !lineItem.tiers.isEmpty()) {
            retVal = true;
            break;
          }
        }
			}
      return retVal;
		}
	}

  public list<LineItemInfo> getSelectedProducts() {
    list<LineItemInfo> lineItems_To_Return = new list<LineItemInfo>(); 
    if (SelectedLines != null) {
      for (LineItemInfo lineItem : SelectedLines) {
        if (!lineItem.IsService) lineItems_To_Return.add(lineItem);
      }
    }
    //return sortLineItems(lineItems_To_Return);
    return lineItems_To_Return;
  }
    
  public list<LineItemInfo> getSelectedServices() {
    list<LineItemInfo> lineItems_To_Return = new list<LineItemInfo>(); 
    if (SelectedLines != null) {
      for (LineItemInfo lineItem : SelectedLines) {
        if (lineItem.IsService) lineItems_To_Return.add(lineItem);
      }
    }
    //return sortLineItems(lineItems_To_Return);
    return lineItems_To_Return;
  }

  public static kugo2p__KugamonSetting__c Settings {
    get {
      if (Settings == null) {
        // try {
          Settings = Database.query(
						'Select Id, ' + CurrencyIsoCodeField + ' k.kugo2p__PaymentMethod__c, k.kugo2p__PaymentTerms__c, k.kugo2p__DeliveryTerms__c, k.kugo2p__CreditTerms__c, ' + 
						'k.kugo2p__Carrier__c, kugo2p__Hide_Ship_To_on_Quote_Order_PDF__c, k.kugo2p__OnlinePaymentLogoinPDFSourceURL__c, ' +
						'k.kugo2p__ProductSchedulingEnabled__c, k.kugo2p__RemitToName__c, k.kugo2p__PrintInvoiceTextAndTerms__c, k.kugo2p__InvoiceTextAndTerms__c, k.kugo2p__DayofRevenueRecognition__c, k.kugo2p__RemitToStreet__c, ' + 
						'k.kugo2p__RemitToCity__c, k.kugo2p__RemitToStateProvince__c, k.kugo2p__RemitToZipPostalCode__c, k.kugo2p__RemitToCountry__c, k.kugo2p__ACName__c, k.kugo2p__ACNumber__c, k.kugo2p__ABANumber__c, ' + 
						'k.kugo2p__BankName__c, k.kugo2p__Warehouse__c, k.kugo2p__VAT__c, k.kugo2p__UnitofMeasure__c, k.kugo2p__UnitOfTerm__c, k.kugo2p__TaxableVAT__c, k.kugo2p__TaxableUsage__c, ' + 
						'k.kugo2p__TaxableSales__c, k.kugo2p__TaxableExcise__c, k.kugo2p__SpecificTextandTerms__c, k.kugo2p__SalesQuoteValidOfferInDays__c, k.kugo2p__PrintSpecificTextandTerms__c, ' + 
						'k.kugo2p__PrintCompanyTextandTerms__c, k.kugo2p__PriceBookName__c, k.kugo2p__DefaultInvoiceSchedule__c, k.kugo2p__CompanyTextandTerms__c, ' + 
						'k.kugo2p__SignatureLinestoPDF__c, k.kugo2p__ListPriceColumnonPDF__c, k.kugo2p__AutoReleaseOrder__c, k.kugo2p__DefaultEcommerceShippingCharge__c, ' + 
						'k.kugo2p__DefaultEcommerceTaxCharge__c, kugo2p__DaysTillPaymentDue__c, kugo2p__BillingMethod__c, kugo2p__OnlinePaymentButton__c, k.kugo2p__SWIFT_Code__c, ' + 
						'kugo2p__Hide_Shipment_Information_on_Invoice_PDF__c, kugo2p__AllowOverrideServiceDateUpdate__c, DisableQuoteOptionalManagedLines__c ' +
						// Five Star changes
						', FinanceRate__c, DefaultFinanceCharge__c, DefaultFreeFinancingCredit__c, FinanceOverrideProfile__c, kugo2p__Admin_User__r.Email ' +
						// Five Star changes - FS04
						', kuga_CalculateFinanceRatebyTerm__c ' + 
            'From kugo2p__KugamonSetting__c k LIMIT 1'
          );
        // } catch (System.QueryException e) { 
          // system.debug(' ### error in getting settings object ' + e.getMessage());
        // }
      }
      return Settings;
    }
    public set;
  }

  public boolean allowOverrideServiceDateUpdate {
    get {
      if (allowOverrideServiceDateUpdate == null) allowOverrideServiceDateUpdate = Settings.kugo2p__AllowOverrideServiceDateUpdate__c;
      return allowOverrideServiceDateUpdate;
    }
    private set;
  }

  public boolean disableQuoteOptionalManagedLines {
    get {
      if (disableQuoteOptionalManagedLines == null) disableQuoteOptionalManagedLines = Settings.DisableQuoteOptionalManagedLines__c==null ? false : Settings.DisableQuoteOptionalManagedLines__c;
      return disableQuoteOptionalManagedLines;
    }
    private set;
  }

  public PageReference cancel() {
    return new PageReference('/'+getPageParameter('id'));
  }
    
  public static String escapeSingleQuotes(String param) {
    if (param != null) return String.escapeSingleQuotes(param);
    return null;
  }

  public static String getPageParameter(String param) {
    if (ApexPages.currentPage().getParameters().containsKey(param)) {
      return escapeSingleQuotes(ApexPages.CurrentPage().getParameters().get(param)).replace('%2F', '');
    }
    return ApexPages.currentPage().getParameters().get(param);
  }    
    
  public Integer PageCounts {
    get {
      return ((Decimal)ProductLines.size() / PageSize).round(System.RoundingMode.UP).intValue();
    }
  }

  public list<SelectOption> PricebookOptions {
    get {
      if(PricebookOptions == null) {
        PricebookOptions = new list<SelectOption>();
        boolean foundPricebook = false;

                //system.debug(' ### lineType ' + lineType);
                map<Id, PriceBook2> mapPricebooks = new map<Id, PriceBook2>([SELECT Id, Name FROM Pricebook2 WHERE IsActive = true ORDER BY Name]);

                try {
                    // we can only query upto 200 records from UserRecordAccess object
                    for (UserRecordAccess recAccess : [SELECT RecordId from UserRecordAccess Where UserId = :UserInfo.getUserId() AND RecordId IN :mapPricebooks.keySet() and HasReadAccess = true]) {  //, HasReadAccess, HasEditAccess, HasDeleteAccess
                        Pricebook2 pb = mapPricebooks.get(recAccess.RecordId);
						if (!foundPricebook) foundPricebook = lineType=='Opportunity' ? (PricebookNameOptionValue==pb.Id) : (PricebookNameOptionValue==pb.Name);

                        PricebookOptions.add(new SelectOption( (lineType=='Opportunity' ? String.valueOf(pb.Id) : pb.Name), pb.Name));
                    }
                } catch (exception ex) {
                    system.debug(' ### exception in PricebookOptions ' + ex);
                    /*for (Pricebook2 pb : mapPricebooks.values()) {
                    	if (!foundPricebook) foundPricebook = lineType=='Opportunity' ? (PricebookNameOptionValue==pb.Id) : (PricebookNameOptionValue==pb.Name);

                        PricebookOptions.add(new SelectOption( (lineType=='Opportunity' ? String.valueOf(pb.Id) : pb.Name), pb.Name));
                    }*/
                    assignPricebookOptions(mapPricebooks.values(), foundPricebook);
                }

				system.debug(' ### foundPricebook ' + foundPricebook + ' lineType ' + lineType + ' PricebookName ' + PricebookName + ' PricebookNameOptionValue ' + PricebookNameOptionValue);
                if (!foundPricebook && String.isNotBlank(PricebookNameOptionValue) && String.isNotBlank(PricebookName)) {
                	PricebookOptions.add(new SelectOption(PricebookNameOptionValue, PricebookName, true));
                }
            }
            return PricebookOptions;
        }
        private set;
    }

    public void assignPricebookOptions(list<PriceBook2> pricebooks, boolean foundPricebook) {
    	if (pricebooks != null && !pricebooks.isEmpty()) {
            for (Pricebook2 pb : pricebooks) {
            	if (!foundPricebook) foundPricebook = lineType=='Opportunity' ? (PricebookNameOptionValue==pb.Id) : (PricebookNameOptionValue==pb.Name);

                PricebookOptions.add(new SelectOption( (lineType=='Opportunity' ? String.valueOf(pb.Id) : pb.Name), pb.Name));
            }
    	}
    }

    public map<Id, kugo2p__AdditionalProductDetail__c> getProductAPD(set<Id> productIds) {
        map<Id, kugo2p__AdditionalProductDetail__c> mapProductId_To_APD = new map<Id, kugo2p__AdditionalProductDetail__c>();

        for (kugo2p__AdditionalProductDetail__c apd : [select Id, Name, kugo2p__NonStock__c, kugo2p__KitBundlePricing__c, kugo2p__KitBundle__c, kugo2p__Service__c, kugo2p__ReferenceProduct__c, 
        													  kugo2p__ReferenceProduct__r.SalesInstruction__c, kugo2p__ReferenceProduct__r.ProductCode, kugo2p__UnitofTerm__c,
        													  kugo2p__DefaultServiceTerm__c, kugo2p__Active__c, kugo2p__Hide__c,
        													  // Five Star changes
        													  LockPrice__c, RecipientLimit__c, CreateOrderFulfillment__c, NumberofOrderFulfillments__c, 
        												(Select Id, Name, kugo2p__Quantity__c, kugo2p__Required__c, kugo2p__AllowQuantityChange__c, kugo2p__ReferenceKitBundle__c, kugo2p__ReferenceMemberProductService__c, 
        														kugo2p__ReferenceMemberProductService__r.Name, kugo2p__ReferenceMemberProductService__r.kugo2p__Active__c, 
        														kugo2p__ReferenceMemberProductService__r.kugo2p__UnitofTerm__c, kugo2p__ReferenceMemberProductService__r.kugo2p__DefaultServiceTerm__c, 
        														kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__c, 
        														kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__r.SalesInstruction__c, 
        														kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__r.ProductCode, kugo2p__ReferenceMemberProductService__r.kugo2p__StandardPrice__c, 
        														kugo2p__ReferenceMemberProductService__r.kugo2p__KitBundle__c, kugo2p__ReferenceMemberProductService__r.kugo2p__KitBundlePricing__c, 
        														kugo2p__ReferenceMemberProductService__r.kugo2p__Service__c, kugo2p__ReferenceMemberProductService__r.kugo2p__NonStock__c
        														// Five Star changes
        														, kugo2p__ReferenceMemberProductService__r.LockPrice__c, kugo2p__ReferenceMemberProductService__r.RecipientLimit__c, kugo2p__ReferenceMemberProductService__r.CreateOrderFulfillment__c,
        														kugo2p__ReferenceMemberProductService__r.NumberofOrderFulfillments__c
        												from kugo2p__KitBundles__r order by Name)
        											  from kugo2p__AdditionalProductDetail__c where kugo2p__ReferenceProduct__c in : productIds]) {
            mapProductId_To_APD.put(apd.kugo2p__ReferenceProduct__c, apd);
        }

        return mapProductId_To_APD;
    }
    
    public PageReference search() {
        
        Boolean resetSize = (PageSize == ProductLines.size());
        ProductLines.clear();

        if (exactMatch && this.QueryKey == '') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Search Keyword must be entered for Exact Match.'));
            return null;
        }

        ProductLines = initProductLines(PricebookName, QueryKey, ExactMatch);
        resetFavorites();
        PageSize = (resetSize) ? ProductLines.size() : PageSize;
        StartIndex = 0;
        CurrentPage = 1;
        
        return null;
    }
        
	public boolean isPriceBookValid {get; set;}
    public boolean isPriceBookActive {get; set;}
    public map<Id, decimal> unitPriceMap = new map<Id, decimal>();
    protected map<Id, Id> mapProductId_To_PBEId = new map<Id, Id>();
    public transient map<String, String> mapAutoCompleteSource {get; set;}
    {
        mapAutoCompleteSource = new map<String, String>{};
    }    
    public String pcodeSeparator {get; set;}
    {
        pcodeSeparator = ' ~ ';
    }
    // Five Star changes
    public map<String, String> mapAutoCompleteSourceRecipients {get; set;}
    {
        mapAutoCompleteSourceRecipients = new map<String, String>{};
    }

    public Integer getTotalProductsCount() {
        return unitPriceMap==null ? 0 : unitPriceMap.size();
    }

    public void initUnitPriceMap() {
        list<Pricebook2> pbs = Database.query('select Id, IsActive, ' +
        									   '(select Product2Id, Product2.Name, Product2.ProductCode, UnitPrice from PricebookEntries where Product2.IsActive = true and IsActive = true ' + 
        									   	(Kugo2p.Util.isNullOrEmpty(currencyCode) ? '' : ' and CurrencyIsoCode = \'' + currencyCode  + '\' ' ) + ') ' +
        									   'from Pricebook2 where Name = :PricebookName limit 1');

        isPriceBookValid = !pbs.isEmpty();
        if (pbs.size() == 1) {
            isPriceBookActive = pbs[0].IsActive;

            String productNameAndCode;
            if (mapAutoCompleteSource == null) mapAutoCompleteSource = new map<String, String>{};
            if (unitPriceMap == null) unitPriceMap = new map<Id, decimal>();

            for (PricebookEntry pbe : pbs[0].PricebookEntries) {
                unitPriceMap.put(pbe.Product2Id, pbe.UnitPrice);
                if (lineType == 'Opportunity') mapProductId_To_PBEId.put(pbe.Product2Id, pbe.Id);
                
                productNameAndCode = pbe.Product2.Name + (String.isBlank(pbe.Product2.ProductCode) ? '' : (pcodeSeparator + pbe.Product2.ProductCode));
                mapAutoCompleteSource.put(productNameAndCode, productNameAndCode);
            }
        }
        system.debug(' ### unitPriceMap ' + unitPriceMap.size() + ' => ' + unitPriceMap);
        system.debug(' ### mapAutoCompleteSource ' + mapAutoCompleteSource.size());
    }
    
    public boolean showAdditionalDetails = false;
    public void initFilters() {
        filters = new List<FilterWrapper>();

        system.debug(' ### showAdditionalDetails in initFilters ' + showAdditionalDetails);
        for (Integer i = 0; i < 5; i++) {
            filters.add(new FilterWrapper(i, showAdditionalDetails));
        }
    }

    public void resetSearch() {
        QueryKey = '';
        ExactMatch = false;

        initFilters();
    }    

    public virtual PageReference clearSearch() {
        resetSearch();

        //return null;
        return search();
    }
    
    public String buildFilterWhereClause() {
        String whereClause = '';
        for (FilterWrapper cur : filters) {
            if (cur.selectedFieldName != null && cur.selectedFieldName != '--None--' && cur.selectedOperator != null && cur.selectedOperator != '--None--') {
                Schema.DisplayType selectedType;
                
                Map<String, Schema.SObjectField> productMap = Schema.SObjectType.Product2.fields.getMap();
                Map<String, Schema.SObjectField> addProdMap = Schema.SObjectType.kugo2p__AdditionalProductDetail__c.fields.getMap();
                if (productMap.containsKey(cur.selectedFieldName)) {
                    selectedType = productMap.get(cur.selectedFieldName).getDescribe().getType();
                } else if (addProdMap.containsKey(cur.selectedFieldName)) {
                    selectedType = addProdMap.get(cur.selectedFieldName).getDescribe().getType();
                } else {
                    selectedType = Schema.DisplayType.INTEGER;
                }

                boolean useMultiIn = false;
                String fieldValue;
                //String fieldName = (cur.objectType == 'additionalDetails') ? cur.selectedFieldName : ('kugo2p__ReferenceProduct__r.' + cur.selectedFieldName);

                //String fieldName = (cur.objectType == 'additionalDetails') ? cur.selectedFieldName : 'kugo2p__ReferenceProduct__r.' + cur.selectedFieldName;
                //String fieldName = (cur.objectType == 'additionalDetails') ? cur.selectedFieldName : 'Product2.' + cur.selectedFieldName;

                String fieldName = (cur.objectType == 'additionalDetails') ? cur.selectedFieldName : ( (showAdditionalDetails ? 'kugo2p__ReferenceProduct__r.' : 'Product2.') + cur.selectedFieldName);

                if (selectedType == Schema.DisplayType.COMBOBOX
                    || selectedType == Schema.DisplayType.EMAIL
                    || selectedType == Schema.DisplayType.PHONE
                    || selectedType == Schema.DisplayType.REFERENCE
                    || selectedType == Schema.DisplayType.STRING
                    || selectedType == Schema.DisplayType.TEXTAREA
                    || selectedType == Schema.DisplayType.URL
                    || selectedType == Schema.DisplayType.PICKLIST
                    || selectedType == Schema.DisplayType.MULTIPICKLIST
                    || selectedType == Schema.DisplayType.ID) {

                    if (cur.selectedFieldValue == null || cur.selectedFieldValue == '') {
                        fieldValue = (cur.selectedOperator == 'not equal to' || cur.selectedOperator == 'equals') ? 'null' : '\'\'';
                    } else if (cur.selectedFieldValue.contains(',')) {
                        fieldValue = '(';
                        for (String curVal : cur.selectedFieldValue.split(',')) {
                            fieldValue += '\'' + curVal.trim() + '\'' + ',';
                        }
                        fieldValue = fieldValue.substring(0, fieldValue.length()-1) + ')';
                        useMultiIn = true;
                    } else {
                        fieldValue = '\'' + String.escapeSingleQuotes(cur.selectedFieldValue) + '\'';
                    }
                } else if (selectedType == Schema.DisplayType.CURRENCY
                           || selectedType == Schema.DisplayType.DOUBLE
                           || selectedType == Schema.DisplayType.INTEGER) {
                    if (cur.selectedFieldValue == null || cur.selectedFieldValue == '') {
                        if (cur.selectedOperator == 'not equal to' || cur.selectedOperator == 'equals') {
                            fieldValue = 'null';
                        } else {
                            fieldValue = '0';
                            cur.selectedFieldValue = '0';
                        }
                    } else {
                        fieldValue = cur.selectedFieldValue;
                    }

                } else if (selectedType == Schema.DisplayType.BOOLEAN) {
                    if (cur.selectedFieldValue == null || cur.selectedFieldValue == '' || (!cur.selectedFieldValue.equalsIgnoreCase('true') && !cur.selectedFieldValue.equalsIgnoreCase('false'))) {
                        fieldValue = 'true';
                        cur.selectedFieldValue = 'true';
                    } else {
                        fieldValue = cur.selectedFieldValue;
                    }
                } else if (selectedType == Schema.DisplayType.DATE) {
                    fieldValue = cur.selectedFieldValue;
                } else if (selectedType == Schema.DisplayType.DATETIME) {
                    fieldValue = cur.selectedFieldValue;
                    fieldName = 'DAY_ONLY(' + cur.selectedFieldName + ')';
                } else {
                    System.debug('**** couldnt find type ****');
                    continue;
                }

                if (cur.selectedOperator == 'equals') {
                    if (useMultiIn) {
                        whereClause += fieldName + ' in ' + fieldValue + ' AND ';   
                    } else {
                        whereClause += fieldName + ' = ' + fieldValue + ' AND ';
                    }
                } else if (cur.selectedOperator == 'not equal to') {
                    whereClause += fieldName + ' != ' + fieldValue + ' AND ';
                } else if (cur.selectedOperator == 'less than') {
                    whereClause += fieldName + ' < ' + fieldValue + ' AND ';
                } else if (cur.selectedOperator == 'greater than') {
                    whereClause += fieldName + ' > ' + fieldValue + ' AND ';
                } else if (cur.selectedOperator == 'less or equal') {
                    whereClause += fieldName + ' <= ' + fieldValue + ' AND ';
                } else if (cur.selectedOperator == 'greater or equal') {
                    whereClause += fieldName + ' >= ' + fieldValue + ' AND ';
                } else if (cur.selectedOperator == 'contains') {
                    whereClause += fieldName + ' LIKE \'%' + String.escapeSingleQuotes(cur.selectedFieldValue) + '%\' AND ';
                } else if (cur.selectedOperator == 'does not contain') {
                    whereClause += '(NOT ' + fieldName + ' LIKE \'%' + String.escapeSingleQuotes(cur.selectedFieldValue) + '%\') AND ';
                } else if (cur.selectedOperator == 'starts with') {
                    whereClause += fieldName + ' LIKE \'' + String.escapeSingleQuotes(cur.selectedFieldValue) + '%\' AND ';
                }
            }
            
        }
        if (whereClause.length() > 0) {
            whereClause = whereClause.substring(0, whereClause.length() -4);
        }
        system.debug(' ### whereClause = ' + whereClause);
        /*if (whereClause != '') {
            soql += ' and ' + whereClause;
        }*/
        
        return whereClause;
    }

    public Integer queryLimit {get; set;}
    {
        queryLimit = system.Test.isRunningTest() ? 10 : Integer.valueOf(system.label.ManageLinesRecordsLimit);
    }

    public virtual List<LineItemInfo> initProductLines(String pbName, String qk, Boolean extMatch) {
        //Integer queryLimit = 1000;

        initUnitPriceMap();

        String key = formatQueryKey(qk);
        set<Id> productIds = unitPriceMap.keyset();        
        map<String, Integer> mapProductQty = new map<String, Integer>();
        String soql = 'select Id, Name, kugo2p__Active__c, kugo2p__ReferenceProduct__c, kugo2p__ReferenceProduct__r.SalesInstruction__c, kugo2p__ReferenceProduct__r.ProductCode, kugo2p__StandardPrice__c, ' + 
        				'kugo2p__KitBundle__c, kugo2p__KitBundlePricing__c, kugo2p__Service__c, kugo2p__NonStock__c, kugo2p__UnitofTerm__c, kugo2p__DefaultServiceTerm__c, ' +
        				// Five Star changes
        				'LockPrice__c, RecipientLimit__c, CreateOrderFulfillment__c, NumberofOrderFulfillments__c, ' + 
				      	'(Select Id, Name, kugo2p__Quantity__c, kugo2p__Required__c, kugo2p__AllowQuantityChange__c, kugo2p__ReferenceKitBundle__c, kugo2p__ReferenceMemberProductService__c, kugo2p__ReferenceMemberProductService__r.Name, ' + 
				      	'kugo2p__ReferenceMemberProductService__r.kugo2p__Active__c, kugo2p__ReferenceMemberProductService__r.kugo2p__UnitofTerm__c, ' + 
				      	'kugo2p__ReferenceMemberProductService__r.kugo2p__DefaultServiceTerm__c, kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__c, ' +
				      	'kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__r.SalesInstruction__c, kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__r.ProductCode, ' + 
				      	'kugo2p__ReferenceMemberProductService__r.kugo2p__StandardPrice__c, kugo2p__ReferenceMemberProductService__r.kugo2p__KitBundle__c, ' + 
				      	'kugo2p__ReferenceMemberProductService__r.kugo2p__KitBundlePricing__c, kugo2p__ReferenceMemberProductService__r.kugo2p__Service__c, kugo2p__ReferenceMemberProductService__r.kugo2p__NonStock__c ' +
				      	// Five Star changes
				      	', kugo2p__ReferenceMemberProductService__r.LockPrice__c, kugo2p__ReferenceMemberProductService__r.RecipientLimit__c, kugo2p__ReferenceMemberProductService__r.CreateOrderFulfillment__c, kugo2p__ReferenceMemberProductService__r.NumberofOrderFulfillments__c ' +
        				'from kugo2p__KitBundles__r  order by Name) ' +
        			  'from kugo2p__AdditionalProductDetail__c where kugo2p__Active__c = true and kugo2p__ReferenceProduct__c in : productIds ';
        //if(prdFamily != 'all') soql += ' and kugo2p__ProductFamily__c = :prdFamily ';

        // START FILTERS
        String whereClause = buildFilterWhereClause(); 
        if (String.isNotBlank(whereClause)) {
            soql += ' and ' + whereClause;
        }

        if (String.isBlank(whereClause) || !whereClause.containsIgnoreCase('kugo2p__Hide__c')) {
        	soql += ' and kugo2p__Hide__c = false ';
        }
        // END FILTERS

        if (extMatch == null || extMatch == false || key == null || key == '') {
        	system.debug(' ### key ' + key);
            soql += ' and (Name like :key or kugo2p__ReferenceProduct__r.ProductCode like :key or kugo2p__ReferenceProduct__r.Description like :key) ';
        } else {
            if (key != null && key != '') {
                key = key.replaceAll('%', '');

                list<String> lstProductsQty = key.split(',');

                system.debug(' ### key ' + key + ' lstProductsQty ' + lstProductsQty);
                for (String p : lstProductsQty) {
                    String[] pq = p.split('\\+');
                    Integer qty;
                    try {
                        qty = (pq.size() > 1 ? Integer.valueOf(pq[1]) : 1);
                    } catch (Exception ex) {
                        qty = 1;
                    }
                    mapProductQty.put(pq[0].trim(), qty);
                }

                system.debug(' ### mapProductQty ' + mapProductQty.size() + ' => ' + mapProductQty);
                set<String> setProducts = mapProductQty.keySet();
                soql += ' and kugo2p__ReferenceProduct__r.ProductCode in : setProducts ';
            }
        }
        soql += ' ORDER BY Name ' + sortDirection + ' limit ' + queryLimit;

        system.debug(' ### soql ' + soql);
        List<kugo2p__AdditionalProductDetail__c> productItems = Database.Query(soql);

        List<LineItemInfo> lineItems = new List<LineItemInfo>();
        Integer sortValue, index = 0;
        LineItemInfo lineItem;
        set<String> productsFound = new set<String>();

        for(kugo2p__AdditionalProductDetail__c productItem : productItems) {
            lineItem = addLineItem(index, mapProductQty, unitPriceMap, productItem);
            
            if (productItem.kugo2p__KitBundle__c && productItem.kugo2p__KitBundles__r != null) {
                lineItem.productKitMembers = new map<Id, LineItemInfo>();
                for (kugo2p__KitBundleMember__c kbm : productItem.kugo2p__KitBundles__r) {

                    LineItemInfo li = addLineItem(lineItem.productKitMembers.size(), mapProductQty, unitPriceMap, kbm.kugo2p__ReferenceMemberProductService__r);
                    li.QuantityValue = (kbm.kugo2p__Quantity__c==null ? 1 : kbm.kugo2p__Quantity__c) * (li.QuantityValue==null ? 1 : li.QuantityValue);
                    li.isKitBundleMemberRequired = kbm.kugo2p__Required__c;
                    li.allowQuantityChange = kbm.kugo2p__AllowQuantityChange__c;
                    li.kitBundleHeaderName = productItem.Name;

                    lineItem.productKitMembers.put(kbm.kugo2p__ReferenceMemberProductService__c, li);
                }
            }

            index++;
            lineItems.add(lineItem);
            productsFound.add(productItem.kugo2p__ReferenceProduct__r.ProductCode);
        }

        if (ExactMatch && productsFound.size() < mapProductQty.size()) {
            String productsNotFound = '';
            for (String p : mapProductQty.keySet()) {
                if (!productsFound.contains(p)) {
                    if (productsNotFound != '') productsNotFound += ', ';
                    productsNotFound += p;
                }
            }
            system.debug(' ### productsNotFound ' + productsNotFound);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find: ' + productsNotFound));
        }

        if (!ExactMatch && (productItems == null || productItems.isEmpty())) {
            if (String.isBlank(key.replaceAll('%', ''))) {
            	if (isPriceBookValid && isPriceBookActive) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'The Price Book <b>' + PricebookName + '</b> does not have any Active Products.'));
            } else {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find: ' + key.replaceAll('%', '')));
            }
        }
        
        if (mapProductTiers == null) mapProductTiers = getPricebookProductTiers(pricebookName, productIds, currencyCode); //getCurrencyCode(salesOrder)

        initRecommendedProducts(lineItems, productIds);

        initFavorites(productIds);

        //lineItems = sortLines(lineItems);
        return lineItems;
    }
    
    public LineItemInfo addLineItem(Integer index, map<String, Integer> mapProductQty, Map<Id, Decimal> unitPriceMap, kugo2p__AdditionalProductDetail__c productItem) {
        LineItemInfo lineItem = new LineItemInfo(index, null, productItem.Id, productItem.kugo2p__ReferenceProduct__c, productItem.Name, null, productItem.kugo2p__KitBundle__c, productItem.kugo2p__ReferenceProduct__r.ProductCode, productItem.kugo2p__NonStock__c);
        //if (unitPriceMap == null || unitPriceMap.isEmpty()) initUnitPriceMap();
        if (unitPriceMap != null) lineItem.ListPrice = convertToFormattedString(unitPriceMap.get(productItem.kugo2p__ReferenceProduct__c),2);
        lineItem.UnitofTerm = productItem.kugo2p__UnitofTerm__c;
        lineItem.ServiceTermValue = productItem.kugo2p__DefaultServiceTerm__c==null ? 0 : productItem.kugo2p__DefaultServiceTerm__c.intValue();
        lineItem.SalesPrice = lineItem.ListPrice;
        if (mapProductQty != null) lineItem.QuantityValue = ExactMatch ? mapProductQty.get(productItem.kugo2p__ReferenceProduct__r.ProductCode) : null;
        lineItem.DiscountValue = 0;
        lineItem.LineDescription = '';
        lineItem.HeaderDiscount = headerDiscountValue;
        lineItem.IsService = productItem.kugo2p__Service__c;
        lineItem.kitBundlePricing = productItem.kugo2p__KitBundlePricing__c;
        lineItem.IsActive = productItem.kugo2p__Active__c;
        lineItem.HasActivePBE = unitPriceMap != null && unitPriceMap.containsKey(productItem.kugo2p__ReferenceProduct__c);
        lineItem.salesInstruction = productItem.kugo2p__ReferenceProduct__r.SalesInstruction__c;

        // Five Star changes
        lineItem.LockPrice = productItem.LockPrice__c;
        lineItem.RecipientLimit = productItem.RecipientLimit__c;
        lineItem.CreateOrderFulfillment = productItem.CreateOrderFulfillment__c;
        lineItem.NumOrderFulfillments = productItem.NumberofOrderFulfillments__c;

        return lineItem;
    }

    //Adds 1 line item according to the line index.
  public void addLine() {
    Integer index = convertIndex('uindex');
    String lineType = getPageParameter('lineType');
    system.debug(' ### lineType in addLine ' + lineType + ' at index ' + index);

    if(index >= 0) {
      //addnewline(index, (lineType == 'All' ? ProductLines : (lineType == 'Asset' ? null : (lineType == 'Subscription' ? null : recommendedProducts))));
      //addnewline(index, (lineType == 'All' ? ProductLines : recommendedProducts));
      addnewline(index, (lineType == 'All' ? ProductLines : (lineType == 'Favorites' ? favoriteProducts : recommendedProducts)));
    }
    //SelectedLines = sortLines(SelectedLines);
    calculateTotal();
  }

  public void cloneLine() {
    Integer index = convertIndex('cindex');
    if( index >= 0 && SelectedLines != null && SelectedLines.size() > index ) {
      LineItemInfo cloningLine = SelectedLines[index];
      LineItemInfo newLine = cloneLine(cloningLine);
      if (cloningLine.IsKit) {
        list<Integer> lstMemberIndex = new list<Integer>();
        for (LineItemInfo lif : SelectedLines) {
          if (lif.KitBundleHeaderIndex != null && lif.KitBundleHeaderIndex == cloningLine.index) {
            lstMemberIndex.add(lif.Index);
          }
        }
        for(Integer i = 0; i <= lstMemberIndex.size()-1; i++) {
          LineItemInfo newKitMember = cloneLine(SelectedLines[lstMemberIndex[i]]);
          newKitMember.KitBundleHeaderIndex = newLine.Index;
          system.debug(' ### newKitMember.useTieredPricing ' + newKitMember.useTieredPricing);
        }
      }
    }
    calculateTotal();
  }
    
    //Adds the line items that have input values.
    public void addAll()
    {
        //list<LineItemInfo> lines = (getPageParameter('lineType') == 'All' ? ProductLines : (getPageParameter('lineType') == 'Asset' ? null : (getPageParameter('lineType') == 'Subscription' ? null : recommendedProducts)));
        String lineType = getPageParameter('lineType');
        system.debug(' ### lineType in addLine ' + lineType);
        list<LineItemInfo> lines = (lineType == 'All' ? ProductLines : (lineType == 'Favorites' ? favoriteProducts : recommendedProducts));

        for(lineiteminfo lineitem : lines)
        {
            //system.debug(' ### salespricevalue ' + lineitem.salespricevalue + ' quantityvalue ' + lineitem.quantityvalue + ' quantityerrorvalue ' + lineItem.quantityerrorvalue + ' quantityerror ' + lineItem.quantityerror);  
            if(lineitem.salespricevalue != null && lineitem.quantityvalue != null) {
            //if(lineitem.salespricevalue != null | lineitem.quantityvalue != null)
                addnewline(lineitem.index, lines);
            }
        }

        //SelectedLines = sortLines(SelectedLines);
        calculateTotal();
    }
    
    //Deletes 1 line item according to the line index.
    public void delLine()
    {
        Integer index = convertIndex('sindex');
        Integer liIndex;
        list<Integer> lstIndex = new list<Integer>();
        if(index >= 0)
        {
            if(deleteLineIds == null)
            {
                deleteLineIds = new list<String>();
            }
            //If the line item is existed in the database, adds it to the list for updating.
            if(SelectedLines[index].LineItemId != null) {
                deleteLineIds.add(SelectedLines[index].LineItemId);
            }
            
            if (SelectedLines[index].IsKit) {
                //liId = SelectedLines[index].LineItemId;
                liIndex = SelectedLines[index].index;
            }

            lstIndex.add(index);

            // delete Kit Members
            //system.debug(' ### liId ' + liId + ' liIndex ' + liIndex);
            system.debug(' ### liIndex ' + liIndex);
            for (LineItemInfo lif : SelectedLines) {
                if (lif.KitBundleHeaderIndex != null && lif.KitBundleHeaderIndex == liIndex) {
                    lstIndex.add(lif.Index);
                }
            }

            // remove the deleted items from the list
            //for (Integer idx : setIndex)
            system.debug(' ### lstIndex ' + lstIndex.size() + ' => ' + lstIndex);
            for(Integer i = lstIndex.size()-1; i >= 0; i--) {
                SelectedLines.remove(lstIndex[i]);
            }

            Integer kitHeaderIndex;
            for(Integer i = 0; i < SelectedLines.size(); i++) {
                SelectedLines[i].index = i;
                if (!SelectedLines[i].isKitBundleMember) {
                    kitHeaderIndex = i;
                } else {
                    SelectedLines[i].KitBundleHeaderIndex = kitHeaderIndex;
                }
            }
        }
        validateInactiveLines();
        calculateTotal();
        resetRecommendedProducts();
    }
    
    //Goes to the previous page.
    public void previousPage()
    {
        StartIndex = StartIndex - PageSize;
        //If it's the first page.
        if(StartIndex < 0)
        {
            StartIndex = 0;
        }
        else
        {
            CurrentPage--;
        }
    }
    
    //Goes to the next page.
    public void nextPage()
    {
        //If it's not the last page.
        if(CurrentPage < PageCounts)
        {
            StartIndex += PageSize;
            CurrentPage++;
        }
    }
    
    //Resets the page size according to the selecting value.
    public void resetPagesize()
    {
        CurrentPage = (CurrentPage > PageCounts) ? PageCounts : CurrentPage;
        StartIndex = CurrentPage==1 ? 0 : (PageSize * (CurrentPage - 1) + 1);
    }

    public PageReference ResetPaging() {
        StartIndex = 0;
        CurrentPage = 1;
        return null;
    }

    //Calculates the total Quantity and Amount if the value of line item is changed.
    public void calculateTotal() {
        decimal productsQuantity = 0;
        decimal servicesQuantity = 0;
        decimal productsAmount = 0;
        decimal servicesAmount = 0;

        for (LineItemInfo lineItem : SelectedLines) {

            if (lineItem.IsService) {
                servicesQuantity += (lineItem.QuantityValue == null) ? 0 : lineItem.QuantityValue;
                servicesAmount += lineItem.TotalAmountValue;
            } else {
                productsQuantity += (lineItem.QuantityValue == null) ? 0 : lineItem.QuantityValue;
                productsAmount += lineItem.TotalAmountValue;
            }
        }
        //system.debug(' ### productsAmount ' + productsAmount + ' servicesAmount ' + servicesAmount);
        //system.debug(' ### productsQuantity ' + productsQuantity);

        TotalProductsQty = convertToFormattedString(productsQuantity, 2);
        TotalProductsAmount = convertToFormattedString(productsAmount, 2);

        TotalServicesQty = convertToFormattedString(servicesQuantity, 2);
        TotalServicesAmount = convertToFormattedString(servicesAmount, 2);
    }

    public virtual void updateheaderDiscount() {

        for(LineItemInfo lineItem : SelectedLines) {
            lineItem.HeaderDiscount = headerDiscountValue==null ? 0 : headerDiscountValue;
            // Five Star changes
            if (lineItem.LockPrice) lineItem.DiscountValue = -1 * lineItem.HeaderDiscount;
        }

        calculateTotal();
    }

    public void updateheaderStartDate() {
        system.debug(' ### dummyStartDate.ServiceDate ' + dummyStartDate.ServiceDate);
        if (dummyStartDate.ServiceDate != null) {
            for(LineItemInfo lineItem : SelectedLines) {
                lineItem.startDate = dummyStartDate.ServiceDate.format();
            }

            calculateServiceEndDate();
        }
    }    

    public void calculateServiceEndDate() {
        
        Integer index = convertIndex('sindex');
        system.debug(' ### index in calculateServiceEndDate ' + index);

        for(LineItemInfo lif : SelectedLines) {
            if (lif.Index == index || index == -1) {
                lif.calculateServiceEndDate();              

                if (index != -1) break;
            }
        }
        
        updateKitMemberDtls();

        calculateTotal();
    }
    
    public void updateKitMemberDtls() {
        Integer index = convertIndex('sindex');
        system.debug(' ### index in updateKitMemberQuantity ' + index);
        
        LineItemInfo kitHeaderLineItem;
        for(LineItemInfo lineItem : SelectedLines) {
            if (lineItem.Index == index) {
                kitHeaderLineItem = lineItem;
            } else if (lineItem.KitBundleHeaderIndex == index) {
            // else if (lineItem.KitBundleHeaderIndex == index && (lineItem.LineItemId == null || lineItem.LineItemId == ''))
                //if (kitHeaderLineItem.QuantityValue != null && kitHeaderLineItem.productKitMembers != null && kitHeaderLineItem.productKitMembers.get(lineItem.ProductId) != null)
                if (kitHeaderLineItem.QuantityValue != null && kitHeaderLineItem.productKitMembers != null && kitHeaderLineItem.productKitMembers.get(lineItem.APDId) != null) {
                    lineItem.Discount = kitHeaderLineItem.Discount;
                    lineItem.QuantityValue = kitHeaderLineItem.QuantityValue * kitHeaderLineItem.productKitMembers.get(lineItem.APDId).QuantityValue;
                    lineItem.startDate = kitHeaderLineItem.startDate;
                    lineItem.endDate = kitHeaderLineItem.endDate;
                    lineItem.ServiceTerm = kitHeaderLineItem.ServiceTerm;
                } else {
                    lineItem.QuantityValue = null;
                }
            }
        }

        calculateTotal();   
    }
    
    public void updateSalesPriceAndKitMemberDtls() {
        Integer index = convertIndex('sindex');
        boolean resetSalesPrice = getPageParameter('resetSalesPrice') == '1';
        system.debug(' ### index in updateKitMemberQuantity ' + index);
        
        LineItemInfo kitHeaderLineItem;
        for(LineItemInfo lineItem : SelectedLines) {
            if (lineItem.Index == index) {
                kitHeaderLineItem = lineItem;
                if (lineItem.useTieredPricing) {
                    lineItem.SalesPriceValue = getProductTieredPrice(mapProductTiers, lineItem.productId, lineItem.QuantityValue);
                } else if (resetSalesPrice) {
                    lineItem.SalesPriceValue = getProductTieredPrice(mapProductTiers, lineItem.productId, 1);
                }
            } else if (lineItem.KitBundleHeaderIndex == index) {
            //} else if (lineItem.KitBundleHeaderIndex == index && (lineItem.LineItemId == null || lineItem.LineItemId == '')) {
                if (kitHeaderLineItem.QuantityValue != null && kitHeaderLineItem.productKitMembers != null && kitHeaderLineItem.productKitMembers.get(lineItem.APDId) != null) {
                    lineItem.Discount = kitHeaderLineItem.Discount;
                    lineItem.QuantityValue = kitHeaderLineItem.QuantityValue * kitHeaderLineItem.productKitMembers.get(lineItem.APDId).QuantityValue;
                } else {
                    lineItem.QuantityValue = null;
                }
            }
        }

        calculateTotal();
    }

    public void updateKitMemberStartDate() {
        Integer index = convertIndex('sindex');
        system.debug(' ### index in updateKitMemberStartDate ' + index);

        LineItemInfo kitHeaderLineItem;
        for(LineItemInfo lineItem : SelectedLines) {
            if (lineItem.Index == index) {
                kitHeaderLineItem = lineItem;
            } else if (lineItem.KitBundleHeaderIndex == index) {
            	// update Kit Member start date only for new members (i.e., before saving it to the database)
            	if (lineItem.isNewKitBundleMember) lineItem.startDate = kitHeaderLineItem.startDate;
            }
        }

        calculateTotal();   
    }    

  public void addnewline(integer index, list<LineItemInfo> sourceLines){
    if ( sourceLines != null && sourceLines.size() > index ){
      LineItemInfo addingLine = sourceLines[index];
      // use header Start Date, if it is filled
      if (dummyStartDate.ServiceDate != null) addingLine.StartDateValue = dummyStartDate.ServiceDate;
      system.debug(' ### index in addnewLine ' + index + ' addingline ' + addingline);
    
      //if (addingLine.SalesPriceValue != null)
      //{
      if(addingLine.QuantityValue==null) addingLine.QuantityValue = 1;
      if(!(addingLine.SalesPriceError || addingLine.QuantityError))           
        {
          Boolean createNew = true;
    
                    for(LineItemInfo lineItem : SelectedLines)
                    {
                        /*
                         * If the product and the salesprice already exists in the selected line items,
                         * adds the quantity to the existed one.
                         */
    
                        //system.debug(' ### APD ' + lineItem.APDId + ' ' + (lineItem.APDId == addingLine.APDId) + ' ' + addingLine.APDId);
                        //system.debug(' ### ProductId ' + (lineItem.ProductId == addingLine.ProductId));
                        //system.debug(' ### SalesPriceValue ' + (lineItem.SalesPriceValue == addingLine.SalesPriceValue));
                        if(lineItem.APDId == addingLine.APDId && lineItem.ProductId == addingLine.ProductId && lineItem.SalesPriceValue == addingLine.SalesPriceValue && lineItem.StartDate == addingLine.StartDate && !lineItem.isKitBundleMember)
                        {
                            try {
    
                                for (String qty : addingLine.quantityErrorValue.split(',')) {
                                    if (qty=='') qty = '1';
                                    lineItem.QuantityValue += decimal.valueOf(qty);
    
                                    if (mapProductTiers.containsKey(lineItem.ProductId) && lineItem.useTieredPricing) {
                                        lineItem.SalesPriceValue = getProductTieredPrice(mapProductTiers, lineItem.productId, lineItem.QuantityValue);
                                    }
                                }
    
                                // update kit bundle member quantity
                                if (lineType != 'Opportunity' && lineItem.isKit) {
                                    ApexPages.currentPage().getParameters().put('sindex', (lineItem.Index==null ? '' : String.valueOf(lineItem.Index)));
                                    updateSalesPriceAndKitMemberDtls();
                                }
    
                            } catch(Exception ex) {
                                system.debug(' ### exception in addNewLine ' + ex);
                            }
                            createNew = false;
                            break;
                        }
                    }
    
                    //If the product and the salesprice does not exist, clone the adding line item and adds to the list.
                    if(createNew)
                    {
                        system.debug(' ### in createNew addingLine.quantityValue ' + addingLine.quantityValue + ' quantityErrorValue ' + addingLine.quantityErrorValue);
                        if (addingLine.quantityErrorValue == null) addingLine.quantityErrorValue = '1';
                        for (String qty : addingLine.quantityErrorValue.split(',')) {
                            if (qty=='') qty = '1';
                            if (addingLine.QuantityValue > 0) qty = String.valueOf(addingLine.QuantityValue);
                            LineItemInfo newLineItem = cloneLine(addingLine);
                            //system.debug(' ### newLineItem salesPrice ' + newLineItem.salesPriceValue + ' listprice ' + newLineItem.listPrice);
    
                            if (mapProductId_To_PBEId.containsKey(addingline.ProductId)) newlineitem.PriceBookEntryId = mapProductId_To_PBEId.get(addingline.ProductId);
    
                            newLineItem.Quantity = qty;
                            if (newLineItem.isService) {
                                newLineItem.calculateServiceEndDate();
                                if (newLineItem.EndDate == null || newLineItem.EndDate == '') newLineItem.EndDate = system.today().format();
                            }
    
                            system.debug(' ### kitBundlePricing ' + newLineItem.kitBundlePricing);
                            initTiers(newLineItem, true);
                            if (lineType != 'Opportunity' && addingLine.isKit && newLineItem.kitBundlePricing == 'Member Prices Only') {
                                newLineItem.SalesPrice = '0';
                            }
    
                            addRecommendedProducts(addingline.productId);
                            // Five Star changes
                            if (contactBuying != null && String.isNotBlank(addingLine.RecipientLimit)) {
                                newLineItem.mapSelectedRecipients.put(contactBuying.Id, contactBuying.Name);
                                mapLineIndex_To_PrimaryRecipientId.put(newLineItem.index, contactBuying.Id);
                            }
        
                            if (lineType != 'Opportunity' && addingLine.isKit && addingLine.productKitMembers != null && !addingLine.productKitMembers.isEmpty()) {
                                boolean resetServiceIndex = false;
                                Integer kitHeaderIndex = SelectedLines[SelectedLines.size()-1].index;
                                system.debug(' ### kitHeaderIndex ' + kitHeaderIndex);
                                for (LineItemInfo kbm : addingLine.productKitMembers.values()){
                                    cloneLine(kbm);
                                    SelectedLines[SelectedLines.size()-1].KitBundleHeaderIndex = kitHeaderIndex;
                                    SelectedLines[SelectedLines.size()-1].QuantityValue = SelectedLines[SelectedLines.size()-1].QuantityValue * decimal.valueOf(qty);
                                    // use header Start Date, if it is filled
                                    if (dummyStartDate.ServiceDate != null) selectedlines[selectedlines.size()-1].StartDateValue = dummyStartDate.ServiceDate;
                                    if (!addingLine.isService && kbm.isService) {
                                        //system.debug(' ### entering kit members sort ' + SelectedLines[SelectedLines.size()-1].SortValue + ' kitHeaderIndex ' + kitHeaderIndex);
                                        system.debug(' ### entering kit member index ' + SelectedLines[SelectedLines.size()-1].index + ' KitBundleHeaderIndex ' + SelectedLines[SelectedLines.size()-1].KitBundleHeaderIndex + ' sortValue ' + SelectedLines[SelectedLines.size()-1].sortValue);
                                        SelectedLines[SelectedLines.size()-1].isKitHeaderAProduct = true;
                                        //SelectedLines[SelectedLines.size()-1].SortValue = 0;
                                        resetServiceIndex = true;
                                    }
    
                                    initTiers(SelectedLines[SelectedLines.size()-1], true);
                                    if (addingLine.kitBundlePricing == 'Kit/Bundle Price Only') SelectedLines[SelectedLines.size()-1].SalesPrice = '0';
    
                                    if (SelectedLines[SelectedLines.size()-1].isService) {
                                        SelectedLines[SelectedLines.size()-1].calculateServiceEndDate();
                                        if (SelectedLines[SelectedLines.size()-1].EndDate == null || SelectedLines[SelectedLines.size()-1].EndDate == '') SelectedLines[SelectedLines.size()-1].EndDate = system.today().format();
                                    }
    
                                    addRecommendedProducts(kbm.productId);
                                    // Five Star changes
                                    if (contactBuying != null && String.isNotBlank(kbm.RecipientLimit)) {
                                        SelectedLines[SelectedLines.size()-1].mapSelectedRecipients.put(contactBuying.Id, contactBuying.Name);
                                        mapLineIndex_To_PrimaryRecipientId.put(SelectedLines[SelectedLines.size()-1].index, contactBuying.Id);
                                    }
                                }
    
                                // reset service line index
                                if (resetServiceIndex) {
                                    Integer kitMemberCounter = getSelectedProducts().size();
                                    system.debug(' ### kitMemberCounter ' + kitMemberCounter);
    
                                    list<LineItemInfo> tempSelectedLines = new list<LineItemInfo>();
                                    for (LineItemInfo lif : getSelectedProducts()) {
                                        tempSelectedLines.add(lif);
                                    }
    
                                    for (LineItemInfo lif : getSelectedServices()) {
                                        if (lif.isKitBundleMember && lif.isKitHeaderAProduct) {
                                            lif.Index = kitMemberCounter;
                                            lif.SortValue = kitMemberCounter - 1;
                                            system.debug(' ### setting kit member index to ' + kitMemberCounter);
                                            kitMemberCounter++;
    
                                            tempSelectedLines.add(lif);
                                        }
                                    }
    
                                    for (LineItemInfo lif : getSelectedServices()) {
                                        if (!lif.isKitBundleMember || !lif.isKitHeaderAProduct) {
                                            lif.Index = kitMemberCounter;
                                            lif.SortValue = kitMemberCounter - 1;
                                            system.debug(' ### setting non kit member index to ' + kitMemberCounter);
                                            kitMemberCounter++;
                                            
                                            tempSelectedLines.add(lif);
                                        }
                                    }
    
                                    selectedLines = tempSelectedLines;
                                }
                            }
                        }
                    }
                    //Resets the adding line item's salesprice and quantity to default one.
                    addingLine.SalesPrice = addingLine.ListPrice;
                    addingLine.Quantity = '';
                    addingLine.StartDate = Date.today().format(); 
                }
            //}
            
            //Requires the SalesPrice and Quantity's values.
            else if(addingLine.SalesPrice == '' || addingLine.Quantity == '')
            {
                ApexPages.Message reqMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please input the Sales Price and Quantity of the product you need to add.');
                ApexPages.addMessage(reqMsg);
            }
        }
    }

    public virtual String getPageTitle() {
        return null;
    }

    public boolean showRecommendedTab {
        get {
            if (showRecommendedTab == null) {
            	set<Id> productIds = unitPriceMap.keyset();
                showRecommendedTab = ([select count() from RecommendedProduct__c where ReferenceProduct__c in : productIds and Product__c in : productIds and IsActive__c = true] > 0);
            }
            return showRecommendedTab;
        }
        private set;
    }

    private set<Id> setRecommendedProductIds = new set<Id>{};
    public void addRecommendedProducts(Id productId) {
        productIds_Rec.add(productId);
        //system.debug(' ### productId exists in RecommendedProducts Map ' + mapproductId_to_RecommendedProducts.containsKey(productId));
        if (mapproductId_to_RecommendedProducts != null && mapproductId_to_RecommendedProducts.containsKey(productId)) {
            for (RecommendedProduct__c rp : mapproductId_to_RecommendedProducts.get(productId)) {
                //system.debug(' ### Recommended Product ' + rp.Product__c + ' price ' + unitpricemap.get(rp.Product__c));
                if (!setRecommendedProductIds.contains(rp.Product__c)) {
                	//system.debug(' ### entering add Recommended Products.');

                	setRecommendedProductIds.add(rp.Product__c);

					kugo2p__AdditionalProductDetail__c apd = getproductapd(new set<Id> {rp.Product__c}).get(rp.Product__c);
                    //LineItemInfo newLineItem = addlineitem(recommendedProducts.size(), null, unitpricemap, getproductapd(new set<Id> {rp.Product__c}).get(rp.Product__c));
                    LineItemInfo newLineItem = addlineitem(recommendedProducts.size(), null, unitpricemap, apd);
                    newLineItem.QuantityValue = rp.quantity__c == null ? 1 : rp.quantity__c;

/*
                    kugo2p__AdditionalProductDetail__c productItem = getProductAPD(new set<Id> {rp.Product__c}).get(rp.Product__c);
                    system.debug(' ### productItem.kugo2p__KitBundles__r ' + productItem.kugo2p__KitBundles__r);
                    if (productItem.kugo2p__KitBundle__c && productItem.kugo2p__KitBundles__r != null) {
                        newLineItem.productKitMembers = new map<Id, LineItemInfo>();
                        for (kugo2p__KitBundleMember__c kbm : productItem.kugo2p__KitBundles__r) {
                            LineItemInfo li = addLineItem(newLineItem.productKitMembers.size(), null, unitPriceMap, kbm.kugo2p__ReferenceMemberProductService__r);
                            li.QuantityValue = (kbm.kugo2p__Quantity__c==null ? 1 : kbm.kugo2p__Quantity__c) * (li.QuantityValue==null ? 1 : li.QuantityValue);
                            li.kitBundleHeaderName = productItem.Name;

                            newLineItem.productKitMembers.put(kbm.kugo2p__ReferenceMemberProductService__c, li);
                        }
                    }
*/

					addKitBundleMembers(newLineItem, apd);
                    recommendedProducts.add(newLineItem);
                }
            }
        }

        resetFavorites();
    }

    private void addKitBundleMembers(LineItemInfo newLineItem, kugo2p__AdditionalProductDetail__c productItem) {
        //kugo2p__AdditionalProductDetail__c productItem = getProductAPD(new set<Id> {apdId}).get(apdId);
        //system.debug(' ### productItem.kugo2p__KitBundles__r ' + productItem.kugo2p__KitBundles__r);

        if (lineType != 'Opportunity' && productItem.kugo2p__KitBundle__c && productItem.kugo2p__KitBundles__r != null) {
            newLineItem.productKitMembers = new map<Id, LineItemInfo>();

            for (kugo2p__KitBundleMember__c kbm : productItem.kugo2p__KitBundles__r) {
                LineItemInfo li = addLineItem(newLineItem.productKitMembers.size(), null, unitPriceMap, kbm.kugo2p__ReferenceMemberProductService__r);
                li.QuantityValue = (kbm.kugo2p__Quantity__c==null ? 1 : kbm.kugo2p__Quantity__c) * (li.QuantityValue==null ? 1 : li.QuantityValue);
                li.isKitBundleMemberRequired = kbm.kugo2p__Required__c;
                li.allowQuantityChange = kbm.kugo2p__AllowQuantityChange__c;
                li.kitBundleHeaderName = productItem.Name;

                newLineItem.productKitMembers.put(kbm.kugo2p__ReferenceMemberProductService__c, li);

                addRecommendedProducts(kbm.kugo2p__ReferenceMemberProductService__c);
            }
        }
    }

    public void resetRecommendedProducts() {
        setRecommendedProductIds = new set<Id>{};
        recommendedProducts = new list<LineItemInfo>{};

        for (LineItemInfo lif : SelectedLines) {
            if (String.isNotBlank(lif.ProductId)) setRecommendedProductIds.add(lif.ProductId);
        }

        for (LineItemInfo lif : SelectedLines) {
            addRecommendedProducts(lif.ProductId);
        }
    }

    public void initRecommendedProducts(list<lineiteminfo> lineitems, set<Id> productIds) {
        getRecommendedProducts(productIds);

        if (lineitems != null && !lineitems.isEmpty()) {
            for (lineiteminfo lineitem : lineitems) {
                if (mapproductId_to_RecommendedProducts.containskey((Id) lineitem.productid)) {
                    lineitem.recommendedProducts = mapproductId_to_RecommendedProducts.get((Id) lineitem.productid);
                    //system.debug(' ### setting recommended products for ' + lineitem.productid + ' - ' + lineitem.productName);
                }
            }
        }
    }

    public set<Id> productIds_Rec = new set<Id>{};    
    public list<LineItemInfo> recommendedProducts {get; set;}
    {
        recommendedProducts = new list<LineItemInfo>{};
    }

    public map<Id, list<RecommendedProduct__c>> getRecommendedProducts(set<Id> productIds) {
        system.debug(' ### productIds in getRecommendedProducts ' + productIds);
        if (productIds != null && !productIds.isEmpty()) {

            //if (mapproductId_to_RecommendedProducts == null) mapproductId_to_RecommendedProducts = new map<Id, list<RecommendedProduct__c>>{};
            mapproductId_to_RecommendedProducts = new map<Id, list<RecommendedProduct__c>>{};

            for (RecommendedProduct__c rp : [select 	Id, ReferenceProduct__c, referenceproduct__r.name, product__c, product__r.name, productcode__c, productdescription__c, quantity__c
                                               from 	RecommendedProduct__c 
                                               where 	ReferenceProduct__c = :productIds 
                                               and 		Product__c != null 
                                               and 		Product__r.IsActive = true]) {

                if (unitPriceMap.containsKey(rp.Product__c)) {
                    if (!mapproductId_to_RecommendedProducts.containskey(rp.ReferenceProduct__c)) mapproductId_to_RecommendedProducts.put(rp.ReferenceProduct__c, new list<RecommendedProduct__c>{});
                    mapproductId_to_RecommendedProducts.get(rp.ReferenceProduct__c).add(rp);
                }    
            }

            system.debug(' ### mapproductId_to_RecommendedProducts in getRecommendedProducts ' + mapproductId_to_RecommendedProducts.size() + ' => ' + mapproductId_to_RecommendedProducts);
        }
        return mapproductId_to_RecommendedProducts;
    }

    public list<LineItemInfo> favoriteProducts {get; set;}
    {
        favoriteProducts = new list<LineItemInfo>{};
    }

    public Integer getTotalFavorites() {
    	return favoriteProducts==null ? 0 : favoriteProducts.size();
    }

	private set<Id> setFavoriteIds = new set<Id>{};
	@testVisible
    protected void initFavorites(set<Id> productIds) {

		list<UserProduct__c> favorites = getFavorites(productIds);

		for (UserProduct__c fav : favorites) {
			setFavoriteIds.add(fav.Product__c);

			kugo2p__AdditionalProductDetail__c apd = getproductapd(new set<Id> {fav.Product__c}).get(fav.Product__c);
            LineItemInfo newLineItem = addlineitem(favoriteProducts.size(), null, unitpricemap, apd);
            newLineItem.QuantityValue = 1;
            newLineItem.IsFavorite = true;

            addKitBundleMembers(newLineItem, apd);

            favoriteProducts.add(newLineItem);
		}
		system.debug(' ### setFavoriteIds ' + setFavoriteIds);

		resetFavorites();
    }

    protected void resetFavorites() {
    	if (ProductLines != null) {
	        for (lineiteminfo lineitem : ProductLines) {
	        	//system.debug(' ### favorite lineitem.productId ' + lineitem.productId);
	        	lineitem.IsFavorite = setFavoriteIds.contains((Id) lineitem.productId);
	        }
    	}

		if (SelectedLines != null) {
	        for (lineiteminfo lineitem : SelectedLines) {
	        	lineitem.IsFavorite = setFavoriteIds.contains((Id) lineitem.productId);
	        }
		}

		if (recommendedProducts != null) {
	        for (lineiteminfo lineitem : recommendedProducts) {
	        	lineitem.IsFavorite = setFavoriteIds.contains((Id) lineitem.productId);
	        }
		}

		if (favoriteProducts != null) {
	        for (lineiteminfo lineitem : favoriteProducts) {
	        	lineitem.IsFavorite = setFavoriteIds.contains((Id) lineitem.productId);
	        }
		}
    }

    public void addFavorite() {
    	Id pid = (Id) getPageParameter('uProductId');
    	Integer index = convertIndex('uindex');

    	UserProduct__c fav = new UserProduct__c(User__c=UserInfo.getUserId(), Product__c=pid, IsFavorite__c=true);
    	insert fav;

		kugo2p__AdditionalProductDetail__c apd = getproductapd(new set<Id> {pid}).get(pid);
        LineItemInfo newLineItem = addlineitem(favoriteProducts.size(), null, unitpricemap, apd);
        newLineItem.QuantityValue = 1;
        newLineItem.IsFavorite = true;

        addRecommendedProducts(pid);

        addKitBundleMembers(newLineItem, apd);

        favoriteProducts.add(newLineItem);

		setFavoriteIds.add(pid);
    	resetFavorites();
    }

    public void removeFavorite() {
    	Id pid = (Id) getPageParameter('uProductId');

    	delete [Select Id from UserProduct__c where User__c = :UserInfo.getUserId() and Product__c = :pid];

		Integer delIndex = -1;
        for (lineiteminfo lineitem : favoriteProducts) {
        	if ((Id) lineitem.productId == pid) {
        		delIndex = lineitem.Index;
        	}
        }
        favoriteProducts.remove(delIndex);

		Integer index = 0;
        for (lineiteminfo lineitem : favoriteProducts) {
        	lineitem.Index = index;
        	index++;
        }

		setFavoriteIds.remove(pid);
    	resetFavorites();
    }

	public list<UserProduct__c> getFavorites(set<Id> productIds) {

		list<UserProduct__c> favorites = new list<UserProduct__c>{};

        system.debug(' ### productIds in getFavorites ' + productIds);
        if (productIds != null && !productIds.isEmpty()) {
			favorites = [Select Product__c, User__c from UserProduct__c where User__c = :UserInfo.getUserId() and Product__c in :productIds and IsFavorite__c = true order by Product__r.Name];
        }

        return favorites;
	}

    public void initTiers(LineItemInfo lineItem, boolean resetSalesPrice) {
        if (mapProductTiers.containsKey(lineItem.ProductId)) {
            lineItem.tiers = mapProductTiers.get(lineItem.ProductId);
            decimal tieredPrice = getProductTieredPrice(mapProductTiers, lineItem.productId, lineItem.QuantityValue);
            //if (resetSalesPrice && lineItem.QuantityValue == 1 && tieredPrice != null) lineItem.SalesPrice = String.valueOf(tieredPrice);
            if (resetSalesPrice && lineItem.QuantityValue == 1 && tieredPrice != null) lineItem.SalesPriceValue = tieredPrice;
            system.debug(' ### salesprice ' + lineItem.SalesPriceValue + ' tier price ' + tieredPrice);
            lineItem.useTieredPricing = lineItem.SalesPriceValue == tieredPrice;
        }
    }

    public LineItemInfo cloneLine(LineItemInfo lineItem)
    {
        String APDId = lineItem.APDId;
        LineItemInfo newLineItem = new LineItemInfo(SelectedLines.size(), lineItem.SortValue, APDId, lineItem.ProductId, lineItem.ProductName, '', lineItem.IsKit, lineItem.ProductCode, lineItem.NonStock);
        newLineItem.PriceBookEntryId = lineItem.PriceBookEntryId;
        newLineItem.IsActive = lineItem.IsActive;
        newLineItem.HasActivePBE = lineItem.HasActivePBE;
        newLineItem.ListPrice = lineItem.ListPrice;
        newLineItem.SalesPrice = lineItem.SalesPrice;
        newLineItem.Quantity = lineItem.Quantity;
        newLineItem.QuantityValue = (newLineItem.QuantityValue==null ? 1 : newLineItem.QuantityValue);
        newLineItem.Discount = lineItem.Discount;
        newLineItem.IsService = lineItem.IsService;
        newLineItem.StartDate = lineItem.StartDate;
        newLineItem.EndDate = lineItem.EndDate;
        newLineItem.ServiceTerm = lineItem.ServiceTerm;
        newLineItem.UnitofTerm = lineItem.UnitofTerm;
        newLineItem.LineDescription = lineItem.LineDescription;
        newLineItem.kitBundlePricing = lineItem.kitBundlePricing;
        newLineItem.ProductKitMembers = lineItem.ProductKitMembers;
        newLineItem.tiers = lineItem.tiers;
        newLineItem.useTieredPricing = lineItem.useTieredPricing;
        newLineItem.salesInstruction = lineItem.salesInstruction;
        newLineItem.isFavorite = lineItem.isFavorite;
        newLineItem.isKitBundleMemberRequired = lineItem.isKitBundleMemberRequired;
        newLineItem.allowQuantityChange = lineItem.allowQuantityChange;
        newLineItem.kitBundleHeaderName = lineItem.kitBundleHeaderName;

		// Five Star changes
        newLineItem.LockPrice = lineItem.LockPrice;
        newLineItem.RecipientLimit = lineItem.RecipientLimit;
        newLineItem.CreateOrderFulfillment = lineItem.CreateOrderFulfillment;
        newLineItem.NumOrderFulfillments = lineItem.NumOrderFulfillments;

        system.debug(' ### orderDiscount in cloneLine ' + ApexPages.currentPage().getParameters().get('headerDiscount'));
        if (ApexPages.currentPage().getParameters().containsKey('headerDiscount')) {
            try {
                newLineItem.HeaderDiscount = decimal.valueOf(ApexPages.currentPage().getParameters().get('headerDiscount'));
            } catch (exception ex) {}
        }

		// Five Star changes - discount customization
        if (newLineItem.LockPrice) newLineItem.DiscountValue = -1 * (headerDiscountValue==null ? 0 : headerDiscountValue);

        SelectedLines.add(newLineItem);

        return newLineItem;
    }

    //Formats the string to the decimal to calculate.
    public static Decimal convertToDecimal(String a) {
        Decimal d = null;
        if(a != '' && a != null) {
            //System.debug('$$$$ a = ' + a);
            if (decimalSeparator == '.') {
                if(a.contains(',')) {
                    a = a.replace(',', '');
                }
            } else {
                
                a = a.replace('.', '');
                a = a.replace(',', '.');
                // added the following line to support Norwegian (Norway) - NOK
                a = a.replace(' ', '');
            }
            //System.debug('$$$$ a = ' + a);
            //d = Decimal.valueOf(Double.valueOf(a)).setScale(2, System.RoundingMode.DOWN);
            d = Decimal.valueOf(Double.valueOf(a)).setScale(2);
        }
        return d;
    }
    
    //Formats the decimal to string with specific digits.
    public static String convertToFormattedString(Decimal num, Integer digit) {
        //system.debug(' ### decimalSeparator = ' + decimalSeparator + ' -  num = ' + num);
        String formattedString;
        if(num != null) {
            //formattedString = num.format();
            
            String a = num.setScale(digit).format();            
            if(decimalSeparator == '.' && a.contains('.')) {
                a = a.replace('.', ':');
            } else if (decimalSeparator == ',' && a.contains(',')) {
                a = a.replace(',', ':');
            }

            String[] b = a.split(':');
            String intPlaces = (b.size() > 0) ? b[0] : '0';
            String decimalPlaces = (b.size() > 1) ? b[1] : '';
            for(Integer i = decimalPlaces.length(); i < digit ; i++) {
                decimalPlaces += '0';
            }
            formattedString = (digit == 0) ? intPlaces : intPlaces + decimalSeparator + decimalPlaces;            
        } else {
            formattedString = '';
        }
        //system.debug('$$$$ a = ' + formattedString);
        return formattedString;
    }

    //Converts the paramater from the page to integer.
    public static Integer convertIndex(String para)
    {
        String index = ApexPages.currentPage().getParameters().get(para);
        index = (index == null || index == '') ? '-1' : index;
        return Integer.valueOf(index);
    }
    
    //Formats the queryKey to SOQL query key
    public static String formatQueryKey(String qk)
    {
        String key = qk;
        if(key == null)
        {
            key = '';
        }
        else
        {
            //key = String.escapeSingleQuotes(key);
            if(key.contains('*'))
            {
                key = key.replace('*', '%');
            }
        }
        key = '%' + key + '%';
        return key;
    }
    
    
    public String sortDirection { get; set; }
    private String sortExp = 'ProductName';
    
    public String sortExpression {
        get { return sortExp; }
        set {
            //if the column is clicked on then switch between Ascending and Descending modes       
            if (value == sortExp)
                sortDirection = (sortDirection == 'asc')? 'desc' : 'asc';      
            else
                sortDirection = 'asc';     
            sortExp = value;
           }
    }

    public void sortResults() {

        system.debug(' ### sortExpression sortDirection before ' + sortExpression + ' ' + sortDirection);

        ProductLines = sortProducts(sortExpression, sortDirection, ProductLines);
        ResetPaging();

        system.debug(' ### sortExpression sortDirection after ' + sortExpression + ' ' + sortDirection);       

        return;
    }

    public void sortRecommendedProducts() {
        recommendedProducts = sortProducts(sortExpression, sortDirection, recommendedProducts);
        ResetPaging();
    }

    public void sortFavoriteProducts() {
        favoriteProducts = sortProducts(sortExpression, sortDirection, favoriteProducts);
        ResetPaging();
    }

    public static list<LineItemInfo> sortProducts(String sortExpression, String sortDirection, list<LineItemInfo> lineItems) {
        String tmpKey;
        list<String> searchKey = new list<String>();        
        Map<String, list<LineItemInfo>> searchKeyMap = new Map<String, list<LineItemInfo>>();
        
        list<Double> searchKeyNum = new list<Double>();     

        for (LineItemInfo lineItem : lineItems){
            if (sortExpression=='Service'){
                tmpKey = (lineItem.IsService ? '1' : '0');
            } else if (sortExpression=='KitBundle'){
                tmpKey = (lineItem.IsKit ? '1' : '0');  
            } else if (sortExpression=='ProductName'){
                tmpKey = lineItem.ProductName;
            } else if (sortExpression=='ProductCode'){
                tmpKey = lineItem.ProductCode;
            } else if (sortExpression=='Description'){
                tmpKey = lineItem.LineDescription;
            } else if (sortExpression=='ListPrice'){
                //tmpKey = Double.valueOf(lineItem.ListPrice.replaceAll(',', '')).format();
                tmpKey = Double.valueOf(convertToDecimal(lineItem.ListPrice)).format();
            }

            if (sortExpression=='ListPrice'){
                //searchKeyNum.add(lineItem.ListPrice == null ? 0 : Double.valueOf(lineItem.ListPrice.replaceAll(',', '')));  
                searchKeyNum.add(lineItem.ListPrice == null ? 0 : Double.valueOf(convertToDecimal(lineItem.ListPrice)));
            }
            else{
                searchKey.add(tmpKey);
            }
            
            if (!searchKeyMap.containsKey(tmpKey))
                searchKeyMap.put(tmpKey, new list<LineItemInfo>());

            searchKeyMap.get(tmpKey).add(lineItem);
        }

        list<LineItemInfo> sortedLineItems = new list<LineItemInfo>();
        if (sortExpression=='ListPrice'){
            // Sort the List in ascending order.            
            searchKeyNum.sort();
            
            for (Double d : searchKeyNum){
                                
                String s = d.format();
                sortedLineItems.add(searchKeyMap.get(s).get(0));
                searchKeyMap.get(s).remove(0);
                // Optionally we can remove the item from the Map.
                if (searchKeyMap.get(s).size() == 0){
                    searchKeyMap.remove(s);
                }
            }
        } else {
            // Sort the List in ascending order.
            searchKey.sort();
            
            for (String s : searchKey){
                sortedLineItems.add(searchKeyMap.get(s).get(0));
                searchKeyMap.get(s).remove(0);
                // Optionally we can remove the item from the Map.
                if (searchKeyMap.get(s).size() == 0){
                    searchKeyMap.remove(s);
                }
                continue;           
            }           
        }
        
        // Implement Desc Logic except for Service field.
        if (sortDirection != 'asc'){
            list<LineItemInfo> sortedLineItemsDesc = new list<LineItemInfo>();

            for(Integer i=sortedLineItems.size()-1; i>=0; i--){
                sortedLineItemsDesc.add(sortedLineItems[i]);
            }

            sortedLineItems = sortedLineItemsDesc;
        }

        for(Integer i = 0; i < sortedLineItems.size() - 1; i++) {
            sortedLineItems[i].Index = i;
        }

        return sortedLineItems;
    }

    public String getCurrencyCode(SObject obj) {
        String currencyCode = '';
        if (kugo2p.Currencies.isMultiCurrencyEnabled) {
            currencyCode = kugo2p.Currencies.getRecordCurrencyCode(obj);
            //if (currencySymbols.containsKey(currencyCode)) currencySymbol = currencySymbols.get(currencyCode);
            // map ISO currency code to currency Symbol for multi currency orgs 
            currencySymbol = currencyCode;
        } else {
        	if (currencySymbols.containsKey(userInfo.getDefaultCurrency())) currencySymbol = currencySymbols.get(userInfo.getDefaultCurrency());
        }
        if (String.isNotBlank(currencySymbol)) currencySymbol += ' ';

        return currencyCode;
    }
    
    public static String CurrencyIsoCodeField {
        get {
            return kugo2p.Currencies.isMultiCurrencyEnabled ? 'CurrencyIsoCode, ' : '';
        }
    }

	// http://www.xe.com/symbols.php
    public static Map<String, String> currencySymbols = new Map<String, String> {
        'CNY' => '¥',
        'JPY' => '¥',
        'EUR' => '€',
        'BRL' => 'R$',
        'INR' => '₹',
        'RUB' => '₽',
        'IDR' => 'Rp',
        'TRY' => '₺',
        'CHF' => 'CHF',

        'KRW' => '￦',	//₩ (two dashes but SF is using one dash)
        'KPW' => '￦',

        'IRR' => '﷼',
        'OMR' => '﷼',
        'QAR' => '﷼',
        'SAR' => '﷼',
        'YER' => '﷼',        

        'NOK' => 'kr',
        'DKK' => 'kr',
        'ISK' => 'kr',
        'SEK' => 'kr',

        'ARS' => '$',
        'AUD' => '$',
        'BSD' => '$',
        'BBD' => '$',
        'BMD' => '$',
        'BND' => '$',
        'CAD' => '$',
        'KYD' => '$',
        'CLP' => '$',
        'COP' => '$',
        'XCD' => '$',
        'SVC' => '$',
        'FJD' => '$',
		'GYD' => '$',
		'HKD' => '$',
        'LRD' => '$',
        'MXN' => '$',
        'NAD' => '$',
        'NZD' => '$',
        'SGD' => '$',
        'SBD' => '$',
        'SRD' => '$',
        'TVD' => '$',
        'USD' => '$',

        'EGP' => '£',
        'FKP' => '£',
        'GIP' => '£',
        'GGP' => '£',
        'IMP' => '£',
        'JEP' => '£',
        'LBP' => '£',
        'SHP' => '£',
        'SYP' => '£',
        'GBP' => '£'
    };

	@testVisible
    private static Map<Id, PricebookEntry> mPricebookEntries = new Map<Id, PricebookEntry>();
    private static Map<String, list<kugo2p__TieredPricing__c>> mPricebookTieredPricing = new Map<String, list<kugo2p__TieredPricing__c>>();
    private static Map<String, Map<Id, list<kugo2p__Tier__c>>> mPricebookProductTiers = new Map<String, Map<Id, list<kugo2p__Tier__c>>>();

    public static List<PricebookEntry> getPricebookEntries(Id pricebookId, Set<Id> productIds, String currencyCode) {
        System.debug(' ### Kugamon.getPricebookEntries(pricebookId, set<productId>):\n   pricebookId = '+ pricebookId +'\n   productIds = '+ productIds);
        
        list<PricebookEntry> pbe_list = Database.query(
            'Select Id, ' + CurrencyIsoCodeField + ' UseStandardPrice, UnitPrice, ProductCode, Product2Id, Pricebook2Id, Name, IsActive ' +
            'From PricebookEntry ' + 
            'Where Product2Id IN :productIds And Pricebook2Id = :pricebookId' + (Kugo2p.Util.isNullOrEmpty(currencyCode) ? '' : ' and CurrencyIsoCode = \'' + currencyCode  + '\' ' )
        );

        for (PricebookEntry pbe : pbe_list) {
            mPricebookEntries.put(pbe.Id, pbe);
        }

        return pbe_list;
    }
    
    public static PricebookEntry getPricebookEntry(Id pricebookId, Id productId, String currencyCode) {
        System.debug(' ### Kugamon.getPricebookEntry(pricebookId,productId):\n   pricebookId = '+ pricebookId +'\n   productId = '+ productId + '\n currencyCode = ' + currencyCode);
        currencyCode = currencyCode==null ? '' : currencyCode;
        for (PricebookEntry entry : mPricebookEntries.values()) {
            if (entry.Pricebook2Id == pricebookId && entry.Product2Id == productId && (currencyCode == '' || currencyCode == kugo2p.Currencies.getRecordCurrencyCode(entry))) return entry;
        }

        // no entry found yet - query
        try {
            System.debug(' ### Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
            PricebookEntry entry;
            for (PricebookEntry pbe : Database.query('Select Id, ' + CurrencyIsoCodeField + ' UseStandardPrice, UnitPrice, ProductCode, Product2Id, Pricebook2Id, Name, IsActive ' +
            										'From PricebookEntry p ' +
            										'Where isDeleted=false And Product2Id = \'' + productId + '\' And Pricebook2Id = \'' + pricebookId + '\'' + 
            										(Kugo2p.Util.isNullOrEmpty(currencyCode) ? '' : ' and CurrencyIsoCode = \'' + currencyCode  + '\' ' ))) {

                mPricebookEntries.put(pbe.Id, pbe);
                if (pbe.Pricebook2Id == pricebookId && pbe.Product2Id == productId && (currencyCode == '' || currencyCode == kugo2p.Currencies.getRecordCurrencyCode(pbe))) entry = pbe; 
            }

            return entry;
        } catch (System.QueryException e) {
            return null;
        }
    }

    public static list<kugo2p__TieredPricing__c> getPricebookTieredPricing(String pricebookName, set<Id> productIds, String currencyCode) {

        list<kugo2p__TieredPricing__c> lstTieredPricing = mPricebookTieredPricing.get(pricebookName);
        System.debug(' ### Kugamon.getPricebookTieredPricing(pricebookName): ' + pricebookName + ' ('+((lstTieredPricing==null)?'database':'cache')+')');
        system.debug(' ### currencyCode in getPricebookTieredPricing ' + currencyCode);

        if (lstTieredPricing == null) {
            System.debug(' ### Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
			String soql = 'Select Id, ' + CurrencyIsoCodeField + ' kugo2p__Pricebook2Id__c, kugo2p__PriceBookName__c, kugo2p__Product__c, kugo2p__IsActive__c, ' +
						      '(select Id, Name, kugo2p__QuantityStart__c, kugo2p__TieredPricing__c, kugo2p__TieredPricing__r.kugo2p__Product__c, kugo2p__TierPrice__c from kugo2p__Tiers__r ' +  
						       (currencyCode != null && currencyCode != '' ? ' where CurrencyIsoCode = \'' + currencyCode  + '\' ' : '')  +  ' order by kugo2p__QuantityStart__c desc) ' + 
						   'From kugo2p__TieredPricing__c ' +
						   'Where kugo2p__IsActive__c = true and kugo2p__Product__c != null and kugo2p__PriceBookName__c = \'' + pricebookName + '\'' +
						   (productIds != null && !productIds.isEmpty() ? ' and kugo2p__Product__c in : productIds ' : '');
			system.debug(' ### soql lstTieredPricing: ' + soql);

            lstTieredPricing = Database.query(soql);

            if (lstTieredPricing.isEmpty()) {
                mPricebookTieredPricing.put(pricebookName, new list<kugo2p__TieredPricing__c>());
                mPricebookProductTiers.put(pricebookName, new map<Id, list<kugo2p__Tier__c>>());
            } else {
                //system.debug(' ### lstTieredPricing ' + lstTieredPricing.size() + ' => ' + lstTieredPricing);
                getPricebookEntries(lstTieredPricing[0].kugo2p__Pricebook2Id__c, productIds, currencyCode);
    
                Map<Id, list<kugo2p__Tier__c>> mapProductTiers = new Map<Id, list<kugo2p__Tier__c>>();
                for (kugo2p__TieredPricing__c tp : lstTieredPricing) {
                    //system.debug(' ### tp.Tiers__r ' + tp.Tiers__r.size() + ' => ' + tp.Tiers__r);
                    mapProductTiers.put(tp.kugo2p__Product__c, tp.kugo2p__Tiers__r);

                    mapProductTiers.get(tp.kugo2p__Product__c).add(new kugo2p__Tier__c(kugo2p__QuantityStart__c=0, kugo2p__TierPrice__c=getPricebookEntry(tp.kugo2p__Pricebook2Id__c, tp.kugo2p__Product__c, currencyCode).UnitPrice));
                }
                mPricebookTieredPricing.put(pricebookName, lstTieredPricing);
                mPricebookProductTiers.put(pricebookName, mapProductTiers);
            }
        }

        return lstTieredPricing;
    }
    
    public static map<Id, list<kugo2p__Tier__c>> getPricebookProductTiers(String pricebookName, set<Id> productIds, String currencyCode) {
        getPricebookTieredPricing(pricebookName, productIds, currencyCode);
        return getPricebookProductTiers(pricebookName);
    }
    
    public static map<Id, list<kugo2p__Tier__c>> getPricebookProductTiers(String pricebookName) {
        return mPricebookProductTiers != null && mPricebookProductTiers.containsKey(pricebookName) ? mPricebookProductTiers.get(pricebookName) : new map<Id, list<kugo2p__Tier__c>>();
    }
    
    public static decimal getProductTieredPrice(map<Id, list<kugo2p__Tier__c>> mapProductTiers, Id productId, decimal quantity) {
        system.debug(' ### quantity in getProductTieredPrice ' + quantity);
        decimal tieredPrice;
        if (mapProductTiers != null && mapProductTiers.containsKey(productId)) {
            for (kugo2p__Tier__c tier : mapProductTiers.get(productId)) {
                if (quantity >= tier.kugo2p__QuantityStart__c) {
                    tieredPrice = tier.kugo2p__TierPrice__c;
                    break;
                }
            }
        }
        return tieredPrice;
    }

    public void displayAllFilters() {
        showMoreFilters = true;
    }

    public void hideAllFilters() {
        showMoreFilters = false;
    }
    
    public static String decimalSeparator {
        get {
            if (decimalSeparator == null) {
                decimal value = 1000.10;
                String formattedValue = value.format();
                //String thousandSep = formattedValue.substring(1, 2);
                decimalSeparator = formattedValue.substring(5, 6);
            }

            return decimalSeparator;
        }
    }

	public virtual void validateInactiveLines() {

		hasInactiveLines = false;
		for (LineItemInfo lif : SelectedLines) {
			if (!lif.IsActive) {
				hasInactiveLines = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.Warning, 'This ' + lineType + ' contains <font color="red"><b>Inactive</b></font> line(s).'));
				break;
			}
		}
	}

	// Five Star changes
	public map<Integer, String> mapLineIndex_To_PrimaryRecipientId = new map<Integer, String>{};
	private LineItemInfo selectedLineItemInfo;

	public void manageRecipients() {
		showRecipient = true;
		Integer index = convertIndex('sindex');

		for (LineItemInfo lif : SelectedLines) {
			if (lif.Index == index) {
				selectedLineItemInfo = lif;
				break;
			}
		}
		system.debug(' ### index in manageRecipients ' + index + ' selectedLineItemInfo ' + selectedLineItemInfo);
		// system.debug(' ### selectedLineItemInfo.mapSelectedRecipients in manageRecipients ' + selectedLineItemInfo.mapSelectedRecipients);
		if (mapAutoCompleteSourceRecipients.isEmpty() && marketId != null && String.isNotBlank(publicationYear)) {
			for (Contact rec : Database.query(ManageRecipientController.getQuery(marketId, publicationYear, ''))) {
				mapAutoCompleteSourceRecipients.put(rec.Name, rec.Name);
			}
			system.debug(' ### mapAutoCompleteSourceRecipients ' + mapAutoCompleteSourceRecipients.size());
		}

		manageRecipientCon = new ManageRecipientController(marketId, publicationYear, selectedLineItemInfo.ProductName, selectedLineItemInfo.RecipientLimit, selectedLineItemInfo.QuantityValue, selectedLineItemInfo.mapSelectedRecipients, selectedLineItemInfo.setUnselectedRecipients, mapAutoCompleteSourceRecipients);

		//selectedPrimaryRecipientId = null;
		if (!mapLineIndex_To_PrimaryRecipientId.containsKey(selectedLineItemInfo.index) && selectedLineItemInfo.mapRecipientId_To_LineRecipient != null) {
			for (LineRecipient__c lr : selectedLineItemInfo.mapRecipientId_To_LineRecipient.values()) {
				if (lr.Primary__c) {
					mapLineIndex_To_PrimaryRecipientId.put(selectedLineItemInfo.index, lr.Recipient__c);
					manageRecipientCon.selectedPrimaryRecipientId = lr.Recipient__c;
					manageRecipientCon.selectedPrimaryRecipientIdInitial = lr.Recipient__c;

					break;
				}
			}
		}
	}

	public void hideRecipient() {

		if (selectedLineItemInfo != null) {
			selectedLineItemInfo.mapSelectedRecipients = manageRecipientCon.mapSelectedRecipients;
			selectedLineItemInfo.setUnselectedRecipients = manageRecipientCon.setUnselectedRecipients;
			mapLineIndex_To_PrimaryRecipientId.put(selectedLineItemInfo.index, manageRecipientCon.selectedPrimaryRecipientId);
			system.debug(' ### selectedPrimaryRecipientId in hideRecipient ' + manageRecipientCon.selectedPrimaryRecipientId);

			// update Kit Bundle Members for new items
			if (selectedLineItemInfo.isKit && selectedLineItemInfo.isNewItem) {
                for (LineItemInfo lif : SelectedLines) {
                    if (lif.KitBundleHeaderIndex != null && lif.KitBundleHeaderIndex == selectedLineItemInfo.index) {
                        lif.mapSelectedRecipients = selectedLineItemInfo.mapSelectedRecipients;
                    }
                }
			}
		}

		showRecipient = false;
		manageRecipientCon = null;
	}	

/*****************************************************************************************************************************************
												Inner classes
 *****************************************************************************************************************************************/	

    public class LineItemInfo
    {
        private String quantityErrorValue;
        private String salespriceErrorValue;
        private String discountErrorValue;
        private String startDateErrorValue;
        private String endDateErrorValue;
        private String ServiceTermErrorValue;
        
        public LineItemInfo() {
            init();
        }

        public LineItemInfo(Integer index, Integer sortValue, String APDId, String ProductId, String productName, String lineItemId, Boolean kitBundle, String productCode, boolean nonStock)
        {
            this.Index = index;
            this.SortValue = sortValue;
            this.APDId = APDId;
            this.ProductId = ProductId;
            this.ProductCode = productCode;
            this.ProductName = productName;
            this.LineItemId = lineItemId;
            this.IsKit = kitBundle;
            this.NonStock = nonStock;

            init();
        }

        private void init() {
            this.IsService = false;
            this.HeaderDiscount = 0;
            this.QuantityError = false;
            this.SalesPriceError = false;
            this.DiscountError = false;
            this.StartDateError = false;
            this.EndDateError = false;
            this.ServiceTermError = false;
            this.startDate = Date.today().format();
            this.EndDate = '';
            this.IsActive = false;
            this.HasActivePBE = false;
            this.IsFavorite = false;
            this.isKitBundleMemberRequired = true;
            this.allowQuantityChange = false;
            this.isKitHeaderAProduct = false;
        }

        public Integer Index { get; set; }
        public Integer SortValue { get; set; }
        public String LineItemId { get; private set; }
        public String APDId { get; private set; }
        public String ProductId { get; private set; }
        public String ProductCode { get; private set; }
        public String ProductName { get; private set; }
        public boolean IsActive {get; set;}
        public boolean HasActivePBE {get; set;}
        public String ListPrice { get; set; }
        public Decimal HeaderDiscount { get; set; }
        public Boolean QuantityError { get; private set; }
        public Boolean SalesPriceError { get; private set; }
        public Boolean DiscountError { get; private set; }
        public Boolean ServiceTermError { get; private set; }
        public Boolean StartDateError { get; private set; }
        public Boolean EndDateError { get; private set; }
        public Boolean IsKit { get; private set; }
        public Boolean IsService { get; set; }
        public Decimal QuantityValue { get; set; }
        public Decimal SalesPriceValue { get; set; }
        public Decimal DiscountValue { get; set; }
        public Date StartDateValue { get; set; }
        public Date EndDateValue { get; set; }
        public String UnitOfTerm    { get; set; }
        public Integer ServiceTermValue { get; set; }
        public String LineDescription { get; set; }
        public Boolean NonStock { get; private set; }
        public decimal AvailableQuantity { get; set {if (value==null) AvailableQuantity=0; else AvailableQuantity=value;} }
        public Integer KitBundleHeaderIndex { get; set; }
        Public String KitBundleLineId { get; set; }
        public String KitBundlePricing { get; set; }
        public Id PriceBookEntryId { get; set; }
        public String salesInstruction {get; set;}
        public map<Id, LineItemInfo> productKitMembers { get; set; }
        public list<kugo2p__Tier__c> tiers {get; set;}
        public list<RecommendedProduct__c> recommendedProducts {get; set;}
        public Boolean IsFavorite { get; set; }
        public boolean isKitBundleMemberRequired {get; set;}
        public boolean allowQuantityChange {get; set;}
        public String kitBundleHeaderName {get; set;}
        // isKitHeaderAProduct is only set for Service Kit Members, whose Header line is a Product 
        public boolean isKitHeaderAProduct {get; set;}

		// Five Star changes        
        public boolean LockPrice {get; set;}
        public String RecipientLimit {get; set;}
		public boolean CreateOrderFulfillment {get; set;}
		public decimal NumOrderFulfillments {get; set;}
        public map<Id, LineRecipient__c> mapRecipientId_To_LineRecipient = new map<Id, LineRecipient__c>{};
		public map<Id, String> mapSelectedRecipients = new map<Id, String>();
		public set<Id> setUnselectedRecipients = new set<Id>();

		// Five Star changes
		public boolean hasAssignedRecipients {
			get {
				return !mapSelectedRecipients.isEmpty();
			}
			private set;
		}

		// Five Star changes
		public integer AssignedRecipientsCount {
			get {
				return mapSelectedRecipients.size();
			}
			private set;
		}        

        public boolean hasRecommendedProducts {
            get {
                return recommendedProducts != null && !recommendedProducts.isEmpty();
            }
            private set;
        }

        public boolean useTieredPricing {
            get {
                if (useTieredPricing == null) useTieredPricing = false;
                return useTieredPricing;
            }
            set;
        }

        public boolean getHasTieredPricing() {
            return tiers != null && !tiers.isEmpty();
        }

        public String getTiersJSON() {
            String jsonString = '';
            if (getHasTieredPricing()) {                
                list<kugo2p__Tier__c> sortedTiers = new list<kugo2p__Tier__c>();
                list<kugo2p__Tier__c> sortedTiersDesc = new list<kugo2p__Tier__c>();

                for (TierWrapper tw : tiersWrapper) {
                    sortedTiers.add(tw.tier);
                }

                for(Integer i=sortedTiers.size()-1; i>=0; i--){
                    sortedTiersDesc.add(sortedTiers[i]);
                }
                jsonString = JSON.serialize(sortedTiersDesc);
            }
            return jsonString;
        }

        public list<TierWrapper> tiersWrapper {
            get {
                if (tiersWrapper == null && tiers != null) {
                    tiersWrapper = new list<TierWrapper>();
                    map<Integer, kugo2p__Tier__c> tierSort = new map<Integer, kugo2p__Tier__c>();

                    for (kugo2p__Tier__c t : tiers) tierSort.put(Integer.valueOf(t.kugo2p__QuantityStart__c), t);

                    for (Integer qty : kugo2p.Util.sortNumberSet(tierSort.keySet())) {
                        tiersWrapper.add(new TierWrapper(convertToDecimal(listPrice), tierSort.get(qty)));
                    }
                }
                return tiersWrapper;
            }
            private set;
        }

        public list<LineItemInfo> getKitMembers() {
            return productKitMembers != null ? productKitMembers.values() : new list<LineItemInfo>(); 
        }

        public boolean getHasInActiveKitMember() {
			for (LineItemInfo lif : getKitMembers()) {
				if (!lif.IsActive || !lif.HasActivePBE) return true;
			}

			return false;
        }

        public String Quantity
        {
            get
            {
                if(QuantityError)
                {
                    return quantityErrorValue;
                }
                else
                {
                    return convertToFormattedString(QuantityValue, 2);
                }
            }
            set
            {
                try
                {
                    quantityErrorValue = value;
                    //QuantityValue = (convertToDecimal(value) == null) ? null : convertToDecimal(value).intValue();
                    QuantityValue = convertToDecimal(value);
                    QuantityError = false;
                }
                catch(Exception ex)
                {
                    QuantityError = true;
                }
            }
        }
        
        public String SalesPrice
        {
            get
            {
                if(SalesPriceError)
                {
                    return salesPriceErrorValue;
                }
                else
                {
                    return convertToFormattedString(SalesPriceValue, 2);
                }
            }
            set
            {
                try
                {
                    salesPriceErrorValue = value;
                    SalesPriceValue = convertToDecimal(value);
                    SalesPriceError = false;
                }
                catch(Exception ex)
                {
                    SalesPriceError = true;
                }
            }
        }
        
        public String ServiceTerm {
            get {
                if(ServiceTermError) {
                    return ServiceTermErrorValue;
                } else {
                    return convertToFormattedString(ServiceTermValue, 0);
                }
            }
            set {
                try {
                    ServiceTermErrorValue = value;
                    ServiceTermValue = Integer.valueOf(value);
                    ServiceTermError = false;
                    if (ServiceTermValue == null || ServiceTermValue <= 0) serviceTermError = true;
                } catch(Exception ex) {
                    ServiceTermError = true;
                }
            }
        }        
        
        public String Discount
        {
            get
            {
                if(DiscountError)
                {
                    return discountErrorValue;
                }
                else
                {
                    return convertToFormattedString(DiscountValue, 2);
                }
            }
            set
            {
                try
                {
                    discountErrorValue = value;
                    DiscountValue = convertToDecimal(value);
                    DiscountError = false;
                }
                catch(Exception ex)
                {
                    DiscountError = true;
                }
            }
        }
        
        public String TotalDiscount {
            get {
                return convertToFormattedString(kugo2p.Util.assignIfNotNull(HeaderDiscount, 0) + kugo2p.Util.assignIfNotNull(DiscountValue, 0), 2);
            }
            private set;
        }        
        
        public decimal TotalAmountValue {
            get {
                try {
                    decimal spValue = (SalesPriceValue == null) ? 0 : SalesPriceValue;
                    decimal qtyValue = (QuantityValue == null) ? 0 : QuantityValue;
                    decimal dcValue = (DiscountValue == null) ? 0 : DiscountValue;
                    decimal sTerm = serviceTermValue==null || serviceTermValue <= 0 ? 1 : serviceTermValue;
                    TotalAmountValue = spValue * qtyValue * sTerm * (100 - dcValue - HeaderDiscount) / 100;
                } catch(Exception ex) {
                    TotalAmountValue = 0;
                }
                return TotalAmountValue;
            }
            private set;
        }
        
        public String TotalAmount {
            get {
                try {
                    return convertToFormattedString(TotalAmountValue, 2);
                } catch (Exception ex) {
                    return '0.00';
                }
            }
            private set;
        }

        public String startDate
        {
            get
            {
                if(StartDateError)
                {
                    return startDateErrorValue;
                }
                else
                {
                    return StartDateValue.format();
                }
            }
            set
            {
                try
                {
                    startDateErrorValue = value;
                    StartDateValue = date.parse(value);
                    StartDateError = false;
                    if (StartDateValue == null || value == null || value == '') startDateError = true;
                }
                catch(Exception ex)
                {
                    StartDateError = true;
                }
            }
        }
        
        public String endDate {
            get {
                if(EndDateError) {
                    return endDateErrorValue;
                } else {
                    return EndDateValue.format();
                }
            }
            set {
                try {
                    endDateErrorValue = value;
                    endDateValue = date.parse(value);
                    EndDateError = false;
                    if (IsService && (endDateValue == null || value == null || value == '')) endDateError = true;
                } catch(Exception ex) {
                    EndDateError = true;
                }
            }
        }

        public boolean isNewKitBundleMember {
            get {
                return (KitBundleLineId == null && KitBundleHeaderIndex >= 0); 
            }
            private set;
        }
        
        public boolean isNewItem {
            get {
                return (LineItemId==null || LineItemId=='');
            }
            private set;            
        }
        
        public boolean isKitBundleMember {
            get { 
                return (KitBundleHeaderIndex != null && KitBundleHeaderIndex >= 0);
            }
            private set;
        }
        
        public void calculateServiceEndDate() {
            Date end_date = EndDateValue;

            if (!IsService || String.isBlank(UnitOfTerm) || StartDateValue == null) return;

            if (UnitOfTerm == 'Second' || UnitOfTerm == 'Minute' || UnitOfTerm == 'Hour') {
                // Don't change the End date provided; but default it to the start date if one isn't provided
                //EndDateValue = Kugo2p.Util.assignIfNotNull(EndDateValue, StartDateValue);
                //if (EndDateValue < StartDateValue) EndDateValue = StartDateValue;
                EndDate = String.isBlank(EndDate) ? StartDate : EndDate;
            } else {
                Integer service_term = ServiceTermValue==null ? 1 : ServiceTermValue;
                if (UnitOfTerm == 'Day')
                    end_date = StartDateValue.addDays(service_term);
                else if (UnitOfTerm == 'Week')
                    end_date = StartDateValue.addDays(7 * service_term);
                else if (UnitOfTerm == 'Fortnight')
                    end_date = StartDateValue.addDays(14 * service_term);
                else if (UnitOfTerm == 'Month')
                    end_date = StartDateValue.addMonths(service_term);
                else if (UnitOfTerm == 'Quarter')
                    end_date = StartDateValue.addMonths(3 * service_term);
                else if (UnitOfTerm == 'Year')
                    end_date = StartDateValue.addYears(service_term);

                System.debug(' ### end date: '+end_date);
                //EndDate = end_date.addDays(-1).format();
				if (UnitOfTerm == 'Day' || UnitOfTerm == 'Week' || UnitOfTerm == 'Fortnight' || StartDateValue.day() == end_date.day()) end_date = end_date.addDays(-1);
				EndDate = end_date.format();
            }
            
            if (EndDateValue < StartDateValue) EndDate = StartDate;
            
            system.debug(' ### EndDateValue = ' + EndDateValue);
        }
    }
    
    public class TierWrapper {
        public kugo2p__Tier__c tier     {get; set;}
        public decimal pbListPrice      {get; set;}
        
        public decimal discountValue {
            get;
            set {
                discountValue = value;
                if (discountValue == null) discountValue = 0;
                discountValue = discountValue.setScale(2, RoundingMode.HALF_UP);
            }
        }

        public TierWrapper(decimal pblp, kugo2p__Tier__c t) {
            this.pbListPrice = pblp;
            this.tier = t;
            calcTierDiscount();
        }

        public void calcTierDiscount() {
            this.discountValue = this.pbListPrice==0 ? (this.tier.kugo2p__TierPrice__c * 100) : (((1 - (this.pbListPrice > 0 ? (this.tier.kugo2p__TierPrice__c / this.pbListPrice) : 0)) * 100).setScale(2,RoundingMode.HALF_UP));
        }
        
        public Integer getQuantityStart() {
            return tier != null && tier.kugo2p__QuantityStart__c != null ? Integer.valueOf(tier.kugo2p__QuantityStart__c) : 0;
        }       

        public String getDiscount() {
            return convertToFormattedString(this.discountValue, 2) + '%';
        }
        
        public String getTierPrice() {
            return tier != null && tier.kugo2p__TierPrice__c != null ? convertToFormattedString(tier.kugo2p__TierPrice__c, 2) : '0';
        }
    }

    public class FilterWrapper {
        private List<String> stringOperators = new List<String>{'equals', 'not equal to', 'less than', 'greater than', 'less or equal', 'greater or equal', 'contains', 'does not contain', 'starts with'};
        private List<String> booleanOperators = new List<String>{'equals', 'not equal to'};
        private List<String> numericalOperators = new List<String>{'equals', 'not equal to', 'less than', 'greater than', 'less or equal', 'greater or equal'};

        public List<SelectOption>fieldOptions {get; set;}
        public String selectedFieldName {get; set;}
        public List<SelectOption>operatorOptions {get; set;}
        public String selectedOperator {get; set;}
        public String selectedFieldValue {get; set;}
        public String filterType {get; set;}
        public String objectType {get; set;}
        public Integer index {get; set;}

        public FilterWrapper(Integer i, boolean showAdditionalDetails) {
            
            selectedFieldValue = '';
            selectedFieldName = '--None--';
            selectedOperator = '--None--';
            objectType = '';
            index = i;

            fieldOptions = new List<SelectOption>();
            fieldOptions.add(new SelectOption('--None--', '--None--'));
            fieldOptions.add(new SelectOption('Product', 'Product', true));
            // Add product fields
            Map<String, Schema.SObjectField>prodFieldMap = Schema.SObjectType.Product2.fields.getMap();
            List<String>fieldKeys = new List<String>();
            fieldKeys.addAll(prodFieldMap.keySet());
            fieldKeys.sort();

            for (String cur : fieldKeys) {
                Schema.DescribeFieldResult curField = prodFieldMap.get(cur).getDescribe();
                if (curField.isFilterable() && curField.getType() != Schema.DisplayType.REFERENCE && !curField.getLabel().containsIgnoreCase('deprecated')) {
                    fieldOptions.add(new SelectOption(curField.getName(), curField.getLabel()));
                }
            }
            if (showAdditionalDetails) {
                fieldOptions.add(new SelectOption('Additional Product Info', 'Additional Product Info', true));
                // Add additional product detail fields
                Map<String, Schema.SObjectField>addProdFieldMap = Schema.SObjectType.kugo2p__AdditionalProductDetail__c.fields.getMap();
                fieldKeys = new List<String>();
                fieldKeys.addAll(addProdFieldMap.keySet());
                fieldKeys.sort();

                for (String cur : fieldKeys) {
                    Schema.DescribeFieldResult curField = addProdFieldMap.get(cur).getDescribe();
                    if (curField.isFilterable() && curField.getType() != Schema.DisplayType.REFERENCE && !curField.getLabel().containsIgnoreCase('deprecated')) {
                        fieldOptions.add(new SelectOption(curField.getName(), curField.getLabel()));
                    }
                }
            }

            updateOperatorOptions();
       
        }

        public void updateOperatorOptions() {
            Schema.DisplayType selectedType;
            
            Map<String, Schema.SObjectField> productMap = Schema.SObjectType.Product2.fields.getMap();
            Map<String, Schema.SObjectField> addProdMap = Schema.SObjectType.kugo2p__AdditionalProductDetail__c.fields.getMap();
            System.debug('$$$$$ selectedFieldName = ' + selectedFieldName);
            if (productMap.containsKey(selectedFieldName)) {
                selectedType = productMap.get(selectedFieldName).getDescribe().getType();
                objectType = 'product';
            } else if (addProdMap.containsKey(selectedFieldName)) {
                selectedType = addProdMap.get(selectedFieldName).getDescribe().getType();
                objectType = 'additionalDetails';
            } else {
                selectedType = Schema.DisplayType.INTEGER;
                System.debug('$$$$$ shouldnt be here');
            }

            system.debug(' ### selectedFieldName = ' + selectedFieldName);
            system.debug(' ### selectedType = ' + selectedType);

            operatorOptions = new List<SelectOption>();
            operatorOptions.add(new SelectOption('--None--', '--None--'));
            filterType = selectedType.name();
            if (selectedType == Schema.DisplayType.COMBOBOX
                || selectedType == Schema.DisplayType.EMAIL
                || selectedType == Schema.DisplayType.PHONE
                || selectedType == Schema.DisplayType.REFERENCE
                || selectedType == Schema.DisplayType.STRING
                || selectedType == Schema.DisplayType.TEXTAREA
                || selectedType == Schema.DisplayType.URL
                || selectedType == Schema.DisplayType.PICKLIST
                || selectedType == Schema.DisplayType.MULTIPICKLIST
                || selectedType == Schema.DisplayType.ID) {
            
        for (String op : stringOperators) {
          operatorOptions.add(new SelectOption(op, op));
        }
      } else if (
        selectedType == Schema.DisplayType.CURRENCY
        || selectedType == Schema.DisplayType.DOUBLE
        || selectedType == Schema.DisplayType.INTEGER
        || selectedType == Schema.DisplayType.PERCENT
        || selectedType == Schema.DisplayType.DATETIME
        || selectedType == Schema.DisplayType.DATE
      ){
        for (String op : numericalOperators) {
          operatorOptions.add(new SelectOption(op, op));
        }
      } else {
        for (String op : booleanOperators) {
          operatorOptions.add(new SelectOption(op, op));
        }
      }            
    }
  }
}