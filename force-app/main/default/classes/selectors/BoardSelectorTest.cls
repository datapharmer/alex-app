@isTest
public class BoardSelectorTest {
    @testSetup
    static void setupTestData() {
        User user = TestDataFactory.createStandardUser();
        System.runAs(user) {
            // Create a test board
            Board__c board = TestDataFactory.createBoard('Test Board');

            // Create two columns for this board
            Column__c column1 = TestDataFactory.createColumn(board.Id);
            Column__c column2 = TestDataFactory.createColumn(board.Id);

            // Create cards for each column
            TestDataFactory.createCards(column1.Id, 3); // 3 cards in column1
            TestDataFactory.createCards(column2.Id, 2); // 2 cards in column2
        }
    }

    @isTest
    static void testGetBoardById() {
        // Get a test board
        Board__c board = [SELECT Id FROM Board__c LIMIT 1];

        // Fetch the board using BoardSelector
        Board__c fetchedBoard = BoardSelector.getBoardById(board.Id);

        // Verify the board is fetched correctly
        System.assertNotEquals(null, fetchedBoard, 'Board should be fetched.');
        System.assertEquals(
            board.Id,
            fetchedBoard.Id,
            'Fetched board ID should match the test board ID.'
        );
    }

    @isTest
    static void testGetColumnsByBoardId() {
        // Get a test board
        Board__c board = [SELECT Id FROM Board__c LIMIT 1];

        // Fetch columns associated with the board
        List<Column__c> columns = BoardSelector.getColumnsByBoardId(
            board.Id
        );

        // Verify the columns are fetched correctly
        System.assertEquals(
            2,
            columns.size(),
            'There should be two columns associated with the board.'
        );
        for (Column__c column : columns) {
            System.assertEquals(
                board.Id,
                column.Board__c,
                'Each column should be associated with the correct board.'
            );
        }
    }

    @isTest
    static void testGetCardsByColumnIds() {
        // Fetch column IDs for the test board
        List<Column__c> columns = [
            SELECT Id
            FROM Column__c
            LIMIT 2
        ];
        Set<Id> columnIds = new Set<Id>();
        for (Column__c column : columns) {
            columnIds.add(column.Id);
        }

        // Fetch cards associated with these column IDs
        List<Card__c> cards = BoardSelector.getCardsByColumnIds(
            columnIds
        );

        // Verify that cards are fetched correctly
        System.assertEquals(
            5,
            cards.size(),
            'There should be 5 cards in total across the two columns.'
        );
        for (Card__c card : cards) {
            System.assert(
                columnIds.contains(card.Column__c),
                'Each card should belong to one of the specified columns.'
            );
        }
    }

    @isTest
    static void testGetCardsByColumnId() {
        // Get a single column Id
        Column__c column = [SELECT Id FROM Column__c LIMIT 1];

        // Fetch cards in this column
        List<Card__c> cards = BoardSelector.getCardsByColumnId(
            column.Id
        );

        // Verify cards are fetched correctly
        System.assertEquals(
            3,
            cards.size(),
            'There should be 3 cards in this column.'
        );
        for (Card__c card : cards) {
            System.assertEquals(
                column.Id,
                card.Column__c,
                'Each card should belong to the specified column.'
            );
        }
    }

    @isTest
    static void testGetCardById() {
        // Get a single card Id
        Card__c card = [SELECT Id FROM Card__c LIMIT 1];

        // Fetch the card by ID
        Card__c fetchedCard = BoardSelector.getCardById(card.Id);

        // Verify the card is fetched correctly
        System.assertNotEquals(null, fetchedCard, 'Card should be fetched.');
        System.assertEquals(
            card.Id,
            fetchedCard.Id,
            'Fetched card ID should match the test card ID.'
        );
    }

    @isTest
    static void testGetCardsById() {
        // Fetch card IDs for the test board
        List<Card__c> cards = [SELECT Id FROM Card__c LIMIT 2];
        Set<Id> cardIds = new Set<Id>();
        for (Card__c card : cards) {
            cardIds.add(card.Id);
        }

        // Fetch cards by IDs
        List<Card__c> fetchedCards = BoardSelector.getCardsById(
            cardIds
        );

        // Verify that cards are fetched correctly
        System.assertEquals(
            cardIds.size(),
            fetchedCards.size(),
            'The number of fetched cards should match the number of card IDs.'
        );
        for (Card__c card : fetchedCards) {
            System.assert(
                cardIds.contains(card.Id),
                'Each fetched card should have an ID from the specified card IDs.'
            );
        }
    }

    @isTest
    static void testGetMaxCardPosition() {
        // Get a single column Id
        Column__c column = [SELECT Id FROM Column__c LIMIT 1];

        // Ensure the column is empty
        delete [
            SELECT Id
            FROM Card__c
            WHERE Column__c = :column.Id
        ];

        // Fetch the maximum card position in this column
        Integer maxPosition = BoardSelector.getMaxCardPosition(column.Id);

        // Verify the maximum position is fetched correctly
        System.assertEquals(
            0,
            maxPosition,
            'The maximum card position should be 0 for a new column with no cards.'
        );

        // Create a card in this column with a specific position
        Card__c card = new Card__c(
            Column__c = column.Id,
            Position__c = 1
        );
        insert card;

        // Fetch the maximum card position again
        maxPosition = BoardSelector.getMaxCardPosition(column.Id);

        // Verify the maximum position is updated correctly
        System.assertEquals(
            1,
            maxPosition,
            'The maximum card position should be 1 after inserting a card with position 1.'
        );

        // Create another card in this column with a higher position
        Card__c card2 = new Card__c(
            Column__c = column.Id,
            Position__c = 5
        );
        insert card2;

        // Fetch the maximum card position again
        maxPosition = BoardSelector.getMaxCardPosition(column.Id);

        // Verify the maximum position is updated correctly
        System.assertEquals(
            5,
            maxPosition,
            'The maximum card position should be 5 after inserting a card with position 5.'
        );
    }

    @isTest
    static void testCountCardsByColumnId() {
        // Get a single column Id
        Column__c column = [SELECT Id FROM Column__c LIMIT 1];

        // Count the number of cards in this column
        Integer cardCount = BoardSelector.countCardsByColumnId(column.Id);

        // Verify the card count is correct
        System.assertEquals(
            3,
            cardCount,
            'There should be 3 cards in this column.'
        );

        // Create another card in this column
        Card__c card = new Card__c(
            Column__c = column.Id,
            Position__c = 4
        );
        insert card;

        // Count the number of cards in this column again
        cardCount = BoardSelector.countCardsByColumnId(column.Id);

        // Verify the card count is updated correctly
        System.assertEquals(
            4,
            cardCount,
            'There should be 4 cards in this column after inserting another card.'
        );
    }
}
