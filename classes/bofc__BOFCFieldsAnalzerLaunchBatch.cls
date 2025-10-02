/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class BOFCFieldsAnalzerLaunchBatch implements Database.Batchable<SObject>, Database.Stateful {
    global List<String> fields;
    global List<bofc__BOFCFieldsAnalyzerResult__c> lPreIdFields;
    global Map<String,Integer> m_FieldName_PopulatedOn {
        get;
        set;
    }
    global Map<String,Set<String>> mapPickValues;
    global Map<String,bofc__BOFCFieldsAnalyzerResult__c> mfielst;
    global Integer nooftimes;
    global String obj;
    global Map<String,Schema.SObjectField> objectFields;
    global String paid {
        get;
        set;
    }
    global String Query;
    global BOFCFieldsAnalzerLaunchBatch(String obj, String paid, String f, String v) {

    }
    global BOFCFieldsAnalzerLaunchBatch(String obj, String paid, Map<String,Integer> m_FieldName_PopulatedOn, String f, String v) {

    }
    global BOFCFieldsAnalzerLaunchBatch(String obj, String paid, Integer nooftimes, String f, String v) {

    }
    global void execute(Database.BatchableContext BC, List<SObject> scope) {

    }
    global void finish(Database.BatchableContext BC) {

    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return null;
    }
}
