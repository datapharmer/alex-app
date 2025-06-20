/**
 * @description This class provides services related to Board operations, encapsulating business logic for managing board-related data and operations.
 * @author Open Systems Foundation
 * @date 13-Nov-2024
 */
public with sharing class BoardService {
    /**
     * @description Fetches board data along with its columns and cards.
     * @param boardId - The Id of the board to fetch data for.
     * @return A Map<String, Object> containing the board, columns, and cards.
     * @throws AuraHandledException if the board is not found.
     */
    public static Map<String, Object> getBoardData(Id boardId) {
        Map<String, Object> result = new Map<String, Object>();

        Board__c board = BoardSelector.getBoardById(boardId);
        if (board != null) {
            result.put('board', board);
        } else {
            throw new AuraHandledException('Board not found');
        }

        List<Column__c> columns = BoardSelector.getColumnsByBoardId(boardId);
        result.put('columns', columns);

        Set<Id> columnIds = new Set<Id>();
        for (Column__c column : columns) {
            columnIds.add(column.Id);
        }

        if (!columnIds.isEmpty()) {
            List<Card__c> cards = BoardSelector.getCardsByColumnIds(columnIds);
            result.put('cards', cards);
        }

        return result;
    }

    /**
     * @description Processes a moved card and performs necessary operations, including updating the card position and re-ordering columns.
     * @param movedCard - A card object to be processed.
     * @return A List<Card__c> of updated cards after the move.
     * @throws AuraHandledException if card validation fails or DML operations fail.
     */
    public static List<Card__c> moveCard(Card__c movedCard) {
        // Validate the moved card
        validateMovedCard(movedCard);

        // Retrieve the current state of the card from the database
        Card__c currentCard = BoardSelector.getCardById(movedCard.Id);

        // Initialize a map for cards to update to ensure uniqueness
        Map<Id, Card__c> cardsToUpdateMap = new Map<Id, Card__c>();
        cardsToUpdateMap.put(currentCard.Id, currentCard);

        // Fetch source column cards based on the current column
        List<Card__c> sourceColumnCards = BoardSelector.getCardsByColumnId(
            currentCard.Column__c
        );

        // Check if the column has changed
        Boolean isColumnChanged =
            currentCard.Column__c != movedCard.Column__c;
        Integer targetPosition = (Integer) movedCard.Position__c;
        Id targetColumnId = movedCard.Column__c;

        // Fetch target column cards if the column has changed
        List<Card__c> targetColumnCards = isColumnChanged
            ? BoardSelector.getCardsByColumnId(targetColumnId)
            : new List<Card__c>();

        // Update the current card's column and position
        currentCard.Column__c = targetColumnId;
        currentCard.Position__c = targetPosition;

        // Adjust positions in the target column if needed
        if (isColumnChanged) {
            adjustPositionsInTargetColumn(
                targetColumnCards,
                targetPosition,
                cardsToUpdateMap
            );
        }

        // Adjust positions in the source column
        adjustPositionsInSourceColumn(
            sourceColumnCards,
            movedCard.Id,
            cardsToUpdateMap
        );

        // Ensure the movedCard is updated with its latest values
        cardsToUpdateMap.put(currentCard.Id, currentCard); // Update with the latest moved card values

        // Perform a single update with all the changes using unique values from the map
        try {
            CardRepository.updateCards(cardsToUpdateMap.values());
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Failed to update card positions: ' + e.getMessage()
            );
        }

        // Retrieve updated Cards
        List<Card__c> updatedCards = BoardSelector.getCardsByColumnIds(
            new Set<Id>{
                currentCard.Column__c,
                movedCard.Column__c
            }
        );

        return updatedCards;
    }

    /**
     * @description Validates that the moved card has a valid Id.
     * @param movedCard - The card to validate.
     * @throws AuraHandledException if the card Id is null.
     */
    private static void validateMovedCard(Card__c movedCard) {
        if (movedCard.Id == null) {
            throw new AuraHandledException('No card Id provided for update.');
        }
    }

    /**
     * @description Adjusts the positions of cards in the target column to accommodate the moved card.
     * @param targetColumnCards - List of cards in the target column.
     * @param targetPosition - The new position for the moved card.
     * @param cardsToUpdateMap - A map of cards to be updated.
     */
    private static void adjustPositionsInTargetColumn(
        List<Card__c> targetColumnCards,
        Integer targetPosition,
        Map<Id, Card__c> cardsToUpdateMap
    ) {
        for (Card__c card : targetColumnCards) {
            if (card.Position__c >= targetPosition) {
                card.Position__c += 1;
                cardsToUpdateMap.put(card.Id, card);
            }
        }
    }

    /**
     * @description Adjusts the positions of cards in the source column after a card has been moved out.
     * @param sourceColumnCards - List of cards in the source column.
     * @param movedCardId - The Id of the moved card.
     * @param cardsToUpdateMap - A map of cards to be updated.
     */
    private static void adjustPositionsInSourceColumn(
        List<Card__c> sourceColumnCards,
        Id movedCardId,
        Map<Id, Card__c> cardsToUpdateMap
    ) {
        Integer newPos = 0;
        for (Card__c card : sourceColumnCards) {
            if (card.Id != movedCardId) {
                card.Position__c = newPos;
                newPos++;
                cardsToUpdateMap.put(card.Id, card);
            }
        }
    }

    /**
     * @description Creates a new card in the specified column with the given status.
     * @param columnId - The Id of the column to add the card to.
     * @param columnStatus - The status to assign to the new card.
     * @return The newly created Card__c record.
     * @throws AuraHandledException if columnId is invalid or card creation fails.
     */
    public static Card__c createCard(Id columnId, String columnStatus) {
        if (columnId == null) {
            throw new AuraHandledException('Invalid columnId for new card.');
        }

        // Create new card with position 1
        Card__c card = new Card__c();
        card.Status__c = columnStatus;
        card.Column__c = columnId;
        card.Position__c = BoardSelector.getMaxCardPosition(columnId) + 1;

        try {
            CardRepository.createCard(card);
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Failed to create card: ' + e.getMessage()
            );
        }

        // Retrieve updated Card
        return BoardSelector.getCardById(card.Id);
    }

    /**
     * @description Updates a list of cards with the provided fields.
     * @param updateCards - List of Card__c objects with updated fields.
     * @return The updated list of Card__c records.
     * @throws AuraHandledException if no cards are provided or DML operations fail.
     */
    public static List<Card__c> updateCards(List<Card__c> updateCards) {
        validateCards(updateCards);

        // Perform the update
        performUpdate(updateCards);

        // Retrieve updated Cards
        return retrieveUpdatedCards(updateCards);
    }

    private static void validateCards(List<Card__c> cards) {
        if (cards == null || cards.isEmpty()) {
            throw new AuraHandledException('No cards provided for update.');
        }

        for (Card__c card : cards) {
            if (card.Id == null) {
                throw new AuraHandledException(
                    'Card Id is required for update.'
                );
            }
        }
    }

    private static void performUpdate(List<Card__c> cards) {
        try {
            CardRepository.updateCards(cards);
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Failed to update cards: ' + e.getMessage()
            );
        }
    }

    private static List<Card__c> retrieveUpdatedCards(List<Card__c> cards) {
        Set<Id> cardIds = new Set<Id>();
        for (Card__c card : cards) {
            cardIds.add(card.Id);
        }
        return BoardSelector.getCardsById(cardIds);
    }
}
