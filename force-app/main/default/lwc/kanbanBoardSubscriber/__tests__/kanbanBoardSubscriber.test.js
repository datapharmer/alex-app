import { createElement } from 'lwc';
import KanbanBoardSubscriber from 'c/kanbanBoardSubscriber';
import kanbanStore from 'c/kanbanBoardStore';
import { subscribe } from 'lightning/empApi';

// Mock the imported methods
jest.mock('lightning/empApi', () => ({
    subscribe: jest.fn().mockResolvedValue({ id: '12345' }),
    unsubscribe: jest.fn(),
    onError: jest.fn()
}));

jest.mock('c/kanbanBoardStore', () => ({
    addCard: jest.fn().mockImplementation(() => Promise.resolve()),
    updateCard: jest.fn().mockImplementation(() => Promise.resolve()),
    deleteCard: jest.fn().mockImplementation(() => Promise.resolve())
}));

describe('c-kanban-board-subscriber', () => {
    let element;
    let dispatchEventSpy;

    beforeEach(() => {
        element = createElement('c-kanban-board-subscriber', {
            is: KanbanBoardSubscriber
        });
        element.boardId = 'testBoardId'; // Set the boardId for testing
        dispatchEventSpy = jest.spyOn(element, 'dispatchEvent');
        document.body.appendChild(element);
    });

    afterEach(() => {
        document.body.removeChild(element);
        jest.clearAllMocks();
    });

    it('should create the component successfully', () => {
        expect(element).toBeTruthy();
    });

    it('should subscribe to the platform event on connectedCallback', () => {
        expect(subscribe).toHaveBeenCalledWith(
            '/event/CardUpdateEvent__e', // channelName
            -1, // REPLAY_ID
            expect.any(Function) // Callback function
        );
    });

    it('should handle CardCreate event and add a card to the store', () => {
        const mockEvent = {
            data: {
                payload: {
                    EventType__c: 'CardCreate',
                    AssigneeId__c: '001',
                    CardId__c: '002',
                    CardName__c: 'Test Card',
                    CardPosition__c: '1',
                    CardPriority__c: 'High',
                    CardStatus__c: 'In Progress',
                    CardSubject__c: 'Subject',
                    CardType__c: 'Bug',
                    ColumnId__c: '003',
                    LastModifiedDate__c: '2023-10-01T00:00:00.000Z',
                    StoryPoints__c: '5'
                }
            }
        };

        // Simulate the platform event
        const messageCallback = subscribe.mock.calls[0][2];
        messageCallback(mockEvent);

        return Promise.resolve().then(() => {
            expect(kanbanStore.addCard).toHaveBeenCalledWith('testBoardId', {
                assigneeId: '001',
                cardId: '002',
                cardName: 'Test Card',
                cardPosition: '1',
                cardPriority: 'High',
                cardStatus: 'In Progress',
                cardSubject: 'Subject',
                cardType: 'Bug',
                cardUrl: '/lightning/r/Card__c/002/view',
                columnId: '003',
                lastModifiedDate: '2023-10-01T00:00:00.000Z',
                storyPoints: '5'
            });
        });
    });

    it('should handle CardUpdate event and update a card in the store', () => {
        const mockEvent = {
            data: {
                payload: {
                    EventType__c: 'CardUpdate',
                    AssigneeId__c: '001',
                    CardId__c: '002',
                    CardName__c: 'Updated Card',
                    CardPosition__c: '2',
                    CardPriority__c: 'Medium',
                    CardStatus__c: 'Completed',
                    CardSubject__c: 'Updated Subject',
                    CardType__c: 'Feature',
                    cardUrl: '/lightning/r/Card__c/002/view',
                    ColumnId__c: '004',
                    LastModifiedDate__c: '2023-10-02T00:00:00.000Z',
                    StoryPoints__c: '8'
                }
            }
        };

        // Simulate the platform event
        const messageCallback = subscribe.mock.calls[0][2];
        messageCallback(mockEvent);

        return Promise.resolve().then(() => {
            expect(kanbanStore.updateCard).toHaveBeenCalledWith('testBoardId', {
                assigneeId: '001',
                cardId: '002',
                cardName: 'Updated Card',
                cardPosition: '2',
                cardPriority: 'Medium',
                cardStatus: 'Completed',
                cardSubject: 'Updated Subject',
                cardType: 'Feature',
                cardUrl: '/lightning/r/Card__c/002/view',
                columnId: '004',
                lastModifiedDate: '2023-10-02T00:00:00.000Z',
                storyPoints: '8'
            });
        });
    });

    it('should handle CardDelete event and remove a card from the store', () => {
        const mockEvent = {
            data: {
                payload: {
                    EventType__c: 'CardDelete',
                    CardId__c: '002'
                }
            }
        };

        // Simulate the platform event
        const messageCallback = subscribe.mock.calls[0][2];
        messageCallback(mockEvent);

        return Promise.resolve().then(() => {
            expect(kanbanStore.deleteCard).toHaveBeenCalledWith(
                'testBoardId',
                '002'
            );
        });
    });
});
