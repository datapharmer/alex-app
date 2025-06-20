import KanbanBoardUtils from 'c/kanbanBoardUtils';

const FIRST_INDEX = 0;
describe('c-kanban-board-utils', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('should map board data correctly', () => {
        const mappedData = KanbanBoardUtils.mapBoardData({
            board: {
                Id: '1',
                Name: 'Test Board',
                LastModifiedDate: '2023-10-01T12:34:56.789Z'
            },
            cards: [
                {
                    Id: 'card1',
                    Name: 'Card 1',
                    Assignee__c: 'user1',
                    Assignee__r: {
                        Name: 'User 1',
                        SmallPhotoUrl: '/img/user1.png'
                    },
                    CardType__c: 'Bug',
                    Column__c: 'col1',
                    Position__c: 1,
                    Priority__c: 'High',
                    Status__c: 'New',
                    StoryPoints__c: 5,
                    Subject__c: 'Subject 1',
                    CreatedDate: '2023-10-01T12:34:56.789Z'
                }
            ],
            columns: [
                {
                    Id: 'col1',
                    Name: 'Column 1',
                    Board__c: '1',
                    ColumnHeader__c: 'Header 1',
                    Position__c: 1,
                    Status__c: 'Open',
                    LastModifiedDate: '2023-10-01T12:34:56.789Z'
                }
            ]
        });

        expect(mappedData.board.boardId).toBe('1');
        expect(mappedData.board.boardName).toBe('Test Board');
        expect(mappedData.board.lastModifiedDate).toBe('2023-10-01T12:34:56Z');
        expect(mappedData.columns[FIRST_INDEX].columnId).toBe('col1');
        expect(mappedData.columns[FIRST_INDEX].columnName).toBe('Column 1');
        expect(mappedData.columns[FIRST_INDEX].columnHeader).toBe('Header 1');
        expect(mappedData.columns[FIRST_INDEX].lastModifiedDate).toBe(
            '2023-10-01T12:34:56Z'
        );
        expect(mappedData.cards[FIRST_INDEX].cardId).toBe('card1');
        expect(mappedData.cards[FIRST_INDEX].cardName).toBe('Card 1');
        expect(mappedData.cards[FIRST_INDEX].cardSubject).toBe('Subject 1');
    });
});
