global class DeleteMultipleObjectsBatch implements Database.Batchable<SObject> {
    global String query;

    // Constructor to pass the object name
    public DeleteMultipleObjectsBatch(String objectName) {
        query = 'SELECT Id FROM ' + objectName;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        delete scope;
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: Add any post-processing logic, like logging
        System.debug('Batch for object completed: ' + query);
    }
}