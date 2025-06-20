@isTest
public class ColumnRepositoryTest {
    @testSetup
    static void setupTestData() {
        User user = TestDataFactory.createStandardUser();
        System.runAs(user) {
            Board__c board = TestDataFactory.createBoard('Test Board');
            insert new Column__c(
                Board__c = board.Id,
                ColumnHeader__c = 'Test Column',
                Position__c = 1
            );
        }
    }

    @isTest
    static void testCreateColumn() {
        // Arrange
        Board__c board = TestDataFactory.createBoard('Test Board');

        // Act
        Test.startTest();
        Column__c createdColumn = ColumnRepository.createColumn(
            new Column__c(
                Board__c = board.Id,
                ColumnHeader__c = 'New Column',
                Position__c = 1
            )
        );
        Test.stopTest();

        // Assert
        System.assertNotEquals(
            null,
            createdColumn.Id,
            'Column ID should not be null after creation'
        );
        System.assertEquals(
            board.Id,
            createdColumn.Board__c,
            'Column should belong to the correct board'
        );
        System.assertEquals(
            'New Column',
            createdColumn.ColumnHeader__c,
            'Column header should match the input value'
        );
    }

    @isTest
    static void testUpdateColumns() {
        // Arrange
        Board__c board = TestDataFactory.createBoard('Test Board');
        List<Column__c> columns = new List<Column__c>();
        for (Integer i = 0; i < 3; i++) {
            columns.add(
                new Column__c(
                    Board__c = board.Id,
                    ColumnHeader__c = 'Column ' + i,
                    Position__c = i
                )
            );
        }
        insert columns;

        // Modify column positions
        for (Integer i = 0; i < columns.size(); i++) {
            columns[i].Position__c = i + 10;
        }

        // Act
        Test.startTest();
        ColumnRepository.updateColumns(columns);
        Test.stopTest();

        // Reload columns from the database to verify update
        List<Column__c> updatedColumns = [
            SELECT Id, Position__c
            FROM Column__c
            WHERE Id IN :columns
        ];

        // Assert
        for (Integer i = 0; i < updatedColumns.size(); i++) {
            System.assertEquals(
                i + 10,
                updatedColumns[i].Position__c,
                'Column position should be updated correctly'
            );
        }
    }
}
