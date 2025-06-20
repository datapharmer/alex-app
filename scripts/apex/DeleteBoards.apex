List<Board__c> boards = [SELECT Id FROM Board__c];
Database.delete(boards, false);
