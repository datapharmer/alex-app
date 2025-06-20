/**
 * @description This class provides a repository for managing operations related to the `Card__c` custom object,
 *              encapsulating DML logic and event publication for managing card-related mutations.
 *              It handles different triggers (before/after insert, update, delete, undelete) to publish events
 *              or perform actions as needed.
 * @author Open Systems Foundation
 * @date 13-Nov-2024
 */
public class CardDomain {
    /**
     * @description Handles logic to be executed before inserting new Card__c records.
     * @param newList The list of new Card__c records to be inserted.
     */
    public static void handleBeforeInsert(List<Card__c> newList) {
        // Future features can be added here
    }

    /**
     * @description Handles logic to be executed after inserting new Card__c records.
     * @param newList The list of new Card__c records that have been inserted.
     */
    public static void handleAfterInsert(List<Card__c> newList) {
        publishEvents(newList, 'CardCreate');
        countEpicCards(newList, null);
        countColumnCards(newList, null);
    }

    /**
     * @description Handles logic to be executed before updating existing Card__c records.
     * @param newList The list of new Card__c records with updated values.
     * @param oldList The list of old Card__c records with original values before the update.
     */
    public static void handleBeforeUpdate(
        List<Card__c> newList,
        List<Card__c> oldList
    ) {
        // Future features can be added here
    }

    /**
     * @description Handles logic to be executed after updating existing Card__c records.
     *              Publishes events if any relevant field changes are detected.
     * @param newList The list of new Card__c records with updated values.
     * @param oldList The list of old Card__c records with original values before the update.
     * @param oldMap A map of old Card__c records with their Ids as keys and the records as values.
     */
    public static void handleAfterUpdate(
        List<Card__c> newList,
        List<Card__c> oldList,
        Map<Id, Card__c> oldMap
    ) {
        List<CardUpdateEvent__e> events = new List<CardUpdateEvent__e>();
        for (Card__c card : newList) {
            if (hasCardChanged(card, oldMap.get(card.Id))) {
                events.add(createEvent('CardUpdate', card));
            }
        }
        publishEvents(events);
        countEpicCards(newList, oldList);
        countColumnCards(newList, oldList);
    }

    /**
     * @description Handles logic to be executed before deleting Card__c records.
     * @param oldList The list of Card__c records that are about to be deleted.
     */
    public static void handleBeforeDelete(List<Card__c> oldList) {
        // Example logic: Prevent deletion if the card status is 'Locked'
        for (Card__c card : oldList) {
            if (card.Locked__c) {
                card.addError('Locked cards cannot be deleted.');
            }
        }
    }

    /**
     * @description Handles logic to be executed after deleting Card__c records.
     * @param oldList The list of Card__c records that have been deleted.
     */
    public static void handleAfterDelete(List<Card__c> oldList) {
        publishEvents(oldList, 'CardDelete');
        countEpicCards(null, oldList);
        countColumnCards(null, oldList);
    }

    /**
     * @description Handles logic to be executed after undeleting Card__c records.
     * @param newList The list of Card__c records that have been undeleted.
     */
    public static void handleAfterUndelete(List<Card__c> newList) {
        // Future features can be added here
        countEpicCards(newList, null);
        countColumnCards(newList, null);
    }

    /**
     * @description Determines if a Card__c record has changed by comparing relevant fields.
     * @param newCard The new Card__c record after update.
     * @param oldCard The old Card__c record before update.
     * @return Boolean indicating whether relevant fields have changed.
     */
    private static Boolean hasCardChanged(
        Card__c newCard,
        Card__c oldCard
    ) {
        Set<String> fieldsToCompare = new Set<String>{
            'Assignee__c',
            'CardType__c',
            'Color__c',
            'Column__c',
            'Position__c',
            'Priority__c',
            'Status__c',
            'StoryPoints__c',
            'Subject__c'
        };

        for (String field : fieldsToCompare) {
            if (newCard.get(field) != oldCard.get(field)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Creates a CardUpdateEvent__e event based on a given Card__c record and event type.
     * @param eventType The type of event (e.g., 'CardCreate', 'CardUpdate', 'CardDelete').
     * @param card The Card__c record for which the event is being created.
     * @return The CardUpdateEvent__e event object.
     */
    private static CardUpdateEvent__e createEvent(
        String eventType,
        Card__c card
    ) {
        return new CardUpdateEvent__e(
            AssigneeId__c = card.Assignee__c,
            CardColor__c = card.Color__c,
            CardId__c = card.Id,
            CardName__c = card.Name,
            CardPosition__c = card.Position__c,
            CardPriority__c = card.Priority__c,
            CardStatus__c = card.Status__c,
            CardSubject__c = card.Subject__c,
            CardType__c = card.CardType__c,
            ColumnId__c = card.Column__c,
            EventType__c = eventType,
            LastModifiedDate__c = card.LastModifiedDate,
            StoryPoints__c = card.StoryPoints__c
        );
    }

    /**
     * @description Publishes a list of CardUpdateEvent__e events for the given Card__c records.
     * @param cards The list of Card__c records for which events are to be published.
     * @param eventType The type of event to be published.
     */
    private static void publishEvents(
        List<Card__c> cards,
        String eventType
    ) {
        List<CardUpdateEvent__e> events = new List<CardUpdateEvent__e>();
        for (Card__c card : cards) {
            events.add(createEvent(eventType, card));
        }
        publishEvents(events);
    }

    /**
     * @description Publishes a list of CardUpdateEvent__e events to the EventBus.
     * @param events The list of CardUpdateEvent__e events to be published.
     */
    private static void publishEvents(List<CardUpdateEvent__e> events) {
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    /**
     * @description Updates the EpicCardsCount__c on the Epic__c record when the Epic__c field changes on a Card__c.
     * @param newList The list of new Card__c records with updated values.
     * @param oldList The list of old Card__c records with original values before the update.
     */
    public static void countEpicCards(
        List<Card__c> newList,
        List<Card__c> oldList
    ) {
        if (newList == null || oldList == null) {
            return;
        }

        Set<Id> affectedEpicIds = new Set<Id>();
        for (Integer i = 0; i < newList.size(); i++) {
            Card__c newCard = newList[i];
            Card__c oldCard = (oldList.size() > i) ? oldList[i] : null;

            if (
                newCard != null &&
                newCard.Epic__c != oldCard?.Epic__c
            ) {
                if (oldCard?.Epic__c != null) {
                    affectedEpicIds.add(oldCard.Epic__c);
                }
                if (newCard.Epic__c != null) {
                    affectedEpicIds.add(newCard.Epic__c);
                }
            }
        }

        if (affectedEpicIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> epicCardCounts = new Map<Id, Integer>();
        for (Id epicId : affectedEpicIds) {
            epicCardCounts.put(epicId, BoardSelector.countEpicCards(epicId));
        }

        List<Card__c> epicsToUpdate = new List<Card__c>();
        for (Id epicId : affectedEpicIds) {
            epicsToUpdate.add(
                new Card__c(
                    Id = epicId,
                    EpicCardsCount__c = epicCardCounts.containsKey(
                            epicId
                        )
                        ? epicCardCounts.get(epicId)
                        : 0
                )
            );
        }

        if (!epicsToUpdate.isEmpty()) {
            CardRepository.updateCards(epicsToUpdate);
        }
    }

    /**
     * @description Updates the CardCount__c on columns when the Column__c field changes on a Card__c.
     * @param newList The list of new Card__c records with updated values.
     * @param oldList The list of old Card__c records with original values before the update.
     */
    private static void countColumnCards(
        List<Card__c> newList,
        List<Card__c> oldList
    ) {
        Set<Id> affectedColumnIds = new Set<Id>();

        if (newList != null) {
            for (Card__c newCard : newList) {
                if (newCard.Column__c != null) {
                    affectedColumnIds.add(newCard.Column__c);
                }
            }
        }

        if (oldList != null) {
            for (Card__c oldCard : oldList) {
                if (oldCard.Column__c != null) {
                    affectedColumnIds.add(oldCard.Column__c);
                }
            }
        }

        if (affectedColumnIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> columnCardCounts = new Map<Id, Integer>();
        for (Id columnId : affectedColumnIds) {
            columnCardCounts.put(
                columnId,
                BoardSelector.countCardsByColumnId(columnId)
            );
        }

        List<OpenSF__Column__c> columnsToUpdate = new List<OpenSF__Column__c>();
        for (Id columnId : affectedColumnIds) {
            columnsToUpdate.add(
                new OpenSF__Column__c(
                    Id = columnId,
                    OpenSF__CardCount__c = columnCardCounts.containsKey(
                            columnId
                        )
                        ? columnCardCounts.get(columnId)
                        : 0
                )
            );
        }

        if (!columnsToUpdate.isEmpty()) {
            ColumnRepository.updateColumns(columnsToUpdate);
        }
    }
}
