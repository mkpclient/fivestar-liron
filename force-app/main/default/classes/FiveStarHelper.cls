public without sharing class FiveStarHelper{
	public static final String ORDER_STATUS_APPROVED = 'Approved';
	public static final String ORDER_STATUS_RELEASED = 'Released';
	public static Boolean processingOrderInvoiceEmailSchedule = false;
	public static boolean processingOrderPaymentSchedule = false;

	/**
	 * * BOOM NOTE
	 * * @name assignMarket
	 * * * this method has been recreated elsewhere and does not need to be revived.  
	 */

	public static void autoReleaseOrder(Map<Id,kugo2p__Payment_Profile__c> p1, Map<Id,kugo2p__Payment_Profile__c> p2){

	}

	// public static void assignMarket(list<kugo2p__SalesOrder__c> salesOrders){
	// 	System.debug('-> salesorders: ' + salesorders.size());
	// 	if (salesOrders != null && !salesOrders.isEmpty()){

	// 		map<Id, Opportunity> mapOpps = new map<Id, Opportunity>{};
	// 		for (kugo2p__SalesOrder__c so : salesOrders){
	// 			if ((Test.isRunningTest() || trigger.isInsert) && so.kugo2p__Opportunity__c != null)
	// 				mapOpps.put(so.kugo2p__Opportunity__c, null);
	// 		}

	// 		if (!mapOpps.isEmpty()){
	// 			mapOpps.putAll([Select Id, Market_Project__c
	// 			                from Opportunity
	// 			                where Id in :mapOpps.keySet()]);

	// 			for (kugo2p__SalesOrder__c so : salesOrders){
	// 				if ((Test.isRunningTest() || trigger.isInsert) && so.kugo2p__Opportunity__c != null){
	// 					so.Market__c = mapOpps.get(so.kugo2p__Opportunity__c).Market_Project__c;
	// 				}
	// 			}
	// 		}
	// 	}
	// }

		/**
		 * * BOOM NOTE
	 * * @name updateLockedPriceLineDiscount
	 * * * This method is referencing a field that only exists in the product additional info and the service line object.
	 * * * Also, a field with the order's discount percent already exists as a formula field called OrderDiscountPercent__c in both product line objects. 
	 * * * no need to revive.
	 * /

	// public static void updateLockedPriceLineDiscount(map<Id, kugo2p__SalesOrder__c> mapNewSalesOrders, map<Id, kugo2p__SalesOrder__c> mapOldSalesOrders){

	// 	if (mapNewSalesOrders != null && !mapNewSalesOrders.isEmpty()){
	// 		set<Id> setOrderIds = new set<Id>{};

	// 		for (kugo2p__SalesOrder__c so : mapNewSalesOrders.values()){
	// 			if ((Test.isRunningTest() || trigger.isUpdate) && so.kugo2p__DiscountPercent__c != mapOldSalesOrders.get(so.Id).kugo2p__DiscountPercent__c){
	// 				setOrderIds.add(so.Id);
	// 			}
	// 		}

	// 		if (!setOrderIds.isEmpty()){
	// 			list<kugo2p__SalesOrderProductLine__c> sopls_To_Update = [select Id, kugo2p__SalesOrder__c, kugo2p__LineDiscountPercent__c
  //         from kugo2p__SalesOrderProductLine__c
  //         where kugo2p__SalesOrder__c in :setOrderIds and kugo2p__Product__r.LockPrice__c = true];
	// 			list<kugo2p__SalesOrderServiceLine__c> sosls_To_Update = [select Id, kugo2p__SalesOrder__c, kugo2p__LineDiscountPercent__c
  //         from kugo2p__SalesOrderServiceLine__c
  //         where kugo2p__SalesOrder__c in :setOrderIds and kugo2p__Service__r.LockPrice__c = true];

	// 			for (kugo2p__SalesOrderProductLine__c sopl : sopls_To_Update){
	// 				sopl.kugo2p__LineDiscountPercent__c = mapNewSalesOrders.get(sopl.kugo2p__SalesOrder__c).kugo2p__DiscountPercent__c == null ? null : (-1 * mapNewSalesOrders.get(sopl.kugo2p__SalesOrder__c).kugo2p__DiscountPercent__c);
	// 			}

	// 			for (kugo2p__SalesOrderServiceLine__c sosl : sosls_To_Update){
	// 				sosl.kugo2p__LineDiscountPercent__c = mapNewSalesOrders.get(sosl.kugo2p__SalesOrder__c).kugo2p__DiscountPercent__c == null ? null : (-1 * mapNewSalesOrders.get(sosl.kugo2p__SalesOrder__c).kugo2p__DiscountPercent__c);
	// 			}

  //       if (!Test.isRunningTest()) {
  //         update sopls_To_Update;
  //         update sosls_To_Update;
  //       }
	// 		}
	// 	}
	// }


	/** 
	 * * BOOM NOTE
	 * * if it's necessary to rename the fields back, here are the original names for reference:
	 * * OrderLine__c => Boom_Order__c
	 * * OrderProductLine__c => Boom_Order_Product_Line__c
	 */

	 /**
		* * BOOM NOTE
		* @name fulFillOrders
		* * Recreation of original kugamon code, with updated field references.
		* * See notes for specific details.
	  */

	public static void fulFillOrders(map<Id, SalesOrder__c> mapNewSalesOrders, map<Id, SalesOrder__c> mapOldSalesOrders){

		if (mapNewSalesOrders != null && !mapNewSalesOrders.isEmpty()){
			set<Id> setOrderIds = new set<Id>{};
			set<Id> setFulFillOrderIds_To_Delete = new set<Id>{};
			set<Id> cancelledOrderIds = new set<Id>{};



			/**
			 * * BOOM NOTE
			 * * This segment deletes fulfillments when FulfillOrder__c is unchecked. 
			 * * Will need to confirm with FiveStar.
			 * * For now, in SalesORderHelper as deleteFulfillments() but commented out in afterUpdate().
			 */

			for (SalesOrder__c so : mapNewSalesOrders.values()) {
				if ((Test.isRunningTest() || trigger.isUpdate) && so.FulfillOrder__c != mapOldSalesOrders.get(so.Id).FulfillOrder__c){
					if (so.FulfillOrder__c){
						setOrderIds.add(so.Id);
					} else{
						setFulFillOrderIds_To_Delete.add(so.Id);
					}
				}

				if ((Test.isRunningTest() || trigger.isUpdate) && so.Status_Picklist__c == 'Cancelled' && so.Status_Picklist__c != mapOldSalesOrders.get(so.Id).Status_Picklist__c){
					cancelledOrderIds.add(so.Id);
				}
			}

			system.debug(' ### setOrderIds ' + setOrderIds.size()+' => ' + setOrderIds);
			if (!setOrderIds.isEmpty()){
				list<Fulfillment__c> childFulfillments_To_Insert = new list<Fulfillment__c>();
				map<Id, Fulfillment__c> mapOrderLineId_To_fulfillments = new map<Id, Fulfillment__c>{};
				map<Id, Id> mapOrderLineId_To_PrimaryRecipientId = new map<Id, Id>{};

        List<Order_Line_Recipient__c> lineRecipient_To_Update = fulfillOrdersLineRecipient(setOrderIds);

				for (Order_Line_Recipient__c lr : lineRecipient_To_Update){
					if (lr.Primary__c && lr.OrderProductLine__c != null)
						mapOrderLineId_To_PrimaryRecipientId.put(lr.OrderProductLine__c, lr.Recipient__c);
				}

				for (SalesOrderProductLine__c sopl : [select Product__r.Name, SalesOrder__c, SalesOrder__r.Market__c
				                                              from SalesOrderProductLine__c
				                                              where SalesOrder__c in :setOrderIds and Product__r.CreateOrderFulfillment__c = true and Quantity__c > 0]){
					mapOrderLineId_To_fulfillments.put(sopl.Id, new Fulfillment__c(Boom_Order__c = sopl.SalesOrder__c, Boom_Order_Product_Line__c = sopl.Id, Status__c = 'New Profile', PrimaryRecipient__c = mapOrderLineId_To_PrimaryRecipientId.get(sopl.Id), Product_Name__c = sopl.Product__r.Name, Market__c = sopl.SalesOrder__r.Market__c));
																													
					// * BOOM NOTE:
					// * Added a child fulfillment function in SalesOrderHelper.createfulfillments()
					// * sopl.kugo2p__Product__r.NumberofOrderFulfillments__c > 1
					// * field no longer exists -- 

					String numberFulfillments = sopl.Product__r.Name.substringBetween('- ', 'X');
					
					if (numberFulfillments != null && numberFulfillments.isNumeric() && Integer.valueOf(numberFulfillments) > 1){
						
						for (Integer i = 2; i <= Integer.valueOf(numberFulfillments); i++){
							childFulfillments_To_Insert.add(mapOrderLineId_To_fulfillments.get(sopl.Id).clone(false, true));
						}
					}
				}

				if (!Test.isRunningTest()){
					insert mapOrderLineId_To_fulfillments.values();
				}

				if (!childFulfillments_To_Insert.isEmpty()){
					for (Fulfillment__c ff : childFulfillments_To_Insert){
						if(ff.Boom_Order_Product_Line__c == null) {
							continue;
						}

						Id lineId = ff.Boom_Order_Product_Line__c;

						ff.ParentFulfillment__c = mapOrderLineId_To_fulfillments.get(lineId).Id;
					}

					// system.debug(' ### childFulfillments_To_Insert ' + childFulfillments_To_Insert.size()+' => ' + childFulfillments_To_Insert);
					if (!Test.isRunningTest()){
						insert childFulfillments_To_Insert;
					}
				}

				/*list<LineRecipient__c> lineRecipient_To_Update = [Select Id, OrderProductLine__c, OrderServiceLine__c, Fulfillment__c, Recipient__c, Primary__c from LineRecipient__c where OrderProductLine__c in :mapOrderLineId_To_fulfillments.keySet() OR OrderServiceLine__c in :mapOrderLineId_To_fulfillments.keySet()];*/
				for (Order_Line_Recipient__c lr : lineRecipient_To_Update){
					lr.Fulfillment__c = mapOrderLineId_To_fulfillments.get(lr.OrderProductLine__c).Id;
        }
        if (!Test.isRunningTest()) {
          update lineRecipient_To_Update;
        }
          
			}

			// system.debug(' ### setFulFillOrderIds_To_Delete ' + setFulFillOrderIds_To_Delete.size()+' => ' + setFulFillOrderIds_To_Delete);
      if (!setFulFillOrderIds_To_Delete.isEmpty())
      if (!Test.isRunningTest()) {
				delete [Select Id
				        from Fulfillment__c
				        where Boom_Order__c in :setFulFillOrderIds_To_Delete];
      }
			system.debug(' ### cancelledOrderIds ' + cancelledOrderIds.size()+' => ' + cancelledOrderIds);

			/** 
			 * * BOOM NOTE:
			 * * segment moved to salesorderhelper in cancelFullfilments
			 */
			if (!cancelledOrderIds.isEmpty()){
				list<Fulfillment__c> fulfillments_To_Update = [Select Id, Status__c
				                                               from Fulfillment__c
				                                               where Boom_Order__c in :cancelledOrderIds];

				for (Fulfillment__c ff : fulfillments_To_Update){
					ff.Status__c = 'Cancelled';
				}

				System.debug('running test? ' + Test.isRunningTest());
				if (!Test.isRunningTest()){
					System.debug('updating fulfillments');
					update fulfillments_To_Update;
				}
			}
		}
	}


	/**
	 * * BOOM NOTE
	 * * OLD METHOD that i copied from
	 */

	// public static void fulFillOrders(map<Id, kugo2p__SalesOrder__c> mapNewSalesOrders, map<Id, kugo2p__SalesOrder__c> mapOldSalesOrders){

	// 	if (mapNewSalesOrders != null && !mapNewSalesOrders.isEmpty()){
	// 		set<Id> setOrderIds = new set<Id>{};
	// 		set<Id> setFulFillOrderIds_To_Delete = new set<Id>{};
	// 		set<Id> cancelledOrderIds = new set<Id>{};

	// 		for (kugo2p__SalesOrder__c so : mapNewSalesOrders.values()){
	// 			if ((Test.isRunningTest() || trigger.isUpdate) && so.FulfillOrder__c != mapOldSalesOrders.get(so.Id).FulfillOrder__c){
	// 				if (so.FulfillOrder__c){
	// 					setOrderIds.add(so.Id);
	// 				} else{
	// 					setFulFillOrderIds_To_Delete.add(so.Id);
	// 				}
	// 			}

	// 			if ((Test.isRunningTest() || trigger.isUpdate) && so.kugo2p__RecordStatus__c == 'Cancelled' && so.kugo2p__RecordStatus__c != mapOldSalesOrders.get(so.Id).kugo2p__RecordStatus__c){
	// 				cancelledOrderIds.add(so.Id);
	// 			}
	// 		}

	// 		system.debug(' ### setOrderIds ' + setOrderIds.size()+' => ' + setOrderIds);
	// 		if (!setOrderIds.isEmpty()){
	// 			list<Fulfillment__c> childFulfillments_To_Insert = new list<Fulfillment__c>();
	// 			map<Id, Fulfillment__c> mapOrderLineId_To_fulfillments = new map<Id, Fulfillment__c>{};
	// 			map<Id, Id> mapOrderLineId_To_PrimaryRecipientId = new map<Id, Id>{};

	// 			//list<LineRecipient__c> lineRecipient_To_Update = [Select Id, OrderProductLine__c, OrderServiceLine__c, Fulfillment__c, Recipient__c, Primary__c from LineRecipient__c where Order__c in : setOrderIds and (OrderProductLine__r.kugo2p__Product__r.CreateOrderFulfillment__c = true OR OrderServiceLine__r.kugo2p__Service__r.CreateOrderFulfillment__c = true)];
	// 			// list<LineRecipient__c> lineRecipient_To_Update = [Select Id, OrderProductLine__c, OrderServiceLine__c, Fulfillment__c, Recipient__c, Primary__c
	// 			                                                  // from LineRecipient__c
  //                                                         // where Order__c in :setOrderIds and ((OrderProductLine__r.kugo2p__Quantity__c > 0 AND OrderProductLine__r.kugo2p__Product__r.CreateOrderFulfillment__c = true) OR (OrderServiceLine__r.kugo2p__Quantity__c > 0 AND OrderServiceLine__r.kugo2p__Service__r.CreateOrderFulfillment__c = true))];
  //       List<LineRecipient__c> lineRecipient_To_Update = fulfillOrdersLineRecipient(setOrderIds);

	// 			for (LineRecipient__c lr : lineRecipient_To_Update){
	// 				if (lr.Primary__c)
	// 					mapOrderLineId_To_PrimaryRecipientId.put(lr.OrderProductLine__c == null ? lr.OrderServiceLine__c : lr.OrderProductLine__c, lr.Recipient__c);
	// 			}

	// 			for (kugo2p__SalesOrderProductLine__c sopl : [select kugo2p__Product__r.Name, kugo2p__Product__r.NumberofOrderFulfillments__c, kugo2p__SalesOrder__c, kugo2p__SalesOrder__r.Market__c
	// 			                                              from kugo2p__SalesOrderProductLine__c
	// 			                                              where kugo2p__SalesOrder__c in :setOrderIds and kugo2p__Product__r.CreateOrderFulfillment__c = true and kugo2p__Quantity__c > 0]){
	// 				mapOrderLineId_To_fulfillments.put(sopl.Id, new Fulfillment__c(OrderNumber__c = sopl.kugo2p__SalesOrder__c, OrderProductLine__c = sopl.Id, OrderServiceLine__c = null, Status__c = 'New Profile', PrimaryRecipient__c = mapOrderLineId_To_PrimaryRecipientId.get(sopl.Id), Product_Name__c = sopl.kugo2p__Product__r.Name, Market__c = sopl.kugo2p__SalesOrder__r.Market__c));

	// 				if (sopl.kugo2p__Product__r.NumberofOrderFulfillments__c > 1){
	// 					for (Integer i = 2; i <= sopl.kugo2p__Product__r.NumberofOrderFulfillments__c; i++){
	// 						childFulfillments_To_Insert.add(mapOrderLineId_To_fulfillments.get(sopl.Id).clone(false, true));
	// 					}
	// 				}
	// 			}

	// 			for (kugo2p__SalesOrderServiceLine__c sosl : [select kugo2p__Service__r.Name, kugo2p__Service__r.NumberofOrderFulfillments__c, kugo2p__SalesOrder__c, kugo2p__SalesOrder__r.Market__c
	// 			                                              from kugo2p__SalesOrderServiceLine__c
	// 			                                              where kugo2p__SalesOrder__c in :setOrderIds and kugo2p__Service__r.CreateOrderFulfillment__c = true and kugo2p__Quantity__c > 0]){
	// 				mapOrderLineId_To_fulfillments.put(sosl.Id, new Fulfillment__c(OrderNumber__c = sosl.kugo2p__SalesOrder__c, OrderProductLine__c = null, OrderServiceLine__c = sosl.Id, Status__c = 'New Profile', PrimaryRecipient__c = mapOrderLineId_To_PrimaryRecipientId.get(sosl.Id), Product_Name__c = sosl.kugo2p__Service__r.Name, Market__c = sosl.kugo2p__SalesOrder__r.Market__c));

	// 				if (sosl.kugo2p__Service__r.NumberofOrderFulfillments__c > 1){
	// 					for (Integer i = 2; i <= sosl.kugo2p__Service__r.NumberofOrderFulfillments__c; i++){
	// 						childFulfillments_To_Insert.add(mapOrderLineId_To_fulfillments.get(sosl.Id).clone(false, true));
	// 					}
	// 				}
	// 			}

	// 			system.debug(' ### mapOrderLineId_To_fulfillments ' + mapOrderLineId_To_fulfillments.size()+' => ' + mapOrderLineId_To_fulfillments);
	// 			if (!Test.isRunningTest()){
	// 				insert mapOrderLineId_To_fulfillments.values();
	// 			}

	// 			if (!childFulfillments_To_Insert.isEmpty()){
	// 				for (Fulfillment__c ff : childFulfillments_To_Insert){
	// 					Id lineId = ff.OrderProductLine__c == null ? ff.OrderServiceLine__c : ff.OrderProductLine__c;

	// 					ff.ParentFulfillment__c = mapOrderLineId_To_fulfillments.get(lineId).Id;
	// 				}

	// 				system.debug(' ### childFulfillments_To_Insert ' + childFulfillments_To_Insert.size()+' => ' + childFulfillments_To_Insert);
	// 				if (!Test.isRunningTest()){
	// 					insert childFulfillments_To_Insert;
	// 				}
	// 			}

	// 			/*list<LineRecipient__c> lineRecipient_To_Update = [Select Id, OrderProductLine__c, OrderServiceLine__c, Fulfillment__c, Recipient__c, Primary__c from LineRecipient__c where OrderProductLine__c in :mapOrderLineId_To_fulfillments.keySet() OR OrderServiceLine__c in :mapOrderLineId_To_fulfillments.keySet()];*/
	// 			for (LineRecipient__c lr : lineRecipient_To_Update){
	// 				lr.Fulfillment__c = mapOrderLineId_To_fulfillments.get(lr.OrderProductLine__c == null ? lr.OrderServiceLine__c : lr.OrderProductLine__c).Id;
  //       }
  //       if (!Test.isRunningTest()) {
  //         update lineRecipient_To_Update;
  //       }
          
	// 		}

	// 		system.debug(' ### setFulFillOrderIds_To_Delete ' + setFulFillOrderIds_To_Delete.size()+' => ' + setFulFillOrderIds_To_Delete);
  //     if (!setFulFillOrderIds_To_Delete.isEmpty())
  //     if (!Test.isRunningTest()) {
	// 			delete [Select Id
	// 			        from Fulfillment__c
	// 			        where OrderNumber__c in :setFulFillOrderIds_To_Delete];
  //     }
	// 		system.debug(' ### cancelledOrderIds ' + cancelledOrderIds.size()+' => ' + cancelledOrderIds);
	// 		if (!cancelledOrderIds.isEmpty()){
	// 			list<Fulfillment__c> fulfillments_To_Update = [Select Id, Status__c
	// 			                                               from Fulfillment__c
	// 			                                               where OrderNumber__c in :cancelledOrderIds];

	// 			for (Fulfillment__c ff : fulfillments_To_Update){
	// 				ff.Status__c = 'Cancelled';
	// 			}

	// 			System.debug('running test? ' + Test.isRunningTest());
	// 			if (!Test.isRunningTest()){
	// 				System.debug('updating fulfillments');
	// 				update fulfillments_To_Update;
	// 			}
	// 		}
	// 	}
	// }

  // this method does not have a dml operation

	/**
	 * * BOOM NOTE
	 * * @name assignLineRecipientAccountManager
	 * * this method does not have a dml operation.
	 * * Account managers are assigned at creation already.
	 */


	// public static void assignLineRecipientAccountManager(list<LineRecipient__c> lineRecipients){

	// 	map<Id, Opportunity> mapOpps = new map<Id, Opportunity>{};
	// 	map<Id, kugo2p__SalesOrder__c> mapOrders = new map<Id, kugo2p__SalesOrder__c>{};

	// 	if (lineRecipients != null && !lineRecipients.isEmpty()){
	// 		for (LineRecipient__c lr : lineRecipients){
	// 			if (lr.AccountManager__c == null)
	// 				mapOrders.put(lr.Order__c, null);
	// 		}

	// 		mapOrders.putAll([Select Id, kugo2p__Opportunity__c, kugo2p__Opportunity__r.Name, kugo2p__Opportunity__r.Contact__c, kugo2p__Opportunity__r.FSP_Sales_Rep__c, kugo2p__Opportunity__r.Market_Project__c
	// 		                  from kugo2p__SalesOrder__c
	// 		                  where Id in :mapOrders.keySet()
	// 		                  FOR  UPDATE ]);
	// 		system.debug(' ### mapOrders ' + mapOrders.size()+' => ' + mapOrders);

	// 		set<Id> marketIds = new set<Id>{};
	// 		set<Id> oppIds = new set<Id>{};
	// 		set<String> oppNames = new set<String>{};

	// 		for (LineRecipient__c lr : lineRecipients){

	// 			kugo2p__SalesOrder__c so = mapOrders.get(lr.Order__c);

	// 			if (lr.AccountManager__c == null && lr.Recipient__c == so.kugo2p__Opportunity__r.Contact__c){
	// 				lr.AccountManager__c = so.kugo2p__Opportunity__r.FSP_Sales_Rep__c;
	// 			}

	// 			if (lr.AccountManager__c == null && so.kugo2p__Opportunity__c != null){
	// 				oppIds.add(so.kugo2p__Opportunity__c);
	// 				oppNames.add(so.kugo2p__Opportunity__r.Name);
	// 				if (so.kugo2p__Opportunity__r.Market_Project__c != null)
	// 					marketIds.add(so.kugo2p__Opportunity__r.Market_Project__c);
	// 			}
	// 		}

	// 		system.debug(' ### oppNames ' + oppNames.size()+' => ' + oppNames);
	// 		system.debug(' ### marketIds ' + marketIds.size()+' => ' + marketIds);
	// 		if (!oppNames.isEmpty()){

	// 			String key;
	// 			map<String, set<Id>> mapOppKey_To_FSPRepIds = new map<String, set<Id>>{};

	// 			for (Opportunity opp : [Select Id, Name, Market_Project__c, Contact__c, FSP_Sales_Rep__c
	// 			                        from Opportunity
	// 			                        Where Id not in :oppIds and Name in :oppNames and Market_Project__c in :marketIds and Contact__c != null and FSP_Sales_Rep__c != null]){
	// 				key = getOppKey(opp.Name, opp.Market_Project__c, opp.Contact__c);

	// 				if (!mapOppKey_To_FSPRepIds.containsKey(key))
	// 					mapOppKey_To_FSPRepIds.put(key, new set<Id>{});
	// 				mapOppKey_To_FSPRepIds.get(key).add(opp.FSP_Sales_Rep__c);
	// 			}

	// 			system.debug(' ### mapOppKey_To_FSPRepIds ' + mapOppKey_To_FSPRepIds.size());
	// 			//system.debug(' ### mapOppKey_To_FSPRepIds ' + mapOppKey_To_FSPRepIds.size() + ' => ' + mapOppKey_To_FSPRepIds);
	// 			for (LineRecipient__c lr : lineRecipients){

	// 				kugo2p__SalesOrder__c so = mapOrders.get(lr.Order__c);
	// 				key = getOppKey(so.kugo2p__Opportunity__r.Name, so.kugo2p__Opportunity__r.Market_Project__c, lr.Recipient__c);

	// 				if (lr.AccountManager__c == null && so.kugo2p__Opportunity__c != null && mapOppKey_To_FSPRepIds.containsKey(key)){
	// 					//system.debug(' ### Line Recipient ' + lr.Recipient__c + ' matches ' + mapOppKey_To_FSPRepIds.get(key).size());
	// 					if (mapOppKey_To_FSPRepIds.get(key).size() == 1){

	// 						for (Id repId : mapOppKey_To_FSPRepIds.get(key)){
	// 							lr.AccountManager__c = repId;
	// 						}
	// 						//system.debug(' ### assigning Rep Id' + lr.AccountManager__c + ' to Line Recipient ' + lr.Recipient__c + ' OrderProductLine__c ' + lr.OrderProductLine__c + ' OrderServiceLine__c ' + lr.OrderServiceLine__c);
	// 					}
	// 				}
	// 			}
	// 		}
	// 	}
	// }




	/**
	 * * BOOM NOTE
	 * * @name getOppKey
	 * * @description i have no idea.
	 * * 
	 */

	// private static String getOppKey(String oppName, Id marketId, Id contactId){
	// 	return oppName + '-' + marketId + '-' + contactId;
	// }


	/**
	 * * BOOM NOTE
	 * * @name deleteFulfillmentAndLineRecipients
	 * * similar methods already exist in SalesOrderProductLineHelper
	 */

	public static void deleteFulfillmentAndLineRecipients(set<Id> soplIds){
		if (soplIds != null && !soplIds.isEmpty()){
			delete [Select Id
			        from Fulfillment__c
			        where Boom_Order_Product_Line__c in :soplIds];  // OR OrderProductLine__r.kugo2p__KitBundleLine__c in :soplIds];
			// delete [Select Id
			//         from Order_Line_Recipient__c
			//         where OrderProductLine__c in :soplIds]; // OR OrderProductLine__r.kugo2p__KitBundleLine__c in :soplIds];
		}
	}

	/**
	 * * ORIGINAL METHOD *
	 */

	// public static void deleteFulfillmentAndLineRecipients(set<Id> soplIds){
	// 	if (soplIds != null && !soplIds.isEmpty()){
	// 		delete [Select Id
	// 		        from Fulfillment__c
	// 		        where OrderProductLine__c in :soplIds];  // OR OrderProductLine__r.kugo2p__KitBundleLine__c in :soplIds];
	// 		delete [Select Id
	// 		        from LineRecipient__c
	// 		        where OrderProductLine__c in :soplIds]; // OR OrderProductLine__r.kugo2p__KitBundleLine__c in :soplIds];
	// 	}
	// }

	private static map<Id, list<SObject>> mapKitHeaderId_To_KitMembers = new map<Id, list<SObject>>{};
	private static map<Id, Fulfillment__c> mapKitMemberId_To_Fulfillment = new map<Id, Fulfillment__c>{};
  private static list<Fulfillment__c> kitMemberChildFulfillments_To_Insert = new list<Fulfillment__c>{};
  

	/**
	 * * BOOM NOTE
	 * *  next two methods are already in the salesorderproduct trigger helper class
	 */

	// public static void createKitMemberFulfillments(map<Id, SalesOrderProductLine__c> mapNewSOPLs){
	// 	if (mapNewSOPLs != null && !mapNewSOPLs.isEmpty()){

	// 		map<Id, kugo2p__SalesOrderProductLine__c> mapSOPLs_To_Process = new map<Id, kugo2p__SalesOrderProductLine__c>{};

	// 		for (kugo2p__SalesOrderProductLine__c sopl : mapNewSOPLs.values()){
	// 			// process Kit Bundle Members only
	// 			if (sopl.kugo2p__KitBundleLine__c != null){
	// 				mapSOPLs_To_Process.put(sopl.Id, null);

	// 				// capture kit member details
	// 				if (!mapKitHeaderId_To_KitMembers.containsKey(sopl.kugo2p__KitBundleLine__c))
	// 					mapKitHeaderId_To_KitMembers.put(sopl.kugo2p__KitBundleLine__c, new list<SObject>{});
	// 				mapKitHeaderId_To_KitMembers.get(sopl.kugo2p__KitBundleLine__c).add(sopl);
	// 			}
	// 		}
	// 		system.debug(' ### mapKitHeaderId_To_KitMembers ' + mapKitHeaderId_To_KitMembers.size()+' => ' + mapKitHeaderId_To_KitMembers);

	// 		if (!mapSOPLs_To_Process.isEmpty()){

	// 			// requery SOPL records to retrieve APD and Order fields
	// 			// mapSOPLs_To_Process.putAll([Select Id, kugo2p__Quantity__c, kugo2p__KitBundleLine__c, kugo2p__Product__c, kugo2p__Product__r.Name, kugo2p__Product__r.CreateOrderFulfillment__c, kugo2p__Product__r.NumberofOrderFulfillments__c, kugo2p__Product__r.RecipientLimit__c, kugo2p__SalesOrder__c, kugo2p__SalesOrder__r.FulfillOrder__c, kugo2p__SalesOrder__r.Market__c
	// 			                            // from kugo2p__SalesOrderProductLine__c
  //                                   // where Id in :mapSOPLs_To_Process.keySet()]);
  //       mapSOPLs_To_Process.putAll(querySalesOrderProductLines(mapSOPLs_To_Process.keySet()));
	// 			system.debug(' ### mapSOPLs_To_Process ' + mapSOPLs_To_Process.size()+' => ' + mapSOPLs_To_Process);

	// 			// creating the Fulfillment records in createKitMemberLineRecipients method (after setting/coping the Primary Recipient from Kit Bundle Header)
	// 			for (kugo2p__SalesOrderProductLine__c sopl : mapSOPLs_To_Process.values()){
	// 				if (sopl.kugo2p__Quantity__c > 0 && sopl.kugo2p__Product__r.CreateOrderFulfillment__c && sopl.kugo2p__SalesOrder__r.FulfillOrder__c){

  //           // setting the Primary Recipient with Kit Bundle Header Primary Recipient in createKitMemberLineRecipients method

	// 					mapKitMemberId_To_Fulfillment.put(sopl.Id, new Fulfillment__c(OrderNumber__c = sopl.kugo2p__SalesOrder__c, OrderProductLine__c = sopl.Id, OrderServiceLine__c = null, Status__c = 'New Profile', Product_Name__c = sopl.kugo2p__Product__r.Name, Market__c = sopl.kugo2p__SalesOrder__r.Market__c));

	// 					if (sopl.kugo2p__Product__r.NumberofOrderFulfillments__c > 1){
	// 						for (Integer i = 2; i <= sopl.kugo2p__Product__r.NumberofOrderFulfillments__c; i++){
	// 							kitMemberChildFulfillments_To_Insert.add(mapKitMemberId_To_Fulfillment.get(sopl.Id).clone(false, true));
	// 						}
	// 					}
	// 				}
	// 			}

	// 			// creating the Fulfillment records in createKitMemberLineRecipients method (after setting/coping the Primary Recipient from Kit Bundle Header)
	// 			//system.debug(' ### mapKitMemberId_To_Fulfillment ' + mapKitMemberId_To_Fulfillment.size() + ' => ' + mapKitMemberId_To_Fulfillment);
	// 			//if (!mapKitMemberId_To_Fulfillment.isEmpty()) insert mapKitMemberId_To_Fulfillment.values();
	// 		}
	// 	}
	// }

	// private static boolean processedKitMemberLineRecipients = false;
	// public static void createKitMemberLineRecipients(list<LineRecipient__c> lineRecipients){

	// 	if (!processedKitMemberLineRecipients && lineRecipients != null && !lineRecipients.isEmpty()){
	// 		processedKitMemberLineRecipients = true;

	// 		list<LineRecipient__c> lineRecipients_To_Insert = new list<LineRecipient__c>{};

	// 		// set Fulfillment Primary Recipient
	// 		for (LineRecipient__c lr : lineRecipients){

	// 			if (lr.Primary__c && mapKitHeaderId_To_KitMembers.containsKey(lr.OrderProductLine__c)){
	// 				for (SObject sobj : mapKitHeaderId_To_KitMembers.get(lr.OrderProductLine__c)){
	// 					if (mapKitMemberId_To_Fulfillment.containsKey(sobj.Id)){
	// 						mapKitMemberId_To_Fulfillment.get(sobj.Id).PrimaryRecipient__c = lr.Recipient__c;
	// 					}
	// 				}
	// 			}
	// 		}

	// 		system.debug(' ### mapKitMemberId_To_Fulfillment ' + mapKitMemberId_To_Fulfillment.size()+' => ' + mapKitMemberId_To_Fulfillment);
	// 		if (!mapKitMemberId_To_Fulfillment.isEmpty() && !Test.isRunningTest())
	// 			insert mapKitMemberId_To_Fulfillment.values();
	// 		if (!kitMemberChildFulfillments_To_Insert.isEmpty()){
	// 			for (Fulfillment__c ff : kitMemberChildFulfillments_To_Insert){
	// 				Id lineId = ff.OrderProductLine__c == null ? ff.OrderServiceLine__c : ff.OrderProductLine__c;

	// 				ff.ParentFulfillment__c = mapKitMemberId_To_Fulfillment.get(lineId).Id;
	// 				ff.PrimaryRecipient__c = mapKitMemberId_To_Fulfillment.get(lineId).PrimaryRecipient__c;
	// 			}

  //       system.debug(' ### kitMemberChildFulfillments_To_Insert ' + kitMemberChildFulfillments_To_Insert.size()+' => ' + kitMemberChildFulfillments_To_Insert);
  //       if (!Test.isRunningTest()) {
  //         insert kitMemberChildFulfillments_To_Insert;
  //       }
	// 		}

	// 		for (LineRecipient__c lr : lineRecipients){

	// 			if (mapKitHeaderId_To_KitMembers.containsKey(lr.OrderProductLine__c)){

	// 				for (SObject sobj : mapKitHeaderId_To_KitMembers.get(lr.OrderProductLine__c)){

	// 					boolean isProduct = sobj.Id.getSobjectType() == Schema.kugo2p__SalesOrderProductLine__c.sObjectType;
	// 					lineRecipients_To_Insert.add(new LineRecipient__c(Order__c = (Id)sobj.get('kugo2p__SalesOrder__c'), OrderProductLine__c = (isProduct ? sobj.Id : null), OrderServiceLine__c = (isProduct ? null : sobj.Id), Recipient__c = lr.Recipient__c, Primary__c = lr.Primary__c, Fulfillment__c = (mapKitMemberId_To_Fulfillment.containsKey(sobj.Id) ? mapKitMemberId_To_Fulfillment.get(sobj.Id).Id : null)));
	// 				}
	// 			}
	// 		}

	// 		system.debug(' ### lineRecipients_To_Insert ' + lineRecipients_To_Insert.size()+' => ' + lineRecipients_To_Insert);
	// 		if (!lineRecipients_To_Insert.isEmpty())
	// 			insert lineRecipients_To_Insert;
	// 	}
	// }


	/**
	 * * BOOM NOTE:
	 * * In SalesORderHelper , queried along with the order prod lines
	 */
	public static List<Order_Line_Recipient__c> fulfillOrdersLineRecipient(Set<Id> ids) {
    return [Select Id, OrderProductLine__c, Fulfillment__c, Recipient__c, Primary__c
    from Order_Line_Recipient__c
    where Order__c in :ids and OrderProductLine__r.Quantity__c > 0 AND OrderProductLine__r.Product__r.CreateOrderFulfillment__c = true];
  }


	/** 
	 * * BOOM NOTE
	 * * No need to revive all of the methods below. We've already recreated them in various triggers
	 */
	

	/**
	 * @name beforeUpdate
	 * @author MK Partners, Inc.
	 * @date 2020-11-25
	 * @param {list<kugo2p__SalesOrder__c>} newList
	 * @param {list<kugo2p__SalesOrder__c>} oldList
	 */
	// public static void beforeUpdate(list<kugo2p__SalesOrder__c> newList, list<kugo2p__SalesOrder__c> oldList){
	// 	if (newList != null && !newList.isEmpty()){
	// 		for (kugo2p__SalesOrder__c so : newList){
	// 			if ( orderNeedsToBeReleased(so) ){
	// 				releaseOrder(so);
	// 			}
	// 		}
	// 	}
	// }

	/**
	 * @name orderNeedsToBeReleased
	 * @author MK Partners, Inc.
	 * @date 2020-11-25
	 * @param kugo2p__SalesOrder__c> so
	 */
	// public static Boolean orderNeedsToBeReleased(kugo2p__SalesOrder__c so){
	// 	return (
	// 		!so.FinanceOverride__c && 
	// 		so.kugo2p__RecordStatus__c == ORDER_STATUS_APPROVED && 
	// 		so.kugo2p__BalanceDueAmount__c <= 0 && (
	// 			so.Complaint_Order__c || (so.kugo2p__TotalAmount__c > 0 && so.kugo2p__AppliedPaymentAmount__c > 0)
	// 		)
	// 	);
	// }


	// public static void autoReleaseOrder(list<kugo2p__SalesOrder__c> salesOrders){
	// 	System.debug('-> AUTO RELEASE ORDER');
	// 	if (salesOrders != null && !salesOrders.isEmpty()){
	// 		// before and after update event is creating duplicate Applied payments (when there are multiple payments on an Order) and hence using a Future method

	// 		list<kugo2p__SalesOrder__c> orders_To_UpdateFulfillments = new list<kugo2p__SalesOrder__c>();
	// 		list<kugo2p__SalesOrder__c> orders_To_Update = new list<kugo2p__SalesOrder__c>();
	// 		List<Id> Order_To_send = new List<Id>();
	// 		Boolean invoiceSent = false;


	// 		for (kugo2p__SalesOrder__c so : salesOrders){
	// 			//if (!so.FinanceOverride__c && so.kugo2p__RecordStatus__c == ORDER_STATUS_APPROVED && so.kugo2p__TotalAmount__c > 0 && so.kugo2p__AppliedPaymentAmount__c > 0 && so.kugo2p__BalanceDueAmount__c <= 0)
	// 			// auto release an Order, if it is a Complaint Order or the Total Amount is fully paid on a normal/regular Order
	// 			if (!so.FinanceOverride__c && so.kugo2p__RecordStatus__c == ORDER_STATUS_APPROVED && so.kugo2p__BalanceDueAmount__c <= 0 && (so.Complaint_Order__c || (so.kugo2p__TotalAmount__c > 0 && so.kugo2p__AppliedPaymentAmount__c > 0))){

  //         // kugo2p__SalesOrder__c newSO = new kugo2p__SalesOrder__c(Id = so.Id, kugo2p__RecordStatus__c = so.kugo2p__RecordStatus__c, Released__c = so.Released__c, Released__c = so.Release_Date__c, FulfillOrder__c = so.FulfillOrder__c);
  //         kugo2p__SalesOrder__c newSO = new kugo2p__SalesOrder__c();
  //         newSO.Id = so.Id;
  //         newSO.kugo2p__RecordStatus__c = so.kugo2p__RecordStatus__c;
  //         newSO.Released__c = so.Released__c;
  //         newSO.Release_Date__c = so.Release_Date__c;
  //         newSO.FulfillOrder__c = so.FulfillOrder__c;

	// 				if (newSO.Email_To_Send__c == true){
	// 					invoiceSent = true;
	// 				}
	// 				releaseOrder(newSO);

	// 				orders_To_Update.add(newSO);
	// 				if (invoiceSent == false){
	// 					Order_To_send.add(newSO.Id);
	// 					System.debug('orders to send' + Order_To_send);
	// 				}

	// 				if (!so.FulfillOrder__c)
	// 					orders_To_UpdateFulfillments.add(new kugo2p__SalesOrder__c(Id = so.Id, FulfillOrder__c = true));
	// 			}
	// 		}

	// 		// Auto Releasing and setting FulfillOrder__c = true in the Future method is throwing an error and hence creating Fulfillment records first and then Releasing the Order in the Future method
  //     if (!orders_To_UpdateFulfillments.isEmpty() && !Test.isRunningTest())
	// 			update orders_To_UpdateFulfillments;
	// 		system.debug(' ### orders_To_Update ' + orders_To_Update.size()+' => ' + orders_To_Update);
	// 		//if (!orders_To_Update.isEmpty()) update orders_To_Update;
	// 		System.debug('-> calling the update orders future method');
	// 		if (!orders_To_Update.isEmpty() && !Test.isRunningTest())
	// 			updateOrders_Future(JSON.serialize(orders_To_Update), Order_To_send);
	// 	}
	// }

	// @future
	// private static void updateOrders_Future(String orderJSONString, List<Id> Order_To_send){
	// 	System.debug('--> update orders future');
	// 	System.debug('orderJSONString: ' + orderJSONString);
	// 	System.debug('list of ids: ');
	// 	System.debug(Order_To_send);
	// 	if (String.isNotBlank(orderJSONString)){
	// 		list<kugo2p__SalesOrder__c> orders_To_Update = (list<kugo2p__SalesOrder__c>)JSON.deserialize(orderJSONString, list<kugo2p__SalesOrder__c>.class);
	// 		if (!Test.isRunningTest())
	// 			update orders_To_Update;
	// 		System.debug('@@@');
	// 		if (!Order_To_send.isEmpty()){
	// 			//OrderInvoiceWithAttachment.sendEmailWithAttachment(Order_To_send);
	// 		}
	// 		System.debug('emaimethodcall');
	// 	}
	// }

	// public static void releaseOrder(kugo2p__SalesOrder__c so){
	// 	System.debug('releasing the order');

	// 	if (so != null){
	// 		so.kugo2p__RecordStatus__c = ORDER_STATUS_RELEASED;
	// 		so.Email_To_Send__c = true;
	// 		so.FulfillOrder__c = true;
	// 		if (so.Released__c == null)
	// 			so.Released__c = system.now();
	// 		if (so.Release_Date__c == null)
	// 			so.Release_Date__c = system.today();
	// 	}
	// }

	// public static void autoReleaseOrder(map<Id, kugo2p__Payment_Profile__c> mapNewRecurringCharges, map<Id, kugo2p__Payment_Profile__c> mapOldRecurringCharges){
	// 	if (mapNewRecurringCharges != null && !mapNewRecurringCharges.isEmpty()){

	// 		map<Id, kugo2p__SalesOrder__c> mapOrders = new map<Id, kugo2p__SalesOrder__c>();
	// 		for (kugo2p__Payment_Profile__c rc : mapNewRecurringCharges.values()){
	// 			if (rc.kugo2p__SalesOrder__c != null && rc.kugo2p__Subscription_Status__c == 'Active' && ((Test.isRunningTest() || trigger.isInsert) || rc.kugo2p__Subscription_Status__c != mapOldRecurringCharges.get(rc.Id).kugo2p__Subscription_Status__c)){

	// 				mapOrders.put(rc.kugo2p__SalesOrder__c, null);
	// 			}
	// 		}

	// 		if (!mapOrders.isEmpty()){
	// 			// mapOrders.putAll([Select Name, kugo2p__RecordStatus__c, Released__c, Release_Date__c, kugo2p__BalanceDueAmount__c, FulfillOrder__c
	// 			//                   from kugo2p__SalesOrder__c
	// 			//                   where Id in :mapOrders.keySet()
  //       //                   FOR  UPDATE ]);
  //       mapOrders.putAll(querySalesOrderForAutoRelease(mapOrders.keyset()));

	// 			system.debug(' ### mapOrders ' + mapOrders.size()+' => ' + mapOrders);

	// 			// AggregateResult[] aggResults = [select kugo2p__SalesOrder__c, SUM(Subscription_Value__c)TotalSubscriptionValue
	// 			//                                 from kugo2p__Payment_Profile__c
	// 			//                                 where kugo2p__SalesOrder__c in :mapOrders.keySet() and kugo2p__Subscription_Status__c = 'Active'
  //       //                                 group by kugo2p__SalesOrder__c];
  //       AggregateResult[] aggResults = aggregatePaymentProfile(mapOrders.keySet());

	// 			map<Id, decimal> mapOrderId_To_TotalSubscriptions = new map<Id, decimal>();
	// 			for (AggregateResult ar : aggResults){
	// 				mapOrderId_To_TotalSubscriptions.put((Id)ar.get('kugo2p__SalesOrder__c'), (decimal)ar.get('TotalSubscriptionValue'));
	// 			}
	// 			system.debug(' ### mapOrderId_To_TotalSubscriptions ' + mapOrderId_To_TotalSubscriptions.size()+' => ' + mapOrderId_To_TotalSubscriptions);

	// 			list<kugo2p__SalesOrder__c> orders_To_Update = new list<kugo2p__SalesOrder__c>();
	// 			for (kugo2p__SalesOrder__c so : mapOrders.values()){
	// 				if (so != null && so.kugo2p__RecordStatus__c == ORDER_STATUS_APPROVED && mapOrderId_To_TotalSubscriptions.get(so.Id) >= so.kugo2p__BalanceDueAmount__c){

	// 					releaseOrder(so);
	// 					orders_To_Update.add(so);
	// 				}
	// 			}

	// 			system.debug(' ### orders_To_Update ' + orders_To_Update.size()+' => ' + orders_To_Update);
	// 			if (!orders_To_Update.isEmpty() && !Test.isRunningTest()){
	// 				update orders_To_Update;
	// 			}
	// 		}
	// 	}
	// }

	// public static void resetOrderReleaseDates(list<kugo2p__SalesOrder__c> salesOrders){
	// 	if (salesOrders != null && !salesOrders.isEmpty()){

	// 		for (kugo2p__SalesOrder__c so : salesOrders){
	// 			if (so.kugo2p__RecordStatus__c != ORDER_STATUS_RELEASED && (so.Released__c != null || so.Release_Date__c != null)){
	// 				so.Released__c = null;
	// 				so.Release_Date__c = null;
	// 			}
	// 		}
	// 	}
	// }

	// // Five Star changes - FS04
	// public static void resetOrderFinanceTerm(list<kugo2p__SalesOrder__c> salesOrders){
	// 	if (salesOrders != null && !salesOrders.isEmpty()){
  //     // if ( nullCheckList(salesOrders) ) {

	// 		for (kugo2p__SalesOrder__c so : salesOrders){
	// 			so.FinanceTerm__c = null;
	// 		}
	// 	}
	// }

	// // Five Star changes - FS04
	// public static void deleteClonedFinanceOrderACC(list<kugo2p__SalesOrderAdditionalChargeCredit__c> orderACCs){
	// 	if (orderACCs != null && !orderACCs.isEmpty()){
  //   // if ( nullCheckList(orderACCs) ) {
	// 		list<kugo2p__SalesOrderAdditionalChargeCredit__c> accs_To_Delete = new list<kugo2p__SalesOrderAdditionalChargeCredit__c>();
	// 		for (kugo2p__SalesOrderAdditionalChargeCredit__c acc : orderACCs){
	// 			if (!processingOrderPaymentSchedule && (acc.kugo2p__AdditionalChargeCredit__c == ManageLinesController.Settings.DefaultFinanceCharge__c || acc.kugo2p__AdditionalChargeCredit__c == ManageLinesController.Settings.DefaultFreeFinancingCredit__c))
	// 				accs_To_Delete.add(new kugo2p__SalesOrderAdditionalChargeCredit__c(Id = acc.Id));
	// 		}

	// 		if (!accs_To_Delete.isEmpty() && !Test.isRunningTest())
	// 			delete accs_To_Delete;
	// 	}
	// }

	// public static void updateLineRecipientCount(list<LineRecipient__c> lineRecipients){
	// 	if (lineRecipients != null && !lineRecipients.isEmpty()){
  //   // if (nullCheckList(lineRecipients)) {
	// 		map<Id, kugo2p__SalesOrderProductLine__c> mapSOPLs = new map<Id, kugo2p__SalesOrderProductLine__c>();
	// 		for (LineRecipient__c lr : lineRecipients){
	// 			if (lr.OrderProductLine__c != null)
	// 				mapSOPLs.put(lr.OrderProductLine__c, new kugo2p__SalesOrderProductLine__c(Id = lr.OrderProductLine__c, Recipient_Count__c = 0));
	// 		}

	// 		//system.debug(' ### mapSOPLs ' + mapSOPLs.size() + ' => ' + mapSOPLs);
	// 		if (!mapSOPLs.isEmpty()){
	// 			// AggregateResult[] aggResults = [select OrderProductLine__c, Count(Id)TotalRecipientCount
	// 			//                                 from LineRecipient__c
	// 			//                                 where OrderProductLine__c in :mapSOPLs.keySet()
  //       //                                 group by OrderProductLine__c];
  //       AggregateResult[] aggResults = aggregateLineReceipients(mapSOPLs.keyset());

	// 			for (AggregateResult ar : aggResults){
	// 				mapSOPLs.get((Id)ar.get('OrderProductLine__c')).Recipient_Count__c = (Integer)ar.get('TotalRecipientCount');
	// 			}

  //       system.debug(' ### mapSOPLs ' + mapSOPLs.size()+' => ' + mapSOPLs);
  //       if (!Test.isRunningTest()) {
  //         update mapSOPLs.values();
  //       }
	// 		}
	// 	}
	// }

	// public static void scheduleSendEmailClass(List<kugo2p__SalesOrder__c> lstNewSalesOrders, map<Id, kugo2p__SalesOrder__c> mapOldSalesOrders){

	// 	if (lstNewSalesOrders != null && !lstNewSalesOrders.isEmpty()){
	// 		FiveStarHelper.processingOrderInvoiceEmailSchedule = true;
	// 		List<Id> soIds = new List<Id>();
	// 		for (kugo2p__SalesOrder__c so : lstNewSalesOrders){
	// 			kugo2p__SalesOrder__c oldSo = mapOldSalesOrders.get(so.Id);
	// 			if (so.Initial_Invoice_Sent__c == false){
	// 				soIds.add(so.Id);
	// 			}
	// 		}
	// 		if (soIds.size() > 0 && !test.isRunningTest())
	// 			OrderInvoiceWithAttachment.sendEmailWithAttachment(soIds);
	// 	}
  // }

  // public static Boolean nullCheckList(List<sObject> sObjectList) {
  //   Integer x = 0;
  //   return sObjectList != null && sObjectList.isEmpty();
  // }
  
  // public static AggregateResult[] aggregateLineReceipients(Set<Id> ids) {
  //   return [
	// 		SELECT OrderProductLine__c, Count(Id)TotalRecipientCount
  //     FROM LineRecipient__c
  //     WHERE OrderProductLine__c in :ids
	// 		GROUP BY OrderProductLine__c
	// 	];
  // }

  // public static AggregateResult[] aggregatePaymentProfile(Set<Id> ids) {
  //   return [
	// 		SELECT kugo2p__SalesOrder__c, SUM(Subscription_Value__c)TotalSubscriptionValue
	// 		FROM kugo2p__Payment_Profile__c
  //   	WHERE kugo2p__SalesOrder__c in :ids and kugo2p__Subscription_Status__c = 'Active'
	// 		GROUP BY kugo2p__SalesOrder__c
	// 	];
  // }

  // public static List<kugo2p__SalesOrder__c> querySalesOrderForAutoRelease(Set<Id> ids) {
  //   return [Select Name, kugo2p__RecordStatus__c, Released__c, Release_Date__c, kugo2p__BalanceDueAmount__c, FulfillOrder__c
  //   from kugo2p__SalesOrder__c
  //   where Id in :ids
  //   FOR  UPDATE ];
  // }

  // public static List<kugo2p__SalesOrderProductLine__c> querySalesOrderProductLines(Set<Id> ids) {
  //   return [Select Id, kugo2p__Quantity__c, kugo2p__KitBundleLine__c, kugo2p__Product__c, kugo2p__Product__r.Name, kugo2p__Product__r.CreateOrderFulfillment__c, kugo2p__Product__r.NumberofOrderFulfillments__c, kugo2p__Product__r.RecipientLimit__c, kugo2p__SalesOrder__c, kugo2p__SalesOrder__r.FulfillOrder__c, kugo2p__SalesOrder__r.Market__c
  //   from kugo2p__SalesOrderProductLine__c
  //   where Id in :ids];
  // }
}