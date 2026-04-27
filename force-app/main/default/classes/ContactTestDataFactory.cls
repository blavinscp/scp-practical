/**
 * Helper used by the seed script and (optionally) by candidate test classes.
 */
public with sharing class ContactTestDataFactory {

    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Practical Exam Account ' + i,
                BillingState = (Math.mod(i, 2) == 0) ? 'CA' : 'NY'
            ));
        }
        insert accounts;
        return accounts;
    }

    public static List<Contact> buildContacts(List<Account> accounts, Integer perAccount) {
        List<Contact> contacts = new List<Contact>();
        for (Account a : accounts) {
            for (Integer i = 0; i < perAccount; i++) {
                contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = a.Name + ' #' + i,
                    AccountId = a.Id
                ));
            }
        }
        return contacts;
    }
}
