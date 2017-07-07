/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Salesforce.org
 * @date 2017
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Test class to validate behavior changes related to TDTM Static Flag handling
 *
***/
@isTest
private class TDTM_DMLgt200_TEST {

    private static Integer insertCnt = 210;

    /*********************************************************************************************************
    * @description Test creating 200+ Contacts with Affiliations
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @isTest
    static void test_contacts_with_affiliations() {

        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
                new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));

        Id orgRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Organization' AND IsActive = True LIMIT 1].Id;
        Account orgAcct = new Account(Name='TestOrganization', RecordTypeId = orgRTId);
        insert orgAcct;

        Test.startTest();

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        List<Contact> contacts = new List<Contact>();
        for (Integer n=0; n<insertCnt; n++) {
            contacts.add(new Contact(
                    FirstName = 'TEST' + n,
                    LastName = 'Test1000X-' + n,
                    Title = 'TestTitle'
            ));
        }
        database.insert(contacts);
        system.AssertEquals(insertCnt, [SELECT Count() FROM Account WHERE RecordType.DeveloperName = 'HH_Account'],
                'There should be exactly ' + insertCnt.format() + ' Household Account records');

        // Create Affiliation records for every Contact, setting the IsPrimary field to true
        // NOTE: To test a WFR update on this, a WFR to check the IsPrimary field could be used.
        List<npe5__Affiliation__c> affls = new List<npe5__Affiliation__c>();
        for (Contact c : contacts) {
            npe5__Affiliation__c affl = new npe5__Affiliation__c(
                    npe5__Organization__c = orgAcct.Id,
                    npe5__Contact__c = c.Id,
                    npe5__Primary__c = True,
                    npe5__Status__c = system.label.npe5.DefaultCurrentStatus
            );
            affls.add(affl);
        }
        database.insert(affls);
        Test.stopTest();
        system.AssertEquals(insertCnt, [SELECT Count() FROM npe5__Affiliation__c WHERE npe5__Organization__c = :orgAcct.Id],
                'There should be exactly ' + insertCnt.format() + ' Affiliations records');
        system.AssertEquals(insertCnt, [SELECT Count() FROM Contact WHERE Primary_Affiliation__c = :orgAcct.Id],
                'There should be exactly ' + insertCnt.format() + ' Contacts with a Primary Affilition');
    }


    /*********************************************************************************************************
    * @description Test creating 200+ Contacts with a Primary Affiliations
    */
    @isTest
    static void test_contacts_with_primary_affiliations() {

        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
                new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));

        Id orgRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Organization' AND IsActive = True LIMIT 1].Id;
        Account orgAcct = new Account(Name='TestOrganization', RecordTypeId = orgRTId);
        insert orgAcct;

        Test.startTest();

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        // as well as all the related Affiliation recorsd
        List<Contact> contacts = new List<Contact>();
        for (Integer n=0; n<insertCnt; n++) {
            contacts.add(new Contact(
                    FirstName = 'TEST' + n,
                    LastName = 'Test1000X-' + n,
                    Title = 'TestTitle',
                    Primary_Affiliation__c = orgAcct.Id
            ));
        }
        database.insert(contacts);
        Test.stopTest();
        system.AssertEquals(insertCnt, [SELECT Count() FROM Account WHERE RecordType.DeveloperName = 'HH_Account'],
                'There should be exactly ' + insertCnt.format() + ' Household Account records');
        system.AssertEquals(insertCnt, [SELECT Count() FROM npe5__Affiliation__c WHERE npe5__Organization__c = :orgAcct.Id],
                'There should be exactly ' + insertCnt.format() + ' Affiliations records');
        system.AssertEquals(insertCnt, [SELECT Count() FROM Contact WHERE Primary_Affiliation__c = :orgAcct.Id],
                'There should be exactly ' + insertCnt.format() + ' Contacts with a Primary Affilition');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ Contacts with Relationships
    */
    @isTest
    static void test_contacts_with_relationships() {

        Test.startTest();

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        List<Contact> contacts = new List<Contact>();
        for (Integer n=0; n<insertCnt; n++) {
            contacts.add(new Contact(
                    FirstName = 'TEST' + n,
                    LastName = 'Test1000X-' + n,
                    Title = 'TestTitle'
            ));
        }
        database.insert(contacts);
        system.AssertEquals(insertCnt, [SELECT Count() FROM Account WHERE RecordType.DeveloperName = 'HH_Account'],
                'There should be exactly ' + insertCnt.format() + ' Household Account records');

        // Create Relationships between the Contacts
        List<npe4__Relationship__c> rels =  new List<npe4__Relationship__c>();
        for (Integer n=0; n<insertCnt; n++) {
            Contact c1 = contacts[n];
            Contact c2 = contacts[insertCnt - n - 1];
            npe4__Relationship__c rel = new npe4__Relationship__c(
                    npe4__Contact__c = c1.Id,
                    npe4__RelatedContact__c = c2.Id,
                    npe4__Type__c = 'Spouse',
                    npe4__Description__c = 'InsertTest'
            );
            rels.add(rel);
        }
        database.insert(rels);
        Test.stopTest();
        system.AssertEquals(insertCnt*2, [SELECT Count() FROM npe4__Relationship__c
        WHERE npe4__Contact__c IN :contacts AND npe4__Type__c = 'Spouse'],
                'There should be exactly ' + (insertCnt*2).format() + ' Relationships');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ Opportunities with a default allocation through a Campaign
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @isTest
    static void test_opportunities_with_default_alloc() {

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;
        c = [SELECT Id, AccountId FROM Contact WHERE Id = :c.Id LIMIT 1];

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(
                Name = 'TestGAU',
                Active__c = True
        );
        insert gau;

        Campaign camp = new Campaign(Name = 'UNITTEST', IsActive = True);
        insert camp;

        Allocation__c campAlloc = new Allocation__c(
                Campaign__c = camp.Id,
                General_Accounting_Unit__c = gau.Id,
                Percent__c = 100
        );
        insert campAlloc;

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c(
                Default_Allocations_Enabled__c = true, Default__c = gau.Id));

        ALLO_Allocations_TDTM.resetFlags(false);

        Test.startTest();

        // Create 200+ Opportunity Records
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer n=0; n<insertCnt; n++) {
            opps.add(new Opportunity(
                    Name = 'MASS INSERT TEST ' + n,
                    Primary_Contact__c = c.Id,
                    CloseDate = Date.Today().addMonths(1),
                    Amount = 100,
                    CampaignId = camp.Id,
                    StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
            ));
        }
        database.insert(opps);
        Test.stopTest();
        system.AssertEquals(insertCnt, [SELECT Count() FROM Allocation__c
        WHERE Opportunity__c IN :opps],
                'There should be exactly ' + insertCnt.format() + ' default Allocations');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ Recurring Donations each with 2 installments.
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @isTest
    static void test_recurring_donations() {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new npe03__Recurring_Donations_Settings__c(
                        npe03__Opportunity_Forecast_Months__c = 6,
                        npe03__Maximum_Donations__c = 2,
                        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()
                ));

        Test.startTest();

        // Insert the RecurringDonation records
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        for (Integer n=0; n<insertCnt; n++) {
            rds.add(new npe03__Recurring_Donation__c(
                    Name = 'MASS INSERT TEST ' + n,
                    npe03__Installments__c = 2,
                    npe03__Contact__c = c.Id,
                    npe03__Amount__c = 100,
                    npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly,
                    npe03__Date_Established__c = date.newinstance(1970,6,12),
                    npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue,
                    npe03__Open_Ended_Status__c = 'None'
            ));
        }
        database.insert(rds);
        Test.stopTest();

        system.AssertEquals(insertCnt*2, [SELECT Count() FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :rds],
                'There should be exactly ' + (insertCnt*2).format() + ' Installment Opps');
    }
}