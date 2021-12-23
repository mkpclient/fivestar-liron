public with sharing class ManageLinesOrderExt extends ManageLinesController {
    private final Id orderId;
    public kugo2p__SalesOrder__c salesOrder { get; set; }
    
	/* ***** HANDLE TO CURRENT INSTANCE OF the controller (to be passed to rendered VF components, avoids re-instantiation of controller) ***** */
	public ManageLinesOrderExt manageLinesOrderCon { get { return this; } }

    public ManageLinesOrderExt(ApexPages.StandardController sc) {
    	lineType = 'Order';
        salesOrder = (kugo2p__SalesOrder__c)sc.getRecord();

        if(salesOrder != null) {
        	this.sortDirection = 'asc';
            orderId = salesOrder.Id;
            PricebookName = salesOrder.kugo2p__PriceBookName__c;
            PricebookNameOptionValue = salesOrder.kugo2p__PriceBookName__c;

			// Five Star changes
            contactBuying = salesOrder.kugo2p__ContactBuying__r;
            marketId = salesOrder.Market__c;
            publicationYear = salesOrder.Market__r.Publication_Year__c;

            showAdditionalDetails = true;
            initFilters();

			recordStatus = salesOrder.kugo2p__RecordStatus__c;
			if (recordStatus == 'Released' || recordStatus == 'Cancelled') {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.Warning, recordStatus + ' Order cannot be modified.'));
				//return;
			}
			currencyCode = getCurrencyCode(salesOrder);

            headerDiscountValue = (salesOrder.kugo2p__DiscountPercent__c == null) ? 0 : salesOrder.kugo2p__DiscountPercent__c;
            ProductLines = initProductLines(PricebookName, QueryKey, ExactMatch);                        
            SelectedLines = initSelectedLines(orderId);
            resetFavorites();
            validateInactiveLines();
        }
    }

    public PageReference save() {
    	PageReference pageRef;
        Boolean isSucceeded = updateRecords();
        if (isSucceeded) {
            pageRef = new PageReference('/' + orderId);

            system.debug(' ### saveOnly ' + getPageParameter('saveOnly'));
            if (getPageParameter('saveOnly') == '1') pageRef = new PageReference('/apex/ManageLinesOrder?id=' + orderId);
            pageRef.setRedirect(true);
        }
		return pageRef;
    }

	public override String getPageTitle() {
		return 'Manage Products/Services to ' + salesOrder.Name;
    }

    public PageReference resetPricebook() {

		PageReference pageRef;
        try {
        	system.debug(' ### salesOrder ' + salesOrder);
            if (salesOrder != null) {

		    	delete [Select Id from kugo2p__SalesOrderServiceLine__c where kugo2p__SalesOrder__c = :SalesOrder.Id and (kugo2p__KitBundle__c = true OR (kugo2p__KitBundle__c = false and kugo2p__KitBundleProductServiceLineId__c = null))];
		    	delete [Select Id from kugo2p__SalesOrderProductLine__c where kugo2p__SalesOrder__c = :SalesOrder.Id and (kugo2p__KitBundle__c = true OR (kugo2p__KitBundle__c = false and kugo2p__KitBundleLine__c = null))];

                salesOrder.kugo2p__PriceBookName__c = PricebookNameOptionValue;
                update salesOrder;

	            pageRef = new PageReference('/apex/ManageLinesOrder?id=' + salesOrder.Id);
	            pageRef.setRedirect(true);
            }

        } catch (Exception ex) {
        	system.debug(' ### exception in resetPricebook ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to change pricebook: ' + ex.getMessage()));
        }

        return pageRef;
    }

    private List<LineItemInfo> initSelectedLines(String oid)
    {
        List<LineItemInfo> lineItems = new List<LineItemInfo>();
        Integer sortValue, index = 0;
        LineItemInfo lineItem;

		list<kugo2p__SalesOrderProductLine__c> sopls = [select 	Id, kugo2p__KitBundle__c, kugo2p__KitBundleLine__c, kugo2p__LineDescription__c, kugo2p__Product__c, kugo2p__Product__r.Name, 
																kugo2p__Product__r.kugo2p__Active__c, kugo2p__Product__r.kugo2p__ReferenceProduct__c, kugo2p__Product__r.kugo2p__ReferenceProduct__r.ProductCode, 
																kugo2p__Product__r.kugo2p__ReferenceProduct__r.SalesInstruction__c, kugo2p__SortOrder__c, kugo2p__Product__r.kugo2p__KitBundle__c, 
																kugo2p__Product__r.kugo2p__KitBundlePricing__c, kugo2p__Product__r.kugo2p__NonStock__c, kugo2p__SalesPrice__c, kugo2p__Quantity__c, 
																kugo2p__LineDiscountPercent__c, kugo2p__TotalAmount__c, kugo2p__DateRequired__c, kugo2p__KitBundleMemberRequired__c, kugo2p__AllowQuantityChange__c, 
																kugo2p__KitBundleLine__r.kugo2p__Product__r.Name
																// Five Star changes
																, kugo2p__Product__r.LockPrice__c, kugo2p__Product__r.RecipientLimit__c, kugo2p__Product__r.CreateOrderFulfillment__c, kugo2p__Product__r.NumberofOrderFulfillments__c																
														from 	kugo2p__SalesOrderProductLine__c 
														where 	kugo2p__SalesOrder__c = :oid 
														order by kugo2p__SortOrder__c];

		list<kugo2p__SalesOrderServiceLine__c> sosls = [select 	Id, kugo2p__KitBundle__c, kugo2p__KitBundleProductServiceLineId__c, kugo2p__LineDescription__c, kugo2p__Service__c, kugo2p__Service__r.Name, 
																kugo2p__Service__r.kugo2p__Active__c, kugo2p__Service__r.kugo2p__ReferenceProduct__c, kugo2p__Service__r.kugo2p__ReferenceProduct__r.ProductCode, 
																kugo2p__Service__r.kugo2p__ReferenceProduct__r.SalesInstruction__c, kugo2p__SortOrder__c, kugo2p__Service__r.kugo2p__KitBundle__c, 
																kugo2p__Service__r.kugo2p__KitBundlePricing__c, kugo2p__Service__r.kugo2p__NonStock__c, kugo2p__SalesPrice__c, kugo2p__Quantity__c, 
																kugo2p__LineDiscountPercent__c, kugo2p__TotalAmount__c, kugo2p__DateServiceStart__c, kugo2p__DateServiceEnd__c, kugo2p__ServiceTerm__c, 
																kugo2p__UnitofTerm__c, kugo2p__KitBundleMemberRequired__c, kugo2p__AllowQuantityChange__c, kugo2p__KitBundleProductLine__r.kugo2p__Product__r.Name, 
																kugo2p__KitBundleServiceLine__r.kugo2p__Service__r.Name
																// Five Star changes
																, kugo2p__Service__r.LockPrice__c, kugo2p__Service__r.RecipientLimit__c, kugo2p__Service__r.CreateOrderFulfillment__c, kugo2p__Service__r.NumberofOrderFulfillments__c
														from 	kugo2p__SalesOrderServiceLine__c 
														where 	kugo2p__SalesOrder__c = :oid 
														order by kugo2p__SortOrder__c];

		// Five Star changes														
		Id lineId;
		map<Id, list<LineRecipient__c>> mapLineId_To_LineRecipients = new map<Id, list<LineRecipient__c>>{};
		for (LineRecipient__c lr : [Select Id, Order__c, OrderProductLine__c, OrderServiceLine__c, Primary__c, Recipient__c, Recipient__r.Name from LineRecipient__c where Order__c = :oid order by Recipient__r.Name]) {

			//if (lr.Primary__c) selectedPrimaryRecipientId = lr.Recipient__c;
			//if (lr.Primary__c) mapLineIndex_To_PrimaryRecipientId.put(lr.OrderProductLine__c != null ? lr.OrderProductLine__c : lr.OrderServiceLine__c, lr.Recipient__c);

			lineId = lr.OrderProductLine__c != null ? lr.OrderProductLine__c : lr.OrderServiceLine__c;
			if (!mapLineId_To_LineRecipients.containsKey(lineId)) mapLineId_To_LineRecipients.put(lineId, new list<LineRecipient__c>{});
			mapLineId_To_LineRecipients.get(lineId).add(lr);
		}

		set<Id> setProductIds = new set<Id>(); 
		map<Id, list<kugo2p__KitBundleMember__c>> mapKitBundleMembers = new map<Id, list<kugo2p__KitBundleMember__c>>();
		for (kugo2p__SalesOrderProductLine__c productLineItem : sopls) {
			setProductIds.add(productLineItem.kugo2p__Product__r.kugo2p__ReferenceProduct__c);
			if (productLineItem.kugo2p__KitBundle__c) {
				mapKitBundleMembers.put(productLineItem.kugo2p__Product__c, new list<kugo2p__KitBundleMember__c>());
			}
		}
		for (kugo2p__SalesOrderServiceLine__c serviceLineItem : sosls) {
			setProductIds.add(serviceLineItem.kugo2p__Service__r.kugo2p__ReferenceProduct__c);
			if (serviceLineItem.kugo2p__KitBundle__c) {
				mapKitBundleMembers.put(serviceLineItem.kugo2p__Service__c, new list<kugo2p__KitBundleMember__c>());
			}
		}

		system.debug(' ### mapKitBundleMembers ' + mapKitBundleMembers.size() + ' => ' + mapKitBundleMembers);
		if (!mapKitBundleMembers.isEmpty()) {
			for (kugo2p__KitBundleMember__c kbm : [Select 	Id, Name, kugo2p__Quantity__c, kugo2p__AllowQuantityChange__c, kugo2p__Required__c, kugo2p__ReferenceKitBundle__c, kugo2p__ReferenceMemberProductService__c, 
															kugo2p__ReferenceMemberProductService__r.Name, kugo2p__ReferenceMemberProductService__r.kugo2p__Active__c, 
															kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__c, kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__r.ProductCode, 
															kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__r.SalesInstruction__c, kugo2p__ReferenceMemberProductService__r.kugo2p__StandardPrice__c, 
															kugo2p__ReferenceMemberProductService__r.kugo2p__KitBundle__c, kugo2p__ReferenceMemberProductService__r.kugo2p__KitBundlePricing__c,
															kugo2p__ReferenceMemberProductService__r.kugo2p__Service__c, kugo2p__ReferenceMemberProductService__r.kugo2p__NonStock__c, 
															kugo2p__ReferenceMemberProductService__r.kugo2p__UnitofTerm__c, kugo2p__ReferenceMemberProductService__r.kugo2p__DefaultServiceTerm__c
															// Five Star changes
															, kugo2p__ReferenceMemberProductService__r.LockPrice__c, kugo2p__ReferenceMemberProductService__r.RecipientLimit__c, kugo2p__ReferenceMemberProductService__r.CreateOrderFulfillment__c,
															kugo2p__ReferenceMemberProductService__r.NumberofOrderFulfillments__c															
													from 	kugo2p__KitBundleMember__c 
													where 	kugo2p__ReferenceKitBundle__c in : mapKitBundleMembers.keySet()]) {
				
				mapKitBundleMembers.get(kbm.kugo2p__ReferenceKitBundle__c).add(kbm);
			}
		}
		system.debug(' ### mapKitBundleMembers ' + mapKitBundleMembers.size() + ' => ' + mapKitBundleMembers);

        for (kugo2p__SalesOrderProductLine__c productLineItem : sopls) {
        	if (productLineItem.kugo2p__KitBundleLine__c == null) {
        		
        		// Five Star changes
				//lineItems.add(addLineItem(index, productLineItem));
				LineItemInfo lih = addLineItem(index, productLineItem);
				lineItems.add(lih);
        		index++;

        		// Five Star changes
        		setRecipients(lih, (mapLineId_To_LineRecipients.containsKey(productLineItem.Id) ? mapLineId_To_LineRecipients.get(productLineItem.Id) : null));

        		if (productLineItem.kugo2p__KitBundle__c) {

        			// Five Star changes
        			//LineItemInfo lih = lineItems[lineItems.size()-1];
        			
        			lih.productKitMembers = new map<Id, LineItemInfo>();
					for (kugo2p__KitBundleMember__c kbm : mapKitBundleMembers.get(productLineItem.kugo2p__Product__c)) {
						LineItemInfo li = addLineItem(lih.productKitMembers.size(), null, null, kbm.kugo2p__ReferenceMemberProductService__r);
						li.QuantityValue = kbm.kugo2p__Quantity__c==null? 1 : kbm.kugo2p__Quantity__c;

						lih.productKitMembers.put(kbm.kugo2p__ReferenceMemberProductService__c, li);
					}

        			Integer kitHeaderIndex = index-1;
        			for (kugo2p__SalesOrderProductLine__c pli : sopls) {
        				if (pli.kugo2p__KitBundleLine__c == productLineItem.Id) {
							lineItem = addLineItem(index, pli);
							lineItem.KitBundleHeaderIndex = kitHeaderIndex;
							lineItems.add(lineItem);
							//system.debug(' ### entering kit member ' + lineItem.KitBundleHeaderIndex + ' ' + );
							
			        		index++;

			        		// Five Star changes
			        		setRecipients(lineItem, (mapLineId_To_LineRecipients.containsKey(pli.Id) ? mapLineId_To_LineRecipients.get(pli.Id) : null));
        				}
        			}
        			
        			for (kugo2p__SalesOrderServiceLine__c sli : sosls) {
        				if (sli.kugo2p__KitBundleProductServiceLineId__c == productLineItem.Id) {
							lineItem = addLineItem(index, sli);
							lineItem.KitBundleHeaderIndex = kitHeaderIndex;
							lineItem.isKitHeaderAProduct = true;
							lineItems.add(lineItem);
							//system.debug(' ### entering kit member1 index ' + lineItem.index + ' KitBundleHeaderIndex ' + lineItem.KitBundleHeaderIndex + ' sortValue ' + lineItem.sortValue);

			        		index++;

							// Five Star changes
			        		setRecipients(lineItem, (mapLineId_To_LineRecipients.containsKey(sli.Id) ? mapLineId_To_LineRecipients.get(sli.Id) : null));
        				}
        			}
        		}
        	}
        }
        
        for(kugo2p__SalesOrderServiceLine__c serviceLineItem : sosls) {
        	if (serviceLineItem.kugo2p__KitBundleProductServiceLineId__c == null) {
        		
        		// Five Star changes
				//lineItems.add(addLineItem(index, serviceLineItem));
				LineItemInfo lih = addLineItem(index, serviceLineItem);
				lineItems.add(lih);
        		index++;

				//system.debug(' ### adding serviceLine ' + lineItems[lineItems.size()-1].index + ' KitBundleHeaderIndex ' + lineItems[lineItems.size()-1].KitBundleHeaderIndex + ' sortValue ' + lineItems[lineItems.size()-1].sortValue);
        		if (serviceLineItem.kugo2p__KitBundle__c) {

        			// Five Star changes
        			//LineItemInfo lih = lineItems[lineItems.size()-1];
        			
        			lih.productKitMembers = new map<Id, LineItemInfo>();
					for (kugo2p__KitBundleMember__c kbm : mapKitBundleMembers.get(serviceLineItem.kugo2p__Service__c)) {
						LineItemInfo li = addLineItem(lih.productKitMembers.size(), null, null, kbm.kugo2p__ReferenceMemberProductService__r);
						li.QuantityValue = kbm.kugo2p__Quantity__c==null ? 1 : kbm.kugo2p__Quantity__c;

						lih.productKitMembers.put(kbm.kugo2p__ReferenceMemberProductService__c, li);
					}

        			Integer kitHeaderIndex = index-1;
        			for (kugo2p__SalesOrderServiceLine__c sli : sosls) {
        				if (sli.kugo2p__KitBundleProductServiceLineId__c == serviceLineItem.Id) {

							lineItem = addLineItem(index, sli);
							lineItem.KitBundleHeaderIndex = kitHeaderIndex;
							lineItems.add(lineItem);
							//system.debug(' ### entering kit member ' + lineItem.KitBundleHeaderIndex + ' ' + );
							//system.debug(' ### entering kit member2 ' + lineItem.index + ' KitBundleHeaderIndex ' + lineItem.KitBundleHeaderIndex + ' sortValue ' + lineItem.sortValue);

			        		index++;

			        		// Five Star changes
			        		setRecipients(lineItem, (mapLineId_To_LineRecipients.containsKey(sli.Id) ? mapLineId_To_LineRecipients.get(sli.Id) : null));
        				}
        			}
        		}
        	}
        }

		//getrecommendedProducts(setProductIds);
		for (Id pid : setProductIds) {
			addrecommendedProducts(pid);
		}

        //lineItems = sortLines(lineItems);
        return lineItems;
    }

	// Five Star changes
	private void setRecipients(LineItemInfo lih, list<LineRecipient__c> lineRecipients) {
		system.debug(' ### lineRecipients ' + lineRecipients);
		if (lih != null && lineRecipients != null && !lineRecipients.isEmpty()) {
			for (LineRecipient__c lr : lineRecipients) {
				lih.mapRecipientId_To_LineRecipient.put(lr.Recipient__c, lr);
				lih.mapSelectedRecipients.put(lr.Recipient__c, lr.Recipient__r.Name);
			}
		}
		system.debug(' ### lih.mapSelectedRecipients ' + lih.mapSelectedRecipients.size() + ' => ' + lih.mapSelectedRecipients);
	}

    private LineItemInfo addLineItem(Integer index, kugo2p__SalesOrderProductLine__c productLineItem) {
        Integer sortValue = (productLineItem.kugo2p__SortOrder__c == null) ? 999 : productLineItem.kugo2p__SortOrder__c.intValue();
        
        LineItemInfo lineItem = new LineItemInfo(index, sortValue, productLineItem.kugo2p__Product__c, productLineItem.kugo2p__Product__r.kugo2p__ReferenceProduct__c, productLineItem.kugo2p__Product__r.Name, productLineItem.Id, productLineItem.kugo2p__Product__r.kugo2p__KitBundle__c, productLineItem.kugo2p__Product__r.kugo2p__ReferenceProduct__r.ProductCode, productLineItem.kugo2p__Product__r.kugo2p__NonStock__c);
        if (unitPriceMap != null) lineItem.ListPrice = convertToFormattedString(unitPriceMap.get(productLineItem.kugo2p__Product__r.kugo2p__ReferenceProduct__c), 2);
        lineItem.SalesPriceValue = productLineItem.kugo2p__SalesPrice__c;
        lineItem.QuantityValue = productLineItem.kugo2p__Quantity__c;
        lineItem.DiscountValue = productLineItem.kugo2p__LineDiscountPercent__c==null ? 0 : productLineItem.kugo2p__LineDiscountPercent__c;
        lineItem.LineDescription = productLineItem.kugo2p__LineDescription__c;
        lineItem.HeaderDiscount = headerDiscountValue==null ? 0 : headerDiscountValue;
        lineItem.StartDateValue = productLineItem.kugo2p__DateRequired__c;
        lineItem.KitBundleLineId = productLineItem.kugo2p__KitBundleLine__c;
        lineItem.IsActive = productLineItem.kugo2p__Product__r.kugo2p__Active__c;
        lineItem.HasActivePBE = unitPriceMap != null && unitPriceMap.containsKey(productLineItem.kugo2p__Product__r.kugo2p__ReferenceProduct__c);
        lineItem.salesInstruction = productLineItem.kugo2p__Product__r.kugo2p__ReferenceProduct__r.SalesInstruction__c;
        lineItem.isKitBundleMemberRequired = productLineItem.kugo2p__KitBundleMemberRequired__c;
        lineItem.allowQuantityChange = productLineItem.kugo2p__AllowQuantityChange__c;
        lineItem.kitBundleHeaderName = productLineItem.kugo2p__KitBundleLine__r.kugo2p__Product__r.Name;

		// Five Star changes
        lineItem.LockPrice = productLineItem.kugo2p__Product__r.LockPrice__c;
        lineItem.RecipientLimit = productLineItem.kugo2p__Product__r.RecipientLimit__c;
        lineItem.CreateOrderFulfillment = productLineItem.kugo2p__Product__r.CreateOrderFulfillment__c;
        lineItem.NumOrderFulfillments = productLineItem.kugo2p__Product__r.NumberofOrderFulfillments__c;

		initTiers(lineItem, false);

		return lineItem;
    }

    private LineItemInfo addLineItem(Integer index, kugo2p__SalesOrderServiceLine__c serviceLineItem) {    
        Integer sortValue = (serviceLineItem.kugo2p__SortOrder__c == null) ? 999 : serviceLineItem.kugo2p__SortOrder__c.intValue();
        
        LineItemInfo lineItem = new LineItemInfo(index, sortValue, serviceLineItem.kugo2p__Service__c, serviceLineItem.kugo2p__Service__r.kugo2p__ReferenceProduct__c, serviceLineItem.kugo2p__Service__r.Name, serviceLineItem.Id, serviceLineItem.kugo2p__Service__r.kugo2p__KitBundle__c, serviceLineItem.kugo2p__Service__r.kugo2p__ReferenceProduct__r.ProductCode, serviceLineItem.kugo2p__Service__r.kugo2p__NonStock__c);
        if (unitPriceMap != null) lineItem.ListPrice = convertToFormattedString(unitPriceMap.get(serviceLineItem.kugo2p__Service__r.kugo2p__ReferenceProduct__c), 2);
        lineItem.UnitOfTerm = serviceLineItem.kugo2p__UnitofTerm__c;
        lineItem.SalesPriceValue = serviceLineItem.kugo2p__SalesPrice__c;
        lineItem.QuantityValue = serviceLineItem.kugo2p__Quantity__c;
        lineItem.DiscountValue = serviceLineItem.kugo2p__LineDiscountPercent__c;
        lineItem.LineDescription = serviceLineItem.kugo2p__LineDescription__c;
        lineItem.HeaderDiscount = headerDiscountValue==null ? 0 : headerDiscountValue;
        lineItem.IsService = true;
        lineItem.StartDate = serviceLineItem.kugo2p__DateServiceStart__c==null ? '' : serviceLineItem.kugo2p__DateServiceStart__c.format();
        lineItem.EndDate = serviceLineItem.kugo2p__DateServiceEnd__c==null ? '' : serviceLineItem.kugo2p__DateServiceEnd__c.format();
        lineItem.ServiceTerm = serviceLineItem.kugo2p__ServiceTerm__c==null ? '0' : String.valueOf(serviceLineItem.kugo2p__ServiceTerm__c);
        lineItem.KitBundleLineId = serviceLineItem.kugo2p__KitBundleProductServiceLineId__c;
        lineItem.IsActive = serviceLineItem.kugo2p__Service__r.kugo2p__Active__c;
        lineItem.HasActivePBE = unitPriceMap != null && unitPriceMap.containsKey(serviceLineItem.kugo2p__Service__r.kugo2p__ReferenceProduct__c);
        lineItem.salesInstruction = serviceLineItem.kugo2p__Service__r.kugo2p__ReferenceProduct__r.SalesInstruction__c;
        lineItem.isKitBundleMemberRequired = serviceLineItem.kugo2p__KitBundleMemberRequired__c;
        lineItem.allowQuantityChange = serviceLineItem.kugo2p__AllowQuantityChange__c;
        lineItem.kitBundleHeaderName = kugo2p.Util.assignIfNotEmpty(serviceLineItem.kugo2p__KitBundleProductLine__r.kugo2p__Product__r.Name, serviceLineItem.kugo2p__KitBundleServiceLine__r.kugo2p__Service__r.Name);

        // Five Star changes
        lineItem.LockPrice = serviceLineItem.kugo2p__Service__r.LockPrice__c;
        lineItem.RecipientLimit = serviceLineItem.kugo2p__Service__r.RecipientLimit__c;
        lineItem.CreateOrderFulfillment = serviceLineItem.kugo2p__Service__r.CreateOrderFulfillment__c;
        lineItem.NumOrderFulfillments = serviceLineItem.kugo2p__Service__r.NumberofOrderFulfillments__c;        

		initTiers(lineItem, false);

		return lineItem;
    }    
    
    private Boolean updateRecords()
    {
        //Validates the input value.
        for(LineItemInfo lineItem : SelectedLines)
        {
            if(lineItem.QuantityError || lineItem.SalesPriceError || lineItem.DiscountError || lineItem.StartDateError || (lineItem.IsService && (lineItem.EndDateError || lineItem.ServiceTermError)))
            {
            	//system.debug(' ### raising error #1');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure quantities, sales prices, discounts, and dates are entered and valid.'));
                return false;
            }
            if(lineItem.Quantity == '' || lineItem.SalesPrice == '' || lineItem.StartDate == '' || (lineItem.EndDate == '' && lineItem.IsService))
            {
            	//system.debug(' ### raising error #2');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please input the Quantity, Sales Price, and Date for all the line items that you need to save.'));
                return false;
            }

            // Five Star changes
			if (lineItem.RecipientLimit == '1' || lineItem.RecipientLimit == 'Line Quantity') {	//String.isBlank(recipientLimit) ||
	    		decimal maxRecipients = lineItem.recipientLimit == '1' ? 1 : lineItem.QuantityValue;
	    		if (lineItem.mapSelectedRecipients.size() > maxRecipients) {
	    			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The number of selected Recipients must be equal to ' + maxRecipients + ' for the Product ' + lineItem.ProductName + '.'));
	    			return false;
	    		}
			}            
            
            if(lineItem.Discount == '')
            {
                lineItem.Discount = '0.00';
            }
        }
        //Gets the deleting records.
        List<SObject> linesToDelete = new List<SObject>();
        if(deleteLineIds != null)
        {
            for(kugo2p__SalesOrderProductLine__c pl:[select Id from kugo2p__SalesOrderProductLine__c where Id in :deleteLineIds])
            {
                linesToDelete.add(pl);
            }
            for(kugo2p__SalesOrderServiceLine__c sl:[select Id from kugo2p__SalesOrderServiceLine__c where Id in :deleteLineIds])
            {
                linesToDelete.add(sl);
            }
        }
        
        Map<String, LineItemInfo> updateLinesMap = new Map<String, LineItemInfo>();
        List<SObject> linesToUpdate = new List<SObject>();
        List<SObject> linesToInsert = new List<SObject>();
        kugo2p__SalesOrderProductLine__c pLine;
        kugo2p__SalesOrderServiceLine__c sLine;

        // Five Star changes
        map<Integer, kugo2p__SalesOrderProductLine__c> mapIndex_To_sopl = new map<Integer, kugo2p__SalesOrderProductLine__c>();
        map<Integer, kugo2p__SalesOrderServiceLine__c> mapIndex_To_sosl = new map<Integer, kugo2p__SalesOrderServiceLine__c>();
        
        for(LineItemInfo lineItem : SelectedLines)
        {
            
            if(lineItem.LineItemId instanceOf Id)
            {
                updateLinesMap.put(lineItem.LineItemId, lineItem);
            }
            //Gets the inserting records.
            else
            {
            	if (!lineItem.isNewKitBundleMember) { 
	                if(lineItem.IsService)
	                {
	                    sLine = new kugo2p__SalesOrderServiceLine__c();
	                    sLine.kugo2p__SalesOrder__c = orderId;
	                    sLine.kugo2p__Service__c = lineItem.APDId;
	                    sLine.kugo2p__Quantity__c = lineItem.QuantityValue;
	                    sLine.kugo2p__SalesPrice__c = lineItem.SalesPriceValue;
	                    sLine.kugo2p__LineDiscountPercent__c = lineItem.DiscountValue;
	                    sLine.kugo2p__LineDescription__c = lineItem.LineDescription;
	                    sLine.kugo2p__DateServiceStart__c = lineItem.StartDateValue;
	                    sLine.kugo2p__DateServiceEnd__c = lineItem.EndDateValue;
	                    sLine.kugo2p__ServiceTerm__c = lineItem.ServiceTermValue;
	                    sLine.kugo2p__SortOrder__c = lineItem.SortValue;

						// Five Star changes
	                    //linesToInsert.add(sLine);
	                    mapIndex_To_sosl.put(lineItem.Index, sLine);
	                }
	                else
	                {
	                    pLine = new kugo2p__SalesOrderProductLine__c();
	                    pLine.kugo2p__SalesOrder__c = orderId;
	                    pLine.kugo2p__Product__c = lineItem.APDId;
	                    pLine.kugo2p__Quantity__c = lineItem.QuantityValue;
	                    pLine.kugo2p__SalesPrice__c = lineItem.SalesPriceValue;
	                    pLine.kugo2p__LineDiscountPercent__c = lineItem.DiscountValue;
	                    pLine.kugo2p__LineDescription__c = lineItem.LineDescription;
	                    pLine.kugo2p__DateRequired__c = lineItem.StartDateValue;
	                    pLine.kugo2p__SortOrder__c = lineItem.SortValue;

						// Five Star changes
	                    //linesToInsert.add(pLine);
	                    mapIndex_To_sopl.put(lineItem.Index, pLine);
	                }
            	}        
                
            }
        }
        //Gets the updating records.
        LineItemInfo lineItemInfo;
        for(kugo2p__SalesOrderProductLine__c productLine : [select 	Id, kugo2p__LineDescription__c, kugo2p__SalesPrice__c, kugo2p__Quantity__c, kugo2p__LineDiscountPercent__c 
        													from 	kugo2p__SalesOrderProductLine__c 
        													where 	Id in :updateLinesMap.keyset()])
        {
            lineItemInfo = updateLinesMap.get(productLine.Id);
            productLine.kugo2p__SalesPrice__c = lineItemInfo.SalesPriceValue;
            productLine.kugo2p__Quantity__c = lineItemInfo.QuantityValue;
            productLine.kugo2p__LineDiscountPercent__c = lineItemInfo.DiscountValue;
            productLine.kugo2p__LineDescription__c = lineItemInfo.LineDescription;
            productLine.kugo2p__DateRequired__c = lineItemInfo.StartDateValue;
            productLine.kugo2p__SortOrder__c = lineItemInfo.SortValue;

			// Five Star changes
            //linesToUpdate.add(productLine);
            mapIndex_To_sopl.put(lineItemInfo.Index, productLine);
        }
        for(kugo2p__SalesOrderServiceLine__c serviceLine : [select 	Id, kugo2p__LineDescription__c, kugo2p__SalesPrice__c, kugo2p__Quantity__c, kugo2p__LineDiscountPercent__c,
        															kugo2p__DateServiceStart__c, kugo2p__DateServiceEnd__c, kugo2p__ServiceTerm__c
        													from 	kugo2p__SalesOrderServiceLine__c where Id in :updateLinesMap.keyset()])
        {
            lineItemInfo = updateLinesMap.get(serviceLine.Id);
            serviceLine.kugo2p__SalesPrice__c = lineItemInfo.SalesPriceValue;
            serviceLine.kugo2p__Quantity__c = lineItemInfo.QuantityValue;
            serviceLine.kugo2p__LineDiscountPercent__c = lineItemInfo.DiscountValue;
            serviceLine.kugo2p__LineDescription__c = lineItemInfo.LineDescription;
            serviceLine.kugo2p__DateServiceStart__c = lineItemInfo.StartDateValue;
            serviceLine.kugo2p__DateServiceEnd__c = lineItemInfo.EndDateValue;
            serviceLine.kugo2p__ServiceTerm__c = lineItemInfo.ServiceTermValue;
            serviceLine.kugo2p__SortOrder__c = lineItemInfo.SortValue;

			// Five Star changes
            //linesToUpdate.add(serviceLine);
            mapIndex_To_sosl.put(lineItemInfo.Index, serviceLine);
        }

        try
        {
        	
			// Five Star changes - delete Line Recipients
        	//if (deleteLineIds != null) delete [Select Id from LineRecipient__c where Order__c = :salesOrder.Id and (OrderProductLine__c in :deleteLineIds OR OrderServiceLine__c in :deleteLineIds)];
        	if (deleteLineIds != null) delete [Select Id from LineRecipient__c where Order__c = :salesOrder.Id and (OrderProductLine__c in :deleteLineIds OR OrderProductLine__r.kugo2p__KitBundleLine__c in :deleteLineIds OR OrderServiceLine__c in :deleteLineIds OR OrderServiceLine__r.kugo2p__KitBundleProductServiceLineId__c in :deleteLineIds)];        	

        	//system.debug(' ### before save ' + linesToInsert.size() + ' => ' + linesToInsert);
            if(linesToDelete.size() > 0)
            {
                delete linesToDelete;
            }

            /* // Five Star changes
            if(linesToInsert.size() > 0)
            {
                insert linesToInsert;
            }
            if(linesToUpdate.size() > 0)
            {
                update linesToUpdate;
            }*/

            // Five Star changes
            if (!mapIndex_To_sopl.isEmpty()) upsert mapIndex_To_sopl.values();
            if (!mapIndex_To_sosl.isEmpty()) upsert mapIndex_To_sosl.values();

            salesOrder.kugo2p__DiscountPercent__c = headerDiscountValue==0 ? null : headerDiscountValue;
            update salesOrder;

            // Five Star changes
            list<LineRecipient__c> lineRecipients_To_Upsert = new list<LineRecipient__c>{};
            list<LineRecipient__c> lineRecipients_To_Delete = new list<LineRecipient__c>{};
            list<Fulfillment__c> fulfillments_To_Upsert = new list<Fulfillment__c>{};
            list<Fulfillment__c> fulfillments_To_Delete = new list<Fulfillment__c>{};
 
 			list<Fulfillment__c> childFulfillments_To_Insert = new list<Fulfillment__c>();
            map<Id, Fulfillment__c> mapOrderLineId_To_Fulfillment = new map<Id, Fulfillment__c>{};
            // for (Fulfillment__c ff : [Select Id, OrderProductLine__c, OrderServiceLine__c, PrimaryRecipient__c from Fulfillment__c where OrderNumber__c = :SalesOrder.Id]) {
            // 	mapOrderLineId_To_Fulfillment.put(ff.OrderProductLine__c == null ? ff.OrderServiceLine__c : ff.OrderProductLine__c, ff);
            // }

			map<Id, LineRecipient__c> mapLineId_To_PrimaryLineRecipient = new map<Id, LineRecipient__c>{};
			for (LineRecipient__c lr : [Select Id, Order__c, OrderProductLine__c, OrderServiceLine__c, Primary__c, Recipient__c, Recipient__r.Name from LineRecipient__c where Order__c = :salesOrder.Id and Primary__c = true]) {

				Id lineId = lr.OrderProductLine__c != null ? lr.OrderProductLine__c : lr.OrderServiceLine__c;
				mapLineId_To_PrimaryLineRecipient.put(lineId, lr);
			}

            for (LineItemInfo lineItem : SelectedLines) {

            	// ignore new kit bundle members
            	if ( (!lineItem.isKitBundleMember || (lineItem.isKitBundleMember && !lineItem.isNewItem))) {

					boolean isProduct = mapIndex_To_sopl.containsKey(lineItem.index);
					Id lineId = isProduct ? mapIndex_To_sopl.get(lineItem.index).Id : mapIndex_To_sosl.get(lineItem.index).Id;				

					// process Line Recipients only if it has an entry in mapLineIndex_To_PrimaryRecipientId. If there is no entry means the User didn't navigate to the line recipients page
					if (mapLineIndex_To_PrimaryRecipientId.containsKey(lineItem.index)) {
		            	for (Id cid : lineItem.mapSelectedRecipients.keySet()) {
		            		LineRecipient__c lr = lineItem.mapRecipientId_To_LineRecipient.containsKey(cid) ? lineItem.mapRecipientId_To_LineRecipient.get(cid) : new LineRecipient__c(Order__c=salesOrder.Id, OrderProductLine__c=(isProduct ? mapIndex_To_sopl.get(lineItem.index).Id : null), OrderServiceLine__c=(mapIndex_To_sosl.containsKey(lineItem.index) ? mapIndex_To_sosl.get(lineItem.index).Id : null), Recipient__c=cid);
		            		lr.Primary__c = mapLineIndex_To_PrimaryRecipientId.get(lineItem.index) == cid || lineItem.mapSelectedRecipients.size() == 1;

							system.debug(' ### order FulfillOrder__c ' + salesOrder.FulfillOrder__c + ' lr.Fulfillment__c ' + lr.Fulfillment__c);
							if (lineItem.QuantityValue > 0 && lineItem.CreateOrderFulfillment && salesOrder.FulfillOrder__c) {
			            		if (mapOrderLineId_To_Fulfillment.containsKey(lineId) && mapOrderLineId_To_Fulfillment.get(lineId).Id != null) {
			            			lr.Fulfillment__c = mapOrderLineId_To_Fulfillment.get(lineId).Id;
			            		} else if (lr.Primary__c) {
			            			// Fulfillment__c fulfillment = new Fulfillment__c(OrderNumber__c=salesOrder.Id, OrderProductLine__c=(isProduct ? lineId : null), OrderServiceLine__c=(isProduct ? null : lineId), 
			            			// 												Status__c='New Profile', PrimaryRecipient__c=(lr.Primary__c ? lr.Recipient__c : null), 
			            			// 												Product_Name__c=lineItem.ProductName, Market__c=salesOrder.Market__c);
			            			// mapOrderLineId_To_fulfillment.put(lineId, fulfillment);

									// if (lineItem.NumOrderFulfillments > 1) {
									// 	for (Integer i=2; i <= lineItem.NumOrderFulfillments; i++) {
									// 		childFulfillments_To_Insert.add(fulfillment.clone(false, true));
									// 	}
									// }

			            			// system.debug(' ### adding a new fulfillment record for line id 1 ' + lineId + ' - ' + fulfillment);
			            			// fulfillments_To_Upsert.add(fulfillment);
			            		}
							}

							// update Fulfillment Primary Recipient, if the Primary Recipient has been updated.
							if (lr.Primary__c && lr.Fulfillment__c != null && mapOrderLineId_To_Fulfillment.get(lineId).PrimaryRecipient__c != lr.Recipient__c) {
								mapOrderLineId_To_Fulfillment.get(lineId).PrimaryRecipient__c = lr.Recipient__c;

								fulfillments_To_Upsert.add(mapOrderLineId_To_Fulfillment.get(lineId));
							}

		            		lineRecipients_To_Upsert.add(lr);
		            	}
					}

					system.debug(' ### lineItem.mapRecipientId_To_LineRecipient ' + lineItem.mapRecipientId_To_LineRecipient.size() + ' => ' + lineItem.mapRecipientId_To_LineRecipient);
	            	for (Id cid : lineItem.mapRecipientId_To_LineRecipient.keySet()) {
	            		if (!lineItem.mapSelectedRecipients.containsKey(cid)) lineRecipients_To_Delete.add(lineItem.mapRecipientId_To_LineRecipient.get(cid));
	            	}

					if ( (lineItem.QuantityValue <= 0 || !lineItem.CreateOrderFulfillment || !salesOrder.FulfillOrder__c) && mapOrderLineId_To_Fulfillment.containsKey(lineId)) fulfillments_To_Delete.add(mapOrderLineId_To_Fulfillment.get(lineId));
					if (lineItem.QuantityValue > 0 && lineItem.CreateOrderFulfillment && salesOrder.FulfillOrder__c && !mapOrderLineId_To_Fulfillment.containsKey(lineId)) {
	        			// Fulfillment__c fulfillment = new Fulfillment__c(OrderNumber__c=salesOrder.Id, OrderProductLine__c=(isProduct ? lineId : null), OrderServiceLine__c=(isProduct ? null : lineId), 
	        			// 												Status__c='New Profile', 
	        			// 												PrimaryRecipient__c=mapLineId_To_PrimaryLineRecipient.containsKey(lineId) ? mapLineId_To_PrimaryLineRecipient.get(lineId).Recipient__c : null,
	        			// 												Product_Name__c=lineItem.ProductName, Market__c=salesOrder.Market__c);
	        			// mapOrderLineId_To_fulfillment.put(lineId, fulfillment);

						if (lineItem.NumOrderFulfillments > 1) {
							for (Integer i=2; i <= lineItem.NumOrderFulfillments; i++) {
								// childFulfillments_To_Insert.add(fulfillment.clone(false, true));
							}
						}

	        			// system.debug(' ### adding a new fulfillment record for line id 2 ' + lineId + ' - ' + fulfillment);
	        			// fulfillments_To_Upsert.add(fulfillment);
					}
            	}
            }

            system.debug(' ### fulfillments_To_Upsert ' + fulfillments_To_Upsert.size() + ' => ' + fulfillments_To_Upsert);
            upsert fulfillments_To_Upsert;

			if (!childFulfillments_To_Insert.isEmpty()) {
				// for (Fulfillment__c ff : childFulfillments_To_Insert) {
				// 	Id lineId = ff.OrderProductLine__c == null ? ff.OrderServiceLine__c : ff.OrderProductLine__c;

				// 	ff.ParentFulfillment__c = mapOrderLineId_To_fulfillment.get(lineId).Id;
				// 	ff.PrimaryRecipient__c = mapOrderLineId_To_fulfillment.get(lineId).PrimaryRecipient__c;
				// }

				system.debug(' ### childFulfillments_To_Insert ' + childFulfillments_To_Insert.size() + ' => ' + childFulfillments_To_Insert);
				insert childFulfillments_To_Insert;
			}

			system.debug(' ### fulfillments_To_Delete ' + fulfillments_To_Delete.size() + ' => ' + fulfillments_To_Delete);	
            if (!fulfillments_To_Delete.isEmpty()) delete fulfillments_To_Delete;

			if (salesOrder.FulfillOrder__c) {
	            for (LineRecipient__c lr : lineRecipients_To_Upsert) {
	            	if (lr.Fulfillment__c == null) {
	            		Id lineId = lr.OrderProductLine__c != null ? lr.OrderProductLine__c : lr.OrderServiceLine__c;

						if (mapOrderLineId_To_Fulfillment.containsKey(lineId) && mapOrderLineId_To_Fulfillment.get(lineId).Id != null) {
		            		lr.Fulfillment__c = mapOrderLineId_To_Fulfillment.get(lineId).Id;
		            		system.debug(' ### assigned Fulfillment__c ' + lr.Fulfillment__c + ' for Line Recipient ' + lr.Id);
						}
	            	}
	            }
			}

            system.debug(' ### lineRecipients_To_Upsert ' + lineRecipients_To_Upsert.size() + ' => ' + lineRecipients_To_Upsert);
            upsert lineRecipients_To_Upsert;

            system.debug(' ### lineRecipients_To_Delete ' + lineRecipients_To_Delete.size() + ' => ' + lineRecipients_To_Delete);
            delete lineRecipients_To_Delete;            

            return true;
        }
        catch(Exception ex)
        {
        	//system.debug(' ### save error ' + ex);	
            ApexPages.Message saveErrMsg = new ApexPages.Message(ApexPages.Severity.ERROR,  'Save failed.');
            ApexPages.addMessage(saveErrMsg);
            saveErrMsg = new ApexPages.Message(ApexPages.Severity.ERROR,  ex.getMessage());
            ApexPages.addMessage(saveErrMsg);
            return false;
        }               
    }
}