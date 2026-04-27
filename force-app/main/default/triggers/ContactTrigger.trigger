trigger ContactTrigger on Contact (after insert) {
    for (Contact c : Trigger.new) {
        if (c.AccountId != null) {
            Account a = [SELECT Id, Contact_Count__c FROM Account WHERE Id = :c.AccountId LIMIT 1];
            if (a.Contact_Count__c == null) {
                a.Contact_Count__c = 0;
            }
            a.Contact_Count__c = a.Contact_Count__c + 1;
            update a;
        }
    }
}
