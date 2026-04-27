public with sharing class AccountContactListController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(Id accountId) {
        return [
            SELECT Id, Name, Email, Title
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastName
            LIMIT 50
        ];
    }
}
