import { LightningElement, api, wire, track } from 'lwc';
import getContacts from '@salesforce/apex/AccountContactListController.getContacts';

export default class AccountContactList extends LightningElement {
    @api recordId;
    @track contacts = [];
    primaryContactName;
    error;

    @wire(getContacts, { accountId: '$recordId' })
    wiredContacts({ data, error }) {
        if (data) {
            this.contacts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    handleMarkPrimary(event) {
        const contactId = event.detail;
        const match = this.contacts.find((c) => c.Id === contactId);
        this.primaryContactName = match ? match.Name : null;
    }
}
