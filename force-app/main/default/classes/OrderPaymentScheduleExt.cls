public with sharing class OrderPaymentScheduleExt {

	public boolean isError					{get; set;}
	public decimal totalAmount				{get; set;}
	public decimal financeCharges			{get; set;}
	public decimal promotionCharges			{get; set;}
	public decimal recurringAmount			{get; set;}
	public String selectedFinanceTerm		{get; set;}	

	// mapping dummySO.kugo2p__ProductDiscountAmount__c to "Initial Amount" on the page
	public kugo2p__SalesOrder__c dummySO 	{get; set;}
	public kugo2p__SalesOrder__c salesOrder {get; set;}

	private Integer selectedFinanceTermVal;
	private decimal initialBalanceDueAmount;
	private kugo2p__SalesOrderAdditionalChargeCredit__c fcAcc;
	private kugo2p__SalesOrderAdditionalChargeCredit__c reverseAcc;
	private decimal financeRate = ManageLinesController.Settings.FinanceRate__c==null ? 0 : ManageLinesController.Settings.FinanceRate__c;
	// Five Star changes - fS04
	private decimal minimumOrderAmount;
	private map<decimal, kuga_FinanceChargeRule__c> mapTerm_To_FinanceChargeRule = new map<decimal, kuga_FinanceChargeRule__c>();

	private ApexPages.StandardController controller;

	public OrderPaymentScheduleExt(ApexPages.StandardController stdCon) {
		isError = false;

		this.controller = stdCon;
		dummySO = new kugo2p__SalesOrder__c();
		this.salesOrder = (kugo2p__SalesOrder__c) stdCon.getRecord();

		if (salesOrder.kugo2p__RecordStatus__c == 'Draft' || salesOrder.kugo2p__RecordStatus__c == 'Sent' || salesOrder.kugo2p__RecordStatus__c == 'Cancelled' || salesOrder.kugo2p__RecordStatus__c == 'Released') {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.Info, 'Finance Order cannot be initiated for Order ' + salesOrder.Name + ' in \'' + salesOrder.kugo2p__RecordStatus__c + '\' status.'));
			isError = true;
			return;
		}

		if (String.isNotBlank(this.salesOrder.FinanceTerm__c)) {
			selectedFinanceTerm = this.salesOrder.FinanceTerm__c;
			setFinanceTermValues();

			// first Payment Schedule record represents Initial Amount and the second represents Recurring Amount.
			list<PaymentSchedule__c> paymentSchedules = [Select Id, Amount__c from PaymentSchedule__c where OrderNumber__c = :this.salesOrder.Id order by DueDate__c Limit 2];
			if (!paymentSchedules.isEmpty()) {
				dummySO.kugo2p__ProductDiscountAmount__c = paymentSchedules[0].Amount__c;
				if (paymentSchedules.size() == 2) recurringAmount = paymentSchedules[1].Amount__c;

				financeCharges = 0;
				promotionCharges = 0;

				for (kugo2p__SalesOrderAdditionalChargeCredit__c soacc : [Select Id, kugo2p__SalesOrder__c, kugo2p__AdditionalChargeCredit__c, kugo2p__AdditionalChargeCredit__r.Name, 
																			  kugo2p__Quantity__c, kugo2p__SalesPrice__c
																		from  kugo2p__SalesOrderAdditionalChargeCredit__c
																		where kugo2p__SalesOrder__c = :this.salesOrder.Id 
																		and   (kugo2p__AdditionalChargeCredit__c = :ManageLinesController.Settings.DefaultFinanceCharge__c
																													OR
																			   kugo2p__AdditionalChargeCredit__c = :ManageLinesController.Settings.DefaultFreeFinancingCredit__c)									
																		]) {

					if (soacc.kugo2p__SalesPrice__c > 0) {
						fcAcc = soacc;
						financeCharges = fcAcc.kugo2p__SalesPrice__c;
					} else {
						reverseAcc = soacc;
						promotionCharges = reverseAcc.kugo2p__SalesPrice__c;
					}
				}

				totalAmount = paymentSchedules[0].Amount__c + (paymentSchedules[1].Amount__c * (selectedFinanceTermVal-1));
				initialBalanceDueAmount = totalAmount - financeCharges - promotionCharges;
				system.debug(' ### totalAmount ' + totalAmount + ' financeCharges ' + financeCharges + ' promotionCharges ' + promotionCharges + ' initialBalanceDueAmount ' + initialBalanceDueAmount);

				// initialize Finance Term Options (FinanceTermOptions) prior to the calculations and after setting initialBalanceDueAmount
				system.assertEquals(FinanceTermOptions.isEmpty(), false);

				// force the calculation to handle "Free Financing Approved" changes
				recalcRecurringAmount();
			}

		} else {

			initialBalanceDueAmount = this.salesOrder.kugo2p__BalanceDueAmount__c==null ? 0 : this.salesOrder.kugo2p__BalanceDueAmount__c;
			system.debug(' ### initialBalanceDueAmount ' + initialBalanceDueAmount);

			// initialize Finance Term Options (FinanceTermOptions) prior to the calculations and after setting initialBalanceDueAmount
			system.assertEquals(FinanceTermOptions.isEmpty(), false);			

			recalcInitialAmount();

			if (FinanceTermOptions.size() == 1) {
				// Five Star changes - fS04
				//ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Order Balance Due Amount must be greater than $300 to Finance Order.'));
				ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Order Balance Due Amount must be greater than $' + minimumOrderAmount + ' to Finance Order.'));
				isError = true;
			}

			if (salesOrder.kugo2p__PaymentStatus2__c == 'Paid') {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Finance Order cannot be initiated because this Order is already paid.'));
				isError = true;
			}
		}
	}

	public pageReference redirect() {

		pageReference retUrl;
		if (!isError && salesOrder.FinanceOverride__c) {
			system.debug(' ### user profile ' + UserInfo.getProfileId());
			if (String.isBlank(ManageLinesController.Settings.FinanceOverrideProfile__c) || !ManageLinesController.Settings.FinanceOverrideProfile__c.contains(UserInfo.getProfileId().left(15))) {

				// Payment Schedule will exists, if Finance Term is not blank and financeCharges > 0
				if (String.isNotBlank(this.salesOrder.FinanceTerm__c) && financeCharges > 0) {
					retUrl = createPaymentProfile();
				} else {
					isError = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Your attempt to Process a Recurring Payment could not be completed because this Order requires a Payment Schedule for Finance Override is Enabled. <br/><br/>Please contact Finance to (1) Create a Payment Schedule or (2) Remove the Finance Override.'));
				}
			}
		}

		return retUrl;
	}

	public list<SelectOption> FinanceTermOptions {
		get {
			if (FinanceTermOptions == null) {
				FinanceTermOptions = new list<SelectOption>{};

				FinanceTermOptions.add(new SelectOption('', '--None--'));

				// Five Star changes - fS04
				for (kuga_FinanceChargeRule__c fcr : [Select kuga_Term__c, kuga_IsFinanceCharged__c, kuga_IsFinanceOverride__c, kuga_MinimumOrderAmount__c, kuga_MinimumInitialPaymentAmount__c 
														from kuga_FinanceChargeRule__c
														order by kuga_Term__c]) {

					if (salesOrder.FinanceOverride__c || initialBalanceDueAmount >= fcr.kuga_MinimumOrderAmount__c) {
						// converted decimal to String by appending an empty string to Term field
						FinanceTermOptions.add(new SelectOption('' + fcr.kuga_Term__c, fcr.kuga_Term__c + ' Months'));

						mapTerm_To_FinanceChargeRule.put(fcr.kuga_Term__c, fcr);
					}
					if (minimumOrderAmount == null || fcr.kuga_MinimumOrderAmount__c < minimumOrderAmount) minimumOrderAmount = fcr.kuga_MinimumOrderAmount__c;
				}
			}
			return FinanceTermOptions;
		}
		private set;
	}

	@testVisible
	private void setFinanceTermValues() {
		if (String.isNotBlank(selectedFinanceTerm)) {
			selectedFinanceTermVal = Integer.valueOf(selectedFinanceTerm);
		}
	}

	private decimal getMinimumPayment() {
		decimal minAmount = 0;

		setFinanceTermValues();

		if (!salesOrder.FinanceOverride__c && String.isNotBlank(selectedFinanceTerm)) {
			system.debug(' ### initialBalanceDueAmount ' + initialBalanceDueAmount + ' selectedFinanceTermVal ' + selectedFinanceTermVal);
			initialBalanceDueAmount = initialBalanceDueAmount==null ? 0 : initialBalanceDueAmount;
			minAmount = (initialBalanceDueAmount / selectedFinanceTermVal).round(System.RoundingMode.CEILING);

			// set/enforce the minimum value
			// Five Star changes - fS04
			/*if (selectedFinanceTermVal == 2 && minAmount < 150) minAmount = 150;
			if (selectedFinanceTermVal > 2 && minAmount < 200) minAmount = 200;*/
			decimal minAmountFromDB = mapTerm_To_FinanceChargeRule.containsKey(selectedFinanceTermVal) ? mapTerm_To_FinanceChargeRule.get(selectedFinanceTermVal).kuga_MinimumInitialPaymentAmount__c : 0;
			if (minAmount < minAmountFromDB) minAmount = minAmountFromDB;
			system.debug(' ### divideBy/selectedFinanceTermVal ' + selectedFinanceTermVal + ' minAmount ' + minAmount);
		}

		return minAmount;
	}

	public void recalcInitialAmount() {

		dummySO.kugo2p__ProductDiscountAmount__c = getMinimumPayment();
		system.debug(' ### dummySO.kugo2p__ProductDiscountAmount__c ' + dummySO.kugo2p__ProductDiscountAmount__c);

		recalcRecurringAmount();
	}

	public void recalcRecurringAmount() {

		financeCharges = 0;
		promotionCharges = 0;
		recurringAmount = 0;
		totalAmount = initialBalanceDueAmount;

		if (String.isNotBlank(selectedFinanceTerm) && validate()) {

			calcFinanceCharges();

			recurringAmount = ((totalAmount - dummySO.kugo2p__ProductDiscountAmount__c) / (selectedFinanceTermVal-1)).setScale(2);
			dummySO.kugo2p__ProductDiscountAmount__c = totalAmount - (recurringAmount * (selectedFinanceTermVal-1));
		}
	}

	private void calcFinanceCharges() {
		// Five Star changes - fS04
		// no financial charges for 1 or 2 Months term; diving annual rate (12%) by 12 to get monthly rate (1%), also exclude the initial payment amount from the finance charges
		//financeCharges = selectedFinanceTermVal <= 2 ? 0 : ( (initialBalanceDueAmount-dummySO.kugo2p__ProductDiscountAmount__c) * (financeRate / 1200) * selectedFinanceTermVal).setScale(2);
		system.debug(' ### selectedFinanceTermVal ' + selectedFinanceTermVal + ' isFinanceCharged ' + mapTerm_To_FinanceChargeRule.get(selectedFinanceTermVal).kuga_IsFinanceCharged__c);
		system.debug(' ### initialBalanceDueAmount ' + initialBalanceDueAmount + ' initial amount ' + dummySO.kugo2p__ProductDiscountAmount__c + ' financeRate ' + financeRate);
		//financeCharges = mapTerm_To_FinanceChargeRule.get(selectedFinanceTermVal).kuga_IsFinanceCharged__c ? ( (initialBalanceDueAmount-dummySO.kugo2p__ProductDiscountAmount__c) * (financeRate / 100) * selectedFinanceTermVal).setScale(2) : 0;
		financeCharges = mapTerm_To_FinanceChargeRule.get(selectedFinanceTermVal).kuga_IsFinanceCharged__c ? ( (initialBalanceDueAmount-dummySO.kugo2p__ProductDiscountAmount__c) * (financeRate / 100) * (ManageLinesController.Settings.kuga_CalculateFinanceRatebyTerm__c ? selectedFinanceTermVal : 1)).setScale(2) : 0;

		//if (salesOrder.FreeFinancingApproved__c) promotionCharges = -1 * financeCharges;
		promotionCharges = salesOrder.FreeFinancingApproved__c ? (-1 * financeCharges) : 0;
		system.debug(' ### financeRate ' + financeRate + ' financeCharges ' + financeCharges + ' promotionCharges ' + promotionCharges);

		calcTotalAmount();
	}

	private void calcTotalAmount() {
		totalAmount = initialBalanceDueAmount + financeCharges + promotionCharges;
	}

	private boolean validate() {
		boolean retVal = true;

		list<kugo2p__Payment_Profile__c> existingProfiles = [Select Id from kugo2p__Payment_Profile__c where kugo2p__SalesOrder__c = :salesOrder.Id and kugo2p__Subscription_Status__c = 'Active'];

		if (String.isBlank(selectedFinanceTerm)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Finance Term must be selected.'));
			retVal = false;
		} else if (!existingProfiles.isEmpty()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Unable to Finance Order due to an existing Active Recurring Charge.'));
			retVal = false;
		} else {

			decimal minAmount = getMinimumPayment();

			if (dummySO.kugo2p__ProductDiscountAmount__c >= initialBalanceDueAmount) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Initial Amount must be less than Balance Due Amount $' + initialBalanceDueAmount.format()));
				retVal = false;
			} else if (dummySO.kugo2p__ProductDiscountAmount__c < minAmount) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Initial Amount must be greater than or equal to the minimum amount $' + minAmount.format()));
				retVal = false;
			}
		}

		return retVal;
	}

	public PageReference savePaymentSchedule() {

		if (validate()) {

			suppressMsg = true;
			deletePaymentSchedule();
			suppressMsg = false;

			list<PaymentSchedule__c> paymentSchedules_To_Insert = new list<PaymentSchedule__c> {
										new PaymentSchedule__c(OrderNumber__c=this.salesOrder.Id, DueDate__c=system.today(), Amount__c=dummySO.kugo2p__ProductDiscountAmount__c)
									};

			system.debug(' ### selectedFinanceTermVal ' + selectedFinanceTermVal);
			for (Integer i=1; i<selectedFinanceTermVal; i++) {
				paymentSchedules_To_Insert.add(new PaymentSchedule__c(OrderNumber__c=this.salesOrder.Id, DueDate__c=system.today().addMonths(i), Amount__c=recurringAmount));
			}

			insert paymentSchedules_To_Insert;
			system.debug(' ### paymentSchedules_To_Insert ' + paymentSchedules_To_Insert.size() + ' => ' + paymentSchedules_To_Insert);

			if (ManageLinesController.Settings.DefaultFinanceCharge__c != null) {

				set<Id> soAccsIds_To_Delete = new set<Id>{};
				list<kugo2p__SalesOrderAdditionalChargeCredit__c> soAccs_To_Upsert = new list<kugo2p__SalesOrderAdditionalChargeCredit__c>{};
				if (financeCharges > 0) {
					if (fcAcc == null) fcAcc = new kugo2p__SalesOrderAdditionalChargeCredit__c(kugo2p__SalesOrder__c=this.salesOrder.Id, kugo2p__AdditionalChargeCredit__c=ManageLinesController.Settings.DefaultFinanceCharge__c, kugo2p__Quantity__c=1);

					// update sales price
					fcAcc.kugo2p__SalesPrice__c = financeCharges;

					soAccs_To_Upsert.add(fcAcc);
					system.debug(' ### fcAcc ' + fcAcc);

				} else if (fcAcc != null && fcAcc.Id != null) {
					// delete ACC record, if there is no Finance Charge
					soAccsIds_To_Delete.add(fcAcc.Id);
					fcAcc = null;
				}

				// promotions
				if (promotionCharges < 0) {
					if (reverseAcc == null) reverseAcc = new kugo2p__SalesOrderAdditionalChargeCredit__c(kugo2p__SalesOrder__c=this.salesOrder.Id, kugo2p__AdditionalChargeCredit__c=ManageLinesController.Settings.DefaultFreeFinancingCredit__c, kugo2p__Quantity__c=1);

					// update sales price
					reverseAcc.kugo2p__SalesPrice__c = promotionCharges;

					soAccs_To_Upsert.add(reverseAcc);
					system.debug(' ### reverseAcc ' + reverseAcc);

					// delete Promotion Acc, if Free Financing is not checked
				} else if (reverseAcc != null && reverseAcc.Id != null) {
					// delete ACC record, if there is no Finance Charge
					soAccsIds_To_Delete.add(reverseAcc.Id);
					reverseAcc = null;
				}

				system.debug(' ### soAccs_To_Upsert ' + soAccs_To_Upsert.size() + ' => ' + soAccs_To_Upsert);
				if (!soAccs_To_Upsert.isEmpty()) {
					// FiveStarHelper.processingOrderPaymentSchedule = true;
					upsert soAccs_To_Upsert;
				}	

				if (!soAccsIds_To_Delete.isEmpty()) delete [Select Id from kugo2p__SalesOrderAdditionalChargeCredit__c where Id in :soAccsIds_To_Delete];
			}

			this.salesOrder.FinanceTerm__c = selectedFinanceTerm;
			update this.salesOrder;

			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Finance Order has been scheduled.'));
		}

		return null;
	}

	private boolean suppressMsg = false;
	public void deletePaymentSchedule() {

		delete [Select Id from PaymentSchedule__c where OrderNumber__c = :salesOrder.Id];

		if (!suppressMsg) {
			if (ManageLinesController.Settings.DefaultFinanceCharge__c != null) {
				delete [Select 	Id
						from 	kugo2p__SalesOrderAdditionalChargeCredit__c 
						where 	kugo2p__SalesOrder__c = :this.salesOrder.Id 
						and 	(kugo2p__AdditionalChargeCredit__c = :ManageLinesController.Settings.DefaultFinanceCharge__c 
																	OR
								kugo2p__AdditionalChargeCredit__c = :ManageLinesController.Settings.DefaultFreeFinancingCredit__c)
						];
			}

			this.salesOrder.FinanceTerm__c = null;
			update this.salesOrder;

			fcAcc = null;
			reverseAcc = null;
			selectedFinanceTerm = '';
			setFinanceTermValues();

			// re-query Sales Order
			this.salesOrder = [Select 	Name, kugo2p__Account__c, kugo2p__ContactBilling__c, kugo2p__RecordStatus__c, kugo2p__PaymentStatus2__c, kugo2p__BalanceDueAmount__c, 
										FinanceOverride__c, FinanceTerm__c, kugo2p__NetAmount__c, FreeFinancingApproved__c 
								from 	kugo2p__SalesOrder__c
								where 	Id = :salesOrder.Id];

			totalAmount = this.salesOrder.kugo2p__BalanceDueAmount__c;
			initialBalanceDueAmount = this.salesOrder.kugo2p__BalanceDueAmount__c==null ? 0 : this.salesOrder.kugo2p__BalanceDueAmount__c;
			recalcInitialAmount();

			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Finance Order has been deleted.'));
		}
	}

	public PageReference createPaymentProfile() {
 
		Id ppcId = [SELECT Id FROM kugo2p__Processor_Connection__c WHERE kugo2p__Processor_Id__c = 'Authorize.Net' order by LastModifiedDate Limit 1].Id;

		kugo2p__Payment_Profile__c rbprofile = new kugo2p__Payment_Profile__c(
			Name = 'Recurring Charges for Order ' + SalesOrder.Name,
			kugo2p__Account__c = SalesOrder.kugo2p__Account__c,
			kugo2p__Contact__c = SalesOrder.kugo2p__ContactBilling__c,
			kugo2p__SalesOrder__c = SalesOrder.Id,
			kugo2p__Amount__c = totalAmount, // pay order's total amount
			kugo2p__Subscription_Status__c = 'Not Activated',
			kugo2p__Processor_Connection__c = ppcId,
			RecordTypeId = Schema.SObjectType.kugo2p__Payment_Profile__c.getRecordTypeInfosByName().get('AuthNet Subscription').getRecordTypeId()
		);

		system.debug(' ### Inserting: '+ rbprofile);
		// Friendly message if no billing contact provided in Order
		if (rbprofile.kugo2p__Contact__c == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.Error, 'Please provide a Billing Contact in your Order.'));
			return new PageReference( Page.kugo2p__RecurringCharge.getUrl() + '?id='+SalesOrder.Id );
		}

		kugo2p.Currencies.assignCurrencyIsoCode(rbprofile, salesOrder);
		insert rbprofile;

		PageReference p = Page.kugo2p__kugAuthNetARBTerminal;
		p.getParameters().put('ppid', rbprofile.Id);

		p.getParameters().put('name', 'Recurring Charges for Order ' + salesOrder.Name);
		p.getParameters().put('startDate', '1');

		p.getParameters().put('frequency', '1');
		p.getParameters().put('period', 'Month');
		p.getParameters().put('occurrences', selectedFinanceTerm);

		p.getParameters().put('trialAmount', (dummySO.kugo2p__ProductDiscountAmount__c==null ? '0' : String.valueOf(dummySO.kugo2p__ProductDiscountAmount__c)));
		p.getParameters().put('amount', (totalAmount==null ? '0' : String.valueOf(totalAmount)));	//recurringAmount

		p.getParameters().put('lock', '1');		

		return p;
	}

	public pageReference saveAndCharge() {
		pageReference retURL;

		if (validate()) {
			savePaymentSchedule();

			retURL = createPaymentProfile();
		}

		return retURL;
	}

	public PageReference cancel() {
		return controller.view();
	}
}