import { LightningElement, api } from 'lwc';

export default class AccountContactRow extends LightningElement {
    @api contact;

    handleClick() {
        this.dispatchEvent(
            new CustomEvent('markprimary', {
                detail: this.contact.Id
            })
        );
    }
}
