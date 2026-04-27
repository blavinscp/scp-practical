// Seed data for the practical exam.
// Inserting 200 Contacts in one DML will hit SOQL/DML governor limits against
// the unrefactored ContactTrigger -- this is intentional. Once the candidate
// fixes Exercise 1, this script should run cleanly.

List<Account> accounts = ContactTestDataFactory.createAccounts(5);
List<Contact> contacts = ContactTestDataFactory.buildContacts(accounts, 40); // 5 x 40 = 200
insert contacts;

System.debug('Seeded ' + accounts.size() + ' accounts and ' + contacts.size() + ' contacts.');
