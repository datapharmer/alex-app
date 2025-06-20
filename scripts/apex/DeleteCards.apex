List<Card__c> cards = [SELECT Id FROM Card__c];
Database.delete(cards, false);
