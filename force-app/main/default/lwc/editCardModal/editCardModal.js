import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import KanbanStore from 'c/kanbanBoardStore';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';

const ZERO = 0;

export default class EditCardModal extends LightningElement {
    @api cardId;
    @api cardName;
    @api boardId;
    objectApiName = 'Card__c';
    results;
    errors;

    fields = [];
    fallbackFields = [
        'Subject__c',
        'Status__c',
        'Epic__c',
        'Assignee__c',
        'CardType__c',
        'StoryPoints__c',
        'Priority__c',
        'Color__c'
    ];

    @wire(graphql, {
        query: gql`
            query CustomMetadataByDeveloperName {
                uiapi {
                    query {
                        boardSettings: KanbanBoardSettings__mdt(
                            where: { DeveloperName: { eq: "Modal_Settings" } }
                        ) {
                            edges {
                                node {
                                    Id
                                    developerName: DeveloperName {
                                        value
                                    }
                                    fieldNames: FieldNames__c {
                                        value
                                    }
                                }
                            }
                        }
                    }
                }
            }
        `
    })
    loadCustomMetadata({ errors, data }) {
        if (data) {
            const customMetadataNode =
                data.uiapi.query.boardSettings.edges[ZERO]?.node;

            if (customMetadataNode) {
                const fieldNames = customMetadataNode.fieldNames?.value;
                this.fields = fieldNames
                    ? fieldNames.split(',').map((field) => field.trim())
                    : [];
            }
        }

        if (errors || !this.fields.length) {
            this.fields = [...this.fallbackFields];
            if (errors) {
                this.showToasts(
                    'Error',
                    'Failed to load custom metadata, using default fields',
                    'error'
                );
            }
        }
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBackdropClick(event) {
        if (event.target === event.currentTarget) {
            this.closeModal();
        }
    }

    handleSuccess(event) {
        const updatedCardData = this.extractCardData(event);

        try {
            KanbanStore.updateCard(this.boardId, updatedCardData);
            this.showToasts('Success', 'Card updated successfully', 'success');
        } catch (error) {
            this.showToasts('Error', 'Error updating card in backend', 'error');
        }

        this.closeModal();
    }

    extractCardData(event) {
        const {
            Assignee__c: { value: assigneeId },
            Color__c: { value: cardColor },
            CardType__c: { value: cardType },
            Priority__c: { value: cardPriority },
            Status__c: { value: cardStatus },
            StoryPoints__c: { value: storyPoints },
            Subject__c: { value: cardSubject }
        } = event.detail.fields;

        return {
            assigneeId,
            cardColor,
            cardId: this.cardId,
            cardPriority,
            cardStatus,
            cardSubject,
            cardType,
            storyPoints
        };
    }

    handleDelete() {
        try {
            if (this.cardId) {
                KanbanStore.deleteCard(this.boardId, this.cardId);
                deleteRecord(this.cardId);
                this.showToasts(
                    'Success',
                    'Card deleted successfully',
                    'success'
                );
            } else {
                throw new Error('No cardId provided');
            }
        } catch (error) {
            this.showToasts(
                'Error',
                `Error deleting card: ${error.message}`,
                'error'
            );
        } finally {
            this.closeModal();
        }
    }

    showToasts(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}
