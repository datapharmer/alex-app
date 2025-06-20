List<Column__c> columns = [SELECT Id FROM Column__c];
Database.delete(columns, false);
