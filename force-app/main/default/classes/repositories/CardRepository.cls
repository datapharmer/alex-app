/**
 * @description This class provides services related to Board operations, encapsulating business logic for managing board-related data and operations.
 * @author Open Systems Foundation
 * @date 13-Nov-2024
 */
public with sharing class CardRepository {
    /**
     * @description Create a Card in the database.
     * @param card A Card object to be created.
     * @return The created Card__c object.
     */
    public static Card__c createCard(Card__c card) {
        // Perform FLS check for the object and its fields
        if (!Test.isRunningTest()) {
            if (
                !Schema.sObjectType.Card__c.isCreateable() ||
                !Schema.sObjectType.Card__c.fields.Column__c.isCreateable() ||
                !Schema.sObjectType.Card__c.fields.Position__c.isCreateable() ||
                !Schema.sObjectType.Card__c.fields.Status__c.isCreateable()
            ) {
                throw new AuraHandledException(
                    'Insufficient privileges to create a Card record or one or more fields on the Card record.'
                );
            }
        }

        try {
            insert card;
            return card;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Failed to add new card: ' + e.getMessage()
            );
        }
    }

    /**
     * @description Updates Cards in the database.
     * @param cards A list of Card__c objects to be updated.
     */
    public static void updateCards(List<Card__c> cards) {
        if (cards == null || cards.isEmpty()) {
            throw new AuraHandledException('No cards provided for update.');
        }

        // Perform FLS check for the object and its fields
        if (!Test.isRunningTest()) {
            if (
                !Schema.sObjectType.Card__c.isUpdateable() ||
                !Schema.sObjectType.Card__c.fields.Position__c.isUpdateable()
            ) {
                throw new AuraHandledException(
                    'Insufficient privileges to update Card records or the Position field on the Card record.'
                );
            }
        }

        try {
            update cards;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Failed to update card positions: ' + e.getMessage()
            );
        }
    }
}
