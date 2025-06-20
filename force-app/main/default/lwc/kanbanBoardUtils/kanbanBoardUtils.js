const FIRST_INDEX = 0;
class KanbanBoardUtils {
    constructor() {
        if (KanbanBoardUtils.instance) {
            return;
        }
        KanbanBoardUtils.instance = this;
    }

    static getInstance() {
        if (!KanbanBoardUtils.instance) {
            KanbanBoardUtils.instance = new KanbanBoardUtils();
        }
        return KanbanBoardUtils.instance;
    }

    // Utility function to format Salesforce Date/Time field value without precision .000
    formatDateWithoutPrecision(dateString) {
        if (!dateString) {
            return undefined;
        }
        const date = new Date(dateString);
        return date.toISOString().split('.')[FIRST_INDEX] + 'Z';
    }

    mapBoardData(result) {
        return {
            board: {
                boardId: result.board?.Id ?? undefined,
                boardName: result.board?.Name ?? 'Unnamed Board',
                lastModifiedDate: this.formatDateWithoutPrecision(
                    result.board?.LastModifiedDate
                )
            },
            cards: result.cards
                ? result.cards.map(this.mapCard.bind(this))
                : [],
            columns: result.columns
                ? result.columns.map(column => ({
                      columnColor: column?.Color__c ?? undefined,
                      boardId: column?.Board__c ?? undefined,
                      columnHeader:
                          column?.ColumnHeader__c ??
                          column?.Name ??
                          'Unnamed Column',
                      columnId: column?.Id ?? undefined,
                      columnName: column?.Name ?? 'Unnamed Column',
                      columnPosition: column?.Position__c ?? undefined,
                      columnStatus: column?.Status__c ?? undefined,
                      columnUrl: `/lightning/r/Column__c/${column?.Id}/view`,
                      lastModifiedDate: this.formatDateWithoutPrecision(
                          column?.LastModifiedDate
                      )
                  }))
                : []
        };
    }

    mapCard(card) {
        return {
            assigneeId: card?.Assignee__c ?? undefined,
            assigneeName: card.Assignee__r?.Name ?? undefined,
            assigneePhoto: card.Assignee__r?.SmallPhotoUrl ?? undefined,
            cardColor: card?.Color__c ?? undefined,
            cardId: card?.Id ?? undefined,
            cardName: card?.Name ?? 'Unnamed Card',
            cardPosition: card?.Position__c ?? undefined,
            cardPriority: card?.Priority__c ?? undefined,
            cardStatus: card?.Status__c ?? undefined,
            cardSubject: card?.Subject__c ?? undefined,
            cardType: card?.CardType__c ?? undefined,
            cardUrl: `/lightning/r/Card__c/${card.Id}/view`,
            columnId: card?.Column__c ?? undefined,
            lastModifiedDate: this.formatDateWithoutPrecision(
                card?.LastModifiedDate
            ),
            storyPoints: card?.StoryPoints__c ?? undefined
        };
    }

    mapCards(cards) {
        return cards.map(this.mapCard.bind(this));
    }

    extractCardData(eventData) {
        return {
            assigneeId: eventData.AssigneeId__c,
            cardColor: eventData.CardColor__c,
            cardId: eventData.CardId__c,
            cardName: eventData.CardName__c,
            cardUrl: `/lightning/r/Card__c/${eventData.CardId__c}/view`,
            cardPosition: eventData.CardPosition__c,
            cardPriority: eventData.CardPriority__c,
            cardStatus: eventData.CardStatus__c,
            cardSubject: eventData.CardSubject__c,
            cardType: eventData.CardType__c,
            columnId: eventData.ColumnId__c,
            lastModifiedDate: eventData.LastModifiedDate__c,
            storyPoints: eventData.StoryPoints__c
        };
    }

    extractColumnData(eventData) {
        return {
            columnColor: eventData.ColumnColor__c,
            columnId: eventData.ColumnId__c,
            columnUrl: `/lightning/r/Column__c/${eventData.ColumnId__c}/view`,
            columnName: eventData.ColumnName__c,
            columnPosition: eventData.ColumnPosition__c,
            columnStatus: eventData.ColumnStatus__c,
            columnHeader: eventData.ColumnHeader__c,
            boardId: eventData.BoardId__c,
            lastModifiedDate: eventData.LastModifiedDate__c
        };
    }
}

export default KanbanBoardUtils.getInstance();
