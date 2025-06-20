/**
 * @description This class provides utility methods for creating test data for Board__c, Column__c, and Card__c records.
 * It is used to facilitate unit testing by generating the necessary data setup.
 * @author Open Systems Foundation
 * @date 13-Nov-2024
 */
@isTest
public class TestDataFactory {
    /**
     * @description Create a test Board__c record with the specified name.
     *
     * @param name The name of the board.
     * @return The created Board__c record.
     */
    public static Board__c createBoard(String name) {
        Board__c board = new Board__c(Name = name);
        insert board;
        return board;
    }

    /**
     * @description Create a test Column__c record for a specific board.
     *
     * @param boardId The Id of the board.
     * @return The created Column__c record.
     */
    public static Column__c createColumn(Id boardId) {
        Column__c column = new Column__c(
            Board__c = boardId,
            Position__c = 1 // Set a default position
        );
        insert column;
        return column;
    }

    /**
     * @description Create multiple test Column__c records for a specific board.
     *
     * @param boardId The Id of the board.
     * @param count The number of columns to create.
     * @return A list of created Column__c records.
     */
    public static List<Column__c> createColumns(
        Id boardId,
        Integer count
    ) {
        List<Column__c> columns = new List<Column__c>();
        for (Integer i = 1; i <= count; i++) {
            columns.add(
                new Column__c(
                    Board__c = boardId,
                    Position__c = i
                )
            );
        }
        insert columns;
        return columns;
    }

    /**
     * @description Create a test Card__c record for a specific column with the specified position.
     *
     * @param columnId The Id of the column.
     * @param position The position of the card.
     * @return The created Card__c record.
     */
    public static Card__c createCard(Id columnId, Integer position) {
        Card__c card = new Card__c(
            Column__c = columnId,
            Position__c = position
        );
        insert card;
        return card;
    }

    /**
     * @description Create a test Card__c record of type 'Epic'.
     *
     * @return The created Card__c record of type 'Epic'.
     */
    public static Card__c createEpic() {
        Card__c epicCard = new Card__c(
            CardType__c = 'Epic'
        );
        insert epicCard;
        return epicCard;
    }

    /**
     * @description Create multiple test Card__c records for a specific column.
     *
     * @param columnId The Id of the column.
     * @param count The number of cards to create.
     * @return A list of created Card__c records.
     */
    public static List<Card__c> createCards(
        Id columnId,
        Integer count
    ) {
        List<Card__c> cards = new List<Card__c>();
        for (Integer i = 1; i <= count; i++) {
            cards.add(
                new Card__c(
                    Column__c = columnId,
                    Position__c = i
                )
            );
        }
        insert cards;
        return cards;
    }

    /**
     * @description Create a Standard Profile User and assign the AlexAdmin permission set.
     *
     * @return The created User record.
     */
    public static User createStandardUser() {
        Profile p = [
            SELECT Id
            FROM Profile
            LIMIT 1
        ];
        User user = new User(
            Alias = 'stduser',
            Email = 'standarduser' +
                System.currentTimeMillis() +
                '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser' +
                System.currentTimeMillis() +
                '@example.com'
        );
        insert user;

        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Alex_Admin'
            LIMIT 1
        ];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        return user;
    }
}
