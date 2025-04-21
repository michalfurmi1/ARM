public without sharing class BudgetTableController {

    @AuraEnabled(Cacheable=true)
    public static List<Rozpocet__c> getBudgetRecords(Id zadostId, String recordTypeDeveloperName) {
        System.debug(zadostId);
        System.debug(recordTypeDeveloperName);
        return [
                SELECT Id, RecordType.DeveloperName, Jmeno_pracovnika__c, Uvazek__c, Mesicni_mzda_dle_uvazku_v_Kc__c, Pocet_mesicu__c,
                        Mzda_celkem_v_KC2__c, V_e_po_adovan_ho_p_sp_vku_od_nadace_v__c, Pracovn_pozice_v_r_mci_projektu__c,
                        Typ_dohody_DPC_DPP__c, Celkov_pocet_hodin__c, V_e_odm_ny_v_K_hodinu__c, Odmena_celkem_v_Kc__c,
                        Nazev_polozky__c, Realizator_odborneho_kurzu__c, Celkova_vyse_nakladu_v_Kc__c, IsDeleted,
                        Jednotka__c, Pocet_jednotek__c, Jednotkov_cena_v_K__c, Celkov_cena_polozky_v_Kc__c, Typ_polozky__c,
                        Popis_polozky_vysvetleni__c, Celkova_schvalena_castka__c, Celkova_schvalena_castka_hodnotitelem__c,
                        Celkova_castka_po_zmene__c, Status_Zmeny__c, Status_zmeny_2__c, Status_zmeny_3__c,
                        Castka_po_zmene_2__c, Castka_po_zmene_3__c, Vyuctovana_castka__c, Nove_vyuctovani__c,
                        Zadost__r.Stav_prubezneho_vyuctovani__c,
                (SELECT Id, Cislo_dokladu__c, Nazev_dokladu__c, Datum_uhrady__c, Ucel_vyuziti_nadacniho_prispevku__c,
                        Castka_v_Kc_vcetne_DPH__c, Typ_Vyuctovani__c FROM Vyuctovani__r ORDER BY Typ_Vyuctovani__c ASC NULLS LAST)
                FROM Rozpocet__c
                WHERE Zadost__c = :zadostId 
                AND RecordType.DeveloperName = :recordTypeDeveloperName 
                AND IsDeleted = FALSE
                AND Schovat_neschvaleny_radek__c = FALSE
                ORDER BY CreatedDate ASC
        ];
    }

    @AuraEnabled
    public static List<Rozpocet__c> saveBudgetLines(Id zadostId, String recordTypeDeveloperName, List<Rozpocet__c> budgetList, String mode) {
        List<Rozpocet__c> budgetListCleared = filterBudgetRestrictedFields(budgetList, mode);
        System.debug(budgetListCleared);
        System.debug(mode);
        Zadost__c zadost = [SELECT Id, Pocet_zadosti_o_zmenu__c FROM Zadost__c WHERE Id = :zadostId];
        for (Rozpocet__c budgetLine : budgetListCleared) {
            System.debug(budgetLine);
            budgetLine.Zadost__c = zadostId;
            budgetLine.RecordTypeId = Rozpocet__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
            if (mode == 'edit' && budgetLine.Status_Zmeny__c != 'Nova'
                    && (zadost.Pocet_zadosti_o_zmenu__c == 0 || zadost.Pocet_zadosti_o_zmenu__c == null)) {
                budgetLine.Celkova_schvalena_castka_hodnotitelem__c = budgetLine.V_e_po_adovan_ho_p_sp_vku_od_nadace_v__c;
            }

            switch on zadost.Pocet_zadosti_o_zmenu__c?.intValue() {
                when 0, null {
                    if (budgetLine.Celkova_castka_po_zmene__c > 0 && budgetLine.Status_Zmeny__c != 'Nova'
                            && budgetLine.Celkova_castka_po_zmene__c != budgetLine.Celkova_schvalena_castka__c) {
                        budgetLine.Status_Zmeny__c = 'Probiha';
                    } else if ((budgetLine.Celkova_castka_po_zmene__c == null || budgetLine.Celkova_castka_po_zmene__c == budgetLine.Celkova_schvalena_castka__c)
                            && budgetLine.Status_Zmeny__c != 'Nova') {
                        budgetLine.Status_Zmeny__c = '';
                    }
                }
                when 1 {
                    if (budgetLine.Castka_po_zmene_2__c > 0 && budgetLine.Status_zmeny_2__c != 'Nova'
                            && budgetLine.Castka_po_zmene_2__c != budgetLine.Celkova_schvalena_castka__c) {
                        budgetLine.Status_zmeny_2__c = 'Probiha';
                    } else if ((budgetLine.Castka_po_zmene_2__c == null || budgetLine.Castka_po_zmene_2__c == budgetLine.Celkova_schvalena_castka__c)
                            && budgetLine.Status_zmeny_2__c != 'Nova') {
                        budgetLine.Status_zmeny_2__c = '';
                    }
                }
                when 2 {
                    if (budgetLine.Castka_po_zmene_3__c > 0 && budgetLine.Status_zmeny_3__c != 'Nova'
                            && budgetLine.Castka_po_zmene_3__c != budgetLine.Celkova_schvalena_castka__c) {
                        budgetLine.Status_zmeny_3__c = 'Probiha';
                    } else if ((budgetLine.Castka_po_zmene_3__c == null || budgetLine.Castka_po_zmene_3__c == budgetLine.Celkova_schvalena_castka__c)
                            && budgetLine.Status_zmeny_3__c != 'Nova') {
                        budgetLine.Status_zmeny_3__c = '';
                    }
                }
            }
        }
        upsert budgetListCleared;
        return budgetListCleared;
    }
    
    @AuraEnabled
    public static void deleteBillingLines(Id recordId){
        FormAddChildController.deleteContentDocuments(new List<Id>{recordId});
        Database.delete(recordId);
    }

    @AuraEnabled
    public static List<Vyuctovani__c> saveBillingLines(String budgetWrappersJson, Boolean partialBillingMode) {
        System.debug(budgetWrappersJson);
        List<BillingItemsWrapper> budgetWrappers = (List<BillingItemsWrapper>) JSON.deserialize(budgetWrappersJson, List<BillingItemsWrapper>.class);
        List<Vyuctovani__c> vyuctovaniUpsert = new List<Vyuctovani__c>();
        Map<Id, Id> contentVersionIdToDocument = new Map<Id, Id>();
        if(budgetWrappers.isEmpty()) return vyuctovaniUpsert;
        
        for(BillingItemsWrapper budgetWrapper : budgetWrappers){
            System.debug(budgetWrapper.billingList);

            if(budgetWrapper.billingList != null && !budgetWrapper.billingList.isEmpty()) {
                for(BillingItemWrapper billingItemWrapper : budgetWrapper.billingList){
                    if(billingItemWrapper.vyuctovani?.Typ_Vyuctovani__c == 'Prubezne' && !partialBillingMode) continue;
                    if(billingItemWrapper.vyuctovani == null || billingItemWrapper.vyuctovani == new Vyuctovani__c()) continue;
                    if(billingItemWrapper.vyuctovani.Rozpocet__c == null) billingItemWrapper.vyuctovani.Rozpocet__c = budgetWrapper.budgetId;
                    if(billingItemWrapper.vyuctovani.Id == null) setTypVyuctovani(billingItemWrapper.vyuctovani, partialBillingMode);

                    vyuctovaniUpsert.add(billingItemWrapper.vyuctovani);

                    if(billingItemWrapper.contentVersionIds == null) continue;
                    for(Id cvId : billingItemWrapper.contentVersionIds){
                        contentVersionIdToDocument.put(cvId, null);
                    }
                }
            }
        }
        upsert vyuctovaniUpsert;

        createCDL(budgetWrappers, contentVersionIdToDocument);
        return vyuctovaniUpsert;
    }

    private static void setTypVyuctovani(Vyuctovani__c vyuctovani, Boolean partialBillingMode){
        if(partialBillingMode){
            vyuctovani.Typ_Vyuctovani__c = 'Prubezne';
        } else {
            vyuctovani.Typ_Vyuctovani__c = 'Konecne';
        }
    }

    private static void createCDL(List<BillingItemsWrapper> budgetWrappers, Map<Id, Id> contentVersionIdToDocument){
        List<ContentDocumentLink> cdlInsert = new List<ContentDocumentLink>();

        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionIdToDocument.keySet()]){
            contentVersionIdToDocument.put(cv.Id, cv.ContentDocumentId);
        }
        for(BillingItemsWrapper wrapper : budgetWrappers){
            for(BillingItemWrapper billingItemWrapper : wrapper.billingList){
                if(billingItemWrapper.contentVersionIds == null) continue;
                for(Id cvId : billingItemWrapper.contentVersionIds){
                    cdlInsert.add(new ContentDocumentLink(LinkedEntityId = billingItemWrapper.vyuctovani.Id, 
                            ContentDocumentId = contentVersionIdToDocument.get(cvId)));
                }
            }
        }
        insert cdlInsert;

    }

    public static List<Rozpocet__c> filterBudgetRestrictedFields(List<Rozpocet__c> budgetList, String mode) {
        List<Rozpocet__c> filteredBudgets = new List<Rozpocet__c>();
        for (Rozpocet__c budget : budgetList) {
            switch on mode {
                when 'edit' {
                    filteredBudgets.add(budget);
                }
                when 'readOnly' {
                    filteredBudgets.add(new Rozpocet__c(Id = budget.Id));
                }
                when 'reviewer' {
                    filteredBudgets.add(new Rozpocet__c(Id = budget.Id,
                            Celkova_schvalena_castka__c = budget.Celkova_schvalena_castka_hodnotitelem__c,
                            Celkova_schvalena_castka_hodnotitelem__c = budget.Celkova_schvalena_castka_hodnotitelem__c));
                }
                when 'change' {
                    if (budget.Status_Zmeny__c == 'Nova' || budget.Status_zmeny_2__c == 'Nova' || budget.Status_zmeny_3__c == 'Nova') {
                        filteredBudgets.add(budget);
                    } else {
                        filteredBudgets.add(new Rozpocet__c(Id = budget.Id,
                                Status_Zmeny__c = budget.Status_Zmeny__c,
                                Status_zmeny_2__c = budget.Status_zmeny_2__c,
                                Status_zmeny_3__c = budget.Status_zmeny_3__c,
                                Castka_po_zmene_2__c = budget.Castka_po_zmene_2__c,
                                Castka_po_zmene_3__c = budget.Castka_po_zmene_3__c,
                                Celkova_castka_po_zmene__c = budget.Celkova_castka_po_zmene__c));
                    }
                }
            }
        }
        return filteredBudgets;
    }

    @AuraEnabled
    public static void calculateIndirectApprovedBudgets(Id zadostId) {
        List<Rozpocet__c> primeNaklady = new List<Rozpocet__c>();
        List<Rozpocet__c> neprimeNaklady = new List<Rozpocet__c>();
        
        Zadost__c zadost = [
                SELECT Id, Prime_naklady_pozadovan_prispevek__c, Neprime_naklady_Pozadovany_prispevek__c, 
                (SELECT Id, V_e_po_adovan_ho_p_sp_vku_od_nadace_v__c, Celkova_schvalena_castka_hodnotitelem__c, 
                        RecordType.DeveloperName FROM Rozpocty__r)
                FROM Zadost__c
                WHERE Id = :zadostId
        ];
        if (zadost.Rozpocty__r.isEmpty()) return;
        
        fillGroupedNaklady(zadost.Rozpocty__r, primeNaklady, neprimeNaklady);
        Decimal primeNakladySum = getDirectCosts(primeNaklady);

        for (Rozpocet__c rozpocet : neprimeNaklady) {
            rozpocet.Celkova_schvalena_castka_hodnotitelem__c = getIndirectApprovedValue(primeNakladySum, zadost.Neprime_naklady_Pozadovany_prispevek__c, rozpocet);
            rozpocet.Celkova_schvalena_castka__c = rozpocet.Celkova_schvalena_castka_hodnotitelem__c;
        }
        update neprimeNaklady;
    }
    
    private static void fillGroupedNaklady(List<Rozpocet__c> rozpocty, List<Rozpocet__c> primeNaklady, List<Rozpocet__c> neprimeNaklady){
        for(Rozpocet__c rozpocet : rozpocty){
            if(rozpocet.RecordType.DeveloperName == 'Rozpocet_neprime_naklady'){
                neprimeNaklady.add(rozpocet);
            } else {
                primeNaklady.add(rozpocet);
            }
        }
    }
    
    private static Decimal getIndirectApprovedValue(Decimal primeNakladySum, Decimal neprimeNakladyRequested, Rozpocet__c rozpocet){
        if(rozpocet.V_e_po_adovan_ho_p_sp_vku_od_nadace_v__c == null || primeNakladySum == null || neprimeNakladyRequested == null) return 0;

        if(primeNakladySum * 0.1 >= neprimeNakladyRequested){
            return rozpocet.V_e_po_adovan_ho_p_sp_vku_od_nadace_v__c;
        } else {
            return (((primeNakladySum / neprimeNakladyRequested) / 10) * rozpocet.V_e_po_adovan_ho_p_sp_vku_od_nadace_v__c).setScale(2) ?? 0;
        }
    }
    
    private static Decimal getDirectCosts(List<Rozpocet__c> primeRozpocty){
        Decimal returnValue = 0;
        for(Rozpocet__c rozpocet : primeRozpocty){
            if(rozpocet.Celkova_schvalena_castka_hodnotitelem__c != null) returnValue += rozpocet.Celkova_schvalena_castka_hodnotitelem__c;
        }
        return returnValue;
    }
    
    public class BillingItemsWrapper{
        @AuraEnabled public List<BillingItemWrapper> billingList {get; set;}
        @AuraEnabled public Id budgetId {get; set;}
    }

    public class BillingItemWrapper{
        @AuraEnabled public Vyuctovani__c vyuctovani;
        @AuraEnabled public List<Id> contentVersionIds;

    }
}