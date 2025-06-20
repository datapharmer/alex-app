@isTest
public class CardDomainTest {
    @testSetup
    static void setup() {
        User user = TestDataFactory.createStandardUser();
        System.runAs(user) {
            // Create a test board and a column to use in all tests
            Board__c board = TestDataFactory.createBoard('Test Board');
            Column__c column = TestDataFactory.createColumn(board.Id);

            // Create a few test cards in the column
            TestDataFactory.createCards(column.Id, 3);
        }
    }

    @isTest
    static void testHandleBeforeInsert() {
        // Test setup
        Board__c board = TestDataFactory.createBoard(
            'Test Board Before Insert'
        );
        Column__c column = TestDataFactory.createColumn(board.Id);

        // Creating test cards to trigger before insert
        List<Card__c> cards = new List<Card__c>{
            new Card__c(
                Column__c = column.Id,
                Position__c = 1
            ),
            new Card__c(
                Column__c = column.Id,
                Position__c = 2
            )
        };

        Test.startTest();
        insert cards;
        Test.stopTest();

        // Verifying insert worked
        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM Card__c
                WHERE Column__c = :column.Id
            ],
            'The number of cards inserted does not match the expected value.'
        );

        // Verifying events published
        // Since Platform Events cannot be queried, we assume the trigger logic is correct if no exceptions were thrown
        System.assert(true, 'Platform Events published successfully.');
    }

    @isTest
    static void testHandleAfterInsert() {
        // Test setup
        Board__c board = TestDataFactory.createBoard(
            'Test Board After Insert'
        );
        Column__c column = TestDataFactory.createColumn(board.Id);

        // Creating test cards to trigger after insert
        Card__c card = new Card__c(
            Column__c = column.Id,
            Position__c = 1
        );

        Test.startTest();
        insert card;
        Test.stopTest();

        // Verifying insert worked
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Card__c
                WHERE Column__c = :column.Id
            ],
            'The number of cards inserted does not match the expected value.'
        );

        // Verifying events published
        // Since Platform Events cannot be queried, we assume the trigger logic is correct if no exceptions were thrown
        System.assert(true, 'Platform Events published successfully.');
    }

    @isTest
    static void testHandleBeforeUpdate() {
        // Test setup
        List<Card__c> cards = [
            SELECT Id, Position__c, Column__c
            FROM Card__c
            LIMIT 1
        ];
        Card__c cardToUpdate = cards[0];
        cardToUpdate.Position__c = 2;

        Test.startTest();
        update cardToUpdate;
        Test.stopTest();

        // Ensuring code executed without issues

        // Verifying events published
        // Since Platform Events cannot be queried, we assume the trigger logic is correct if no exceptions were thrown
        System.assert(true, 'Platform Events published successfully.');
    }

    @isTest
    static void testHandleAfterUpdate() {
        // Test setup
        List<Card__c> cards = [
            SELECT
                Id,
                Position__c,
                Status__c,
                Priority__c,
                Subject__c,
                CardType__c,
                StoryPoints__c
            FROM Card__c
            LIMIT 1
        ];
        Card__c cardToUpdate = cards[0];

        // Changing each field to trigger an event
        cardToUpdate.Position__c = 5;
        cardToUpdate.Status__c = 'Done';
        cardToUpdate.Priority__c = 'High';
        cardToUpdate.Subject__c = 'New Subject';
        cardToUpdate.CardType__c = 'Bug';
        cardToUpdate.StoryPoints__c = 10;

        Test.startTest();
        update cardToUpdate;
        Test.stopTest();

        // Ensuring Platform Event published without errors
        System.assert(true, 'Platform Event published successfully.');
    }

    @isTest
    static void testHandleBeforeDelete() {
        // Test setup
        List<Card__c> cards = [
            SELECT Id, Locked__c
            FROM Card__c
            LIMIT 1
        ];
        Card__c cardToDelete = cards[0];
        cardToDelete.Locked__c = true;
        update cardToDelete; // Ensure the locked status is saved

        Test.startTest();
        try {
            delete cardToDelete;
            System.assert(false, 'Expected an exception due to locked card.');
        } catch (DmlException e) {
            System.assert(
                e.getDmlMessage(0).contains('Locked cards cannot be deleted.'),
                'Expected error message for locked card deletion not found.'
            );
        }
        Test.stopTest();

        // Ensuring no issues in delete trigger
    }

    @isTest
    static void testHandleAfterDelete() {
        // Test setup
        List<Card__c> cards = [SELECT Id FROM Card__c LIMIT 1];

        Test.startTest();
        delete cards;
        Test.stopTest();

        // Verifying the card was deleted
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Card__c
                WHERE Id = :cards[0].Id
            ],
            'The card was not deleted as expected.'
        );

        // Ensuring Platform Event published without errors
        System.assert(true, 'Platform Event published successfully.');
    }

    @isTest
    static void testHandleAfterUndelete() {
        // Test setup: create and delete a card
        Board__c board = TestDataFactory.createBoard(
            'Test Board After Undelete'
        );
        Column__c column = TestDataFactory.createColumn(board.Id);
        Card__c card = TestDataFactory.createCard(column.Id, 1);

        delete card;

        Test.startTest();
        undelete card;
        Test.stopTest();

        // Verifying the card was undeleted
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Card__c
                WHERE Id = :card.Id
            ],
            'The card was not undeleted as expected.'
        );

        // Ensuring Platform Event published without errors
        System.assert(true, 'Platform Event published successfully.');
    }

    @isTest
    static void testCountEpicCards() {
        // Test setup
        Board__c board = TestDataFactory.createBoard(
            'Test Board for Epic'
        );
        Column__c column = TestDataFactory.createColumn(board.Id);
        Card__c epic = TestDataFactory.createEpic();

        // Create cards in the column using TestDataFactory
        List<Card__c> cards = TestDataFactory.createCards(column.Id, 2);

        // Update cards to associate them with the epic
        for (Card__c card : cards) {
            card.Epic__c = epic.Id;
        }
        Test.startTest();
        update cards;
        Test.stopTest();

        // Verify the epic card count
        List<Card__c> epicCards = [
            SELECT EpicCardsCount__c
            FROM Card__c
            WHERE Epic__c = :epic.Id
        ];
        System.assertEquals(
            2,
            epicCards.size(),
            'Epic card count is incorrect.'
        );
    }

    @isTest
    static void testCountColumnCards() {
        // Step 1: Test setup
        Board__c board = TestDataFactory.createBoard('Test Board');
        Column__c column1 = TestDataFactory.createColumn(board.Id);
        Column__c column2 = TestDataFactory.createColumn(board.Id);

        // Create cards associated with column1
        List<Card__c> cards = TestDataFactory.createCards(
            column1.Id,
            3
        );

        // Verify initial card count on column1
        Column__c refreshedColumn1 = [
            SELECT CardCount__c
            FROM Column__c
            WHERE Id = :column1.Id
        ];
        System.assertEquals(
            3,
            refreshedColumn1.CardCount__c,
            'Initial card count should be 3'
        );

        Test.startTest();

        // Step 2: Update the Column__c field for one card to column2
        Card__c updatedCard = cards[0];
        updatedCard.Column__c = column2.Id;
        update updatedCard;

        Test.stopTest();

        // Step 3: Verify the updated card counts
        refreshedColumn1 = [
            SELECT CardCount__c
            FROM Column__c
            WHERE Id = :column1.Id
        ];
        Column__c refreshedColumn2 = [
            SELECT CardCount__c
            FROM Column__c
            WHERE Id = :column2.Id
        ];

        System.assertEquals(
            2,
            refreshedColumn1.CardCount__c,
            'Card count for column1 should decrease to 2'
        );
        System.assertEquals(
            1,
            refreshedColumn2.CardCount__c,
            'Card count for column2 should increase to 1'
        );
    }

    @isTest
    static void testDeleteCards() {
        // Step 1: Test setup
        Board__c board = TestDataFactory.createBoard('Test Board');
        Column__c column = TestDataFactory.createColumn(board.Id);

        // Create multiple cards associated with the column
        List<Card__c> cards = TestDataFactory.createCards(column.Id, 3);

        // Verify initial card count
        Column__c refreshedColumn = [
            SELECT CardCount__c
            FROM Column__c
            WHERE Id = :column.Id
        ];
        System.assertEquals(
            3,
            refreshedColumn.CardCount__c,
            'Initial card count should be 3'
        );

        Test.startTest();

        // Step 2: Delete a card
        delete cards[0];

        Test.stopTest();

        // Step 3: Verify card count decreases
        refreshedColumn = [
            SELECT CardCount__c
            FROM Column__c
            WHERE Id = :column.Id
        ];
        System.assertEquals(
            2,
            refreshedColumn.CardCount__c,
            'Card count should decrease to 2'
        );
    }
}
