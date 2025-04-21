public without sharing class AktualityController {

    @AuraEnabled(Cacheable=true)
    public static List<Aktuality__c> getRecentAktuality(Integer limitRecords) {
        String query = 'SELECT Id, Nadpis__c, Text_Aktuality__c, Datum_publikace__c FROM Aktuality__c ' +
                ' WHERE Datum_publikace__c <= TODAY ORDER BY Datum_publikace__c DESC LIMIT :limitRecords';
        return Database.query(query);
    }

    @AuraEnabled
    public static ImageWrapper getRelatedImage(Id recordId) {
        if (recordId == null
                || (recordId.getSobjectType() != Aktuality__c.SObjectType
                && recordId.getSobjectType() != Pribehy__c.SObjectType)) return null;

        List<ContentDocumentLink> links = [
                SELECT ContentDocumentId, ContentDocument.LatestPublishedVersion.Title,
                        ContentDocument.LatestPublishedVersionId, ContentDocument.Description
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 1
        ];

        if (links.size() == 0) return null;

        ContentDocumentLink link = links[0];
        List<ContentDistribution> distributions = getDistributions(link.ContentDocumentId);
        if (distributions.isEmpty()) return null;

        return new ImageWrapper(distributions[0], link.ContentDocument.Description);

    }

    private static List<ContentDistribution> getDistributions(Id contentDocumentId) {
        return [
                SELECT Id, DistributionPublicUrl, ContentDownloadUrl
                FROM ContentDistribution
                WHERE ContentDocumentId = :contentDocumentId
        ];
    }

    public class ImageWrapper {
        @AuraEnabled public String url;
        @AuraEnabled public String title;

        public ImageWrapper(ContentDistribution distribution, String description) {
            url = distribution.ContentDownloadUrl.replace('download/?', 'renditionDownload?rendition=ORIGINAL_Jpg&').replace('&ids', '&versionId');
            title = description;
        }
    }
}