@isTest
public with sharing class ERR_Handler_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    /*** We need to use Database.insert because otherwise the code does not pass the contacts insert
         in the test itself. A record gets inserted just because the name field for accounts was not
         retrieved. This happens in the second pass of the Database.insert ***/
    public testmethod static void errorsStoredInDbTdtmCustomConfig() {
    	if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDbTdtmCustomConfig') return;
    	
    	insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ERR_ParentAccountUpdater_TEST', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;');
    	            
    	//Create account
    	Account acc1 = new Account(Name='test1');
    	Account acc2 = new Account(Name='test2');
    	Account acc3 = new Account(Name='test3');
        insert new Account[] {acc1, acc2, acc3};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get ERR_ParentAccountUpdater_TEST code to throw an exception
        delete acc2;
        
        Test.startTest();
	    List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
	    LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        //If a non-dml error occurs we rolled the whole thing back, and flag all message as having errors.
        //(Unfortunately we cannot check (and assert) the error messages added.)
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess()); 

        //Verify 2 contacts were properly inserted
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size()); 
        
        //Verify error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c];
        System.assertEquals(1, errors.size()); 
    }
    
    /** To prove that there are different types of null pointer exceptions. In this case the account
    name is always available. The error does not get stored because the second time that Database.insert 
    runs there are no errors. **/
    public testmethod static void errorsStoredInDbTdtmCustomConfig2() {
        if (strTestOnly != '*' && strTestOnly != 'errorsStoredInDbTdtmCustomConfig') return;
        
        insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ERR_ParentAccountUpdater2_TEST', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;');
                    
        //Create account
        Account acc1 = new Account(Name='test1');
        Account acc2 = new Account(Name='test2');
        Account acc3 = new Account(Name='test3');
        insert new Account[] {acc1, acc2, acc3};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get ERR_ParentAccountUpdater_TEST code to throw an exception
        delete acc2;
        
        Test.startTest();
        List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
        LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        //If a non-dml error occurs we rolled the whole thing back, and flag all message as having errors.
        //(Unfortunately we cannot check (and assert) the error messages added.)
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess());

        //Verify 2 contacts were properly inserted
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size()); 
        
        //Verify error record was created
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c];
        System.assertEquals(0, errors.size()); 
    }
    
    /** Test using the default configuration of classes that implement TDTM_Runnable **/
    public testmethod static void errorStoredInDbTdtmStandardConfig() {
    	if (strTestOnly != '*' && strTestOnly != 'errorStoredInDbTdtmStandardConfig') return;
    
        AFFL_Affiliations_TEST.getAffiliationsSettingsForTests(new npe5__Affiliations_Settings__c(
                                           npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
                    
        //Create account
        Account acc1 = new Account(Name='test1');
        Account acc2 = new Account(Name='test2');
        Account acc3 = new Account(Name='test3');
        insert new Account[] {acc1, acc2, acc3};
        
        //Create contact
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', AccountId = acc1.Id, Title = 'VP1');
        Contact contact2 = new Contact(FirstName = 'test', LastName = 'testerson2', AccountId = acc2.Id, Title = 'VP2');
        Contact contact3 = new Contact(FirstName = 'test', LastName = 'testerson3', AccountId = acc3.Id, Title = 'VP3');

        //Delete the account to get the affiliations code to throw an exception
        delete acc2;
        
        Test.startTest();
        List<Contact> contacts = new Contact[]{contact1, contact2, contact3};
        LIST<database.SaveResult> results = Database.insert(contacts, false);
        Test.stopTest();
        
        //If a non-dml error occurs we rolled the whole thing back, and flag all message as having errors.
        //(Unfortunately we cannot check (and assert) the error messages added.)
        System.assertEquals(true, results[0].isSuccess());  
        System.assertEquals(false, results[1].isSuccess()); 
        System.assertEquals(true, results[2].isSuccess()); 

        //Verify 2 contacts were properly inserted
        list<Contact> insertedContacts = [select Id from Contact where Id in :contacts];
        System.assertEquals(2, insertedContacts.size()); 
        
        //Verify error record was created -> Nope. Since we are using Database insert the operation
        //gets rolled back and then run again only with records that succeed. No error is saved.
        List<Error__c> errors = [select Id, Full_Message__c, Stack_Trace__c from Error__c];
        System.assertEquals(0, errors.size());                                    
    }
    
    /** This is the same test called testErrorRecordCreation in the REL_Relationships_TEST class, but
        using simple insert instead of Database.insert ***/
    static testMethod void errorStoredInDatabaseFromInsert() {
        if (strTestOnly != '*' && strTestOnly != 'errorStoredInDatabaseFromInsert') return;
        
        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', Title = 'VP1');
        insert contact1;
                
        npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = contact1.id, npe4__Type__c='TestLookupType') };
        
        insert relationships;
        //assert an error record was created - Required fields are missing: [npe4__Contact__c]
        system.assertEquals(1, [select count() from Error__c]);
        
        //update relationship - this will create the missing npe4__Contact__c field
        relationships[0].npe4__RelatedContact__c = contact1.id;
        Database.SaveResult[] updateResults = Database.update(relationships, false);
        
        //process error
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processResults(null, updateResults, null, null, null, (List<SObject>)relationships, null, null);

        //assert no additional error was created on update
        system.assertEquals(1, [select count() from Error__c]);
    }
}