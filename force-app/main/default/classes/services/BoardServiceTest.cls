@isTest
public class BoardServiceTest {
    @testSetup
    static void setupTestData() {
        User user = TestDataFactory.createStandardUser();
        System.runAs(user) {
            // Set up a board with columns and cards for testing
            Board__c board = TestDataFactory.createBoard('Test Board');
            Column__c column1 = TestDataFactory.createColumn(board.Id);
            Column__c column2 = TestDataFactory.createColumn(board.Id);

            // Create cards in the columns
            TestDataFactory.createCards(column1.Id, 3);
            TestDataFactory.createCards(column2.Id, 2);
        }
    }

    @isTest
    static void testGetBoardData() {
        // Retrieve the board created in testSetup
        Board__c board = [SELECT Id FROM Board__c LIMIT 1];

        // Test getBoardData method
        Map<String, Object> result = BoardService.getBoardData(board.Id);
        System.assertNotEquals(null, result, 'Expected non-null result');
        System.assert(result.containsKey('board'), 'Expected board in result');
        System.assert(
            result.containsKey('columns'),
            'Expected columns in result'
        );
        System.assert(result.containsKey('cards'), 'Expected cards in result');

        List<Column__c> columns = (List<Column__c>) result.get(
            'columns'
        );
        System.assertEquals(2, columns.size(), 'Expected 2 columns');

        List<Card__c> cards = (List<Card__c>) result.get(
            'cards'
        );
        System.assertEquals(5, cards.size(), 'Expected 5 cards across columns');
    }

    @isTest
    static void testMoveCard() {
        // Retrieve all cards created in testSetup
        List<Card__c> cards = [
            SELECT Id, Column__c, Position__c
            FROM Card__c
            ORDER BY Position__c ASC
            LIMIT 5
        ];
        System.assertEquals(5, cards.size(), 'Expected 5 cards for move test');

        // Move a card to a new position in the same column
        Card__c movedCard = cards[0];
        movedCard.Position__c = 2;

        Test.startTest();
        List<Card__c> updatedCards = BoardService.moveCard(movedCard);
        Test.stopTest();

        // Verify positions were updated
        for (Card__c card : updatedCards) {
            if (card.Id == movedCard.Id) {
                System.assertEquals(
                    2,
                    card.Position__c,
                    'Expected moved card position to be 2'
                );
            }
        }
    }

    @isTest
    static void testMoveCardToDifferentColumn() {
        // Retrieve two columns created in testSetup
        List<Column__c> columns = [
            SELECT Id
            FROM Column__c
            LIMIT 2
        ];
        Column__c sourceColumn = columns[0];
        Column__c targetColumn = columns[1];

        // Retrieve a card from the source column
        List<Card__c> sourceCards = [
            SELECT Id, Column__c, Position__c
            FROM Card__c
            WHERE Column__c = :sourceColumn.Id
            LIMIT 1
        ];
        Card__c movedCard = sourceCards[0];
        movedCard.Column__c = targetColumn.Id;
        movedCard.Position__c = 1;

        Test.startTest();
        BoardService.moveCard(movedCard);
        Test.stopTest();

        // Verify that positions in the target column are adjusted
        List<Card__c> targetCards = [
            SELECT Id, Position__c
            FROM Card__c
            WHERE Column__c = :targetColumn.Id
            ORDER BY Position__c ASC
        ];
        for (Integer i = 0; i < targetCards.size(); i++) {
            System.assertEquals(
                i + 1,
                targetCards[i].Position__c,
                'Expected card position to be sequential'
            );
        }
    }

    @isTest
    static void testCreateCard() {
        // Retrieve a column for adding a new card
        Column__c column = [SELECT Id FROM Column__c LIMIT 1];

        // Create a new card in the column
        Test.startTest();
        Card__c newCard = BoardService.createCard(column.Id, 'Backlog');
        Test.stopTest();

        // Verify the card was created
        System.assertNotEquals(null, newCard, 'Expected new card');
        System.assertEquals(
            column.Id,
            newCard.Column__c,
            'Expected column ID to match'
        );
    }

    @isTest
    static void testUpdateCards() {
        // Retrieve all cards created in testSetup
        List<Card__c> cards = [
            SELECT Id, Column__c, Position__c
            FROM Card__c
            LIMIT 5
        ];
        System.assertEquals(
            5,
            cards.size(),
            'Expected 5 cards for update test'
        );

        // Modify some card positions
        cards[0].Position__c = 3;
        cards[1].Position__c = 2;

        // Update card positions using BoardService
        Test.startTest();
        List<Card__c> updatedCards = BoardService.updateCards(cards);
        Test.stopTest();

        // Verify positions were updated
        for (Card__c card : updatedCards) {
            System.assertNotEquals(
                null,
                card.Position__c,
                'Expected non-null position'
            );
        }
    }
}
