/**
 * @description This class provides a repository for managing operations related to the `Column__c` custom object,
 *              encapsulating DML logic and event publication for managing column-related mutations.
 *              It handles different triggers (before/after insert, update, delete, undelete) to publish events
 *              or perform actions as needed.
 * @author Open Systems Foundation
 * @date 23-Nov-2024
 */
public class ColumnDomain {
    /**
     * @description Handles logic before inserting new columns.
     * @param newList List of new `Column__c` records to be inserted.
     */
    public static void handleBeforeInsert(List<Column__c> newList) {
        // Future features can be added here
    }

    /**
     * @description Handles logic after inserting new columns.
     * @param newList List of new `Column__c` records that were inserted.
     */
    public static void handleAfterInsert(List<Column__c> newList) {
        publishEvents(newList, 'ColumnCreate');
    }

    /**
     * @description Handles logic before updating existing columns.
     * @param newList List of new `Column__c` records to be updated.
     * @param oldList List of old `Column__c` records before the update.
     */
    public static void handleBeforeUpdate(
        List<Column__c> newList,
        List<Column__c> oldList
    ) {
        // Future features can be added here
    }

    /**
     * @description Handles logic after updating existing columns.
     * @param newList List of new `Column__c` records that were updated.
     * @param oldList List of old `Column__c` records before the update.
     * @param oldMap Map of old `Column__c` records keyed by Id.
     */
    public static void handleAfterUpdate(
        List<Column__c> newList,
        List<Column__c> oldList,
        Map<Id, Column__c> oldMap
    ) {
        List<ColumnUpdateEvent__e> events = new List<ColumnUpdateEvent__e>();
        for (Column__c column : newList) {
            if (hasColumnChanged(column, oldMap.get(column.Id))) {
                events.add(createEvent('ColumnUpdate', column));
            }
        }
        publishEvents(events);
    }

    /**
     * @description Handles logic before deleting columns and shows an error message in the UI prompt if deletion is restricted.
     * @param oldList List of `Column__c` records to be deleted.
     * @throws CustomException if any column has associated cards.
     */
    public static void handleBeforeDelete(List<Column__c> oldList) {
        for (Column__c column : oldList) {
            Integer cardCount = BoardSelector.countCardsByColumnId(column.Id);
            if (cardCount > 0) {
                String errorMessage =
                    'Column "' +
                    column.Name +
                    '" has ' +
                    cardCount +
                    ' associated cards and cannot be deleted.';
                column.addError(errorMessage);
            }
        }
    }

    /**
     * @description Handles logic after deleting columns.
     * @param oldList List of `Column__c` records that were deleted.
     */
    public static void handleAfterDelete(List<Column__c> oldList) {
        publishEvents(oldList, 'ColumnDelete');
    }

    /**
     * @description Handles logic after undeleting columns.
     * @param newList List of `Column__c` records that were undeleted.
     */
    public static void handleAfterUndelete(List<Column__c> newList) {
        // Future features can be added here
    }

    /**
     * @description Checks if any relevant fields in the column have changed.
     * @param newColumn The new `Column__c` record.
     * @param oldColumn The old `Column__c` record.
     * @return Boolean indicating if any relevant fields have changed.
     */
    private static Boolean hasColumnChanged(
        Column__c newColumn,
        Column__c oldColumn
    ) {
        Set<String> fieldsToCompare = new Set<String>{
            'Board__c',
            'Position__c',
            'Status__c',
            'Color__c',
            'ColumnHeader__c'
        };

        for (String field : fieldsToCompare) {
            if (newColumn.get(field) != oldColumn.get(field)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Creates an event for a column.
     * @param eventType The type of event (e.g., 'ColumnUpdate').
     * @param column The `Column__c` record for which the event is created.
     * @return The created `ColumnUpdateEvent__e` event.
     */
    private static ColumnUpdateEvent__e createEvent(
        String eventType,
        Column__c column
    ) {
        return new ColumnUpdateEvent__e(
            BoardId__c = column.Board__c,
            ColumnColor__c = column.Color__c,
            ColumnId__c = column.Id,
            ColumnName__c = column.Name,
            ColumnHeader__c = column.ColumnHeader__c,
            ColumnPosition__c = column.Position__c,
            ColumnStatus__c = column.Status__c,
            EventType__c = eventType,
            LastModifiedDate__c = column.LastModifiedDate
        );
    }

    /**
     * @description Publishes events for a list of columns.
     * @param columns List of `Column__c` records for which events are published.
     * @param eventType The type of event (e.g., 'ColumnCreate').
     */
    private static void publishEvents(
        List<Column__c> columns,
        String eventType
    ) {
        List<ColumnUpdateEvent__e> events = new List<ColumnUpdateEvent__e>();
        for (Column__c column : columns) {
            events.add(createEvent(eventType, column));
        }
        publishEvents(events);
    }

    /**
     * @description Publishes a list of events.
     * @param events List of `ColumnUpdateEvent__e` events to be published.
     */
    private static void publishEvents(
        List<ColumnUpdateEvent__e> events
    ) {
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
}
