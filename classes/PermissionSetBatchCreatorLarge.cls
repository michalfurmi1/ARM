public class PermissionSetBatchCreatorLarge {
    public static void createLargePermissionSets(Integer numberOfSets) {
        if (numberOfSets <= 0) {
            System.debug('Number of Permission Sets to create must be greater than 0.');
            return;
        }

        List<PermissionSet> permissionSetsToInsert = new List<PermissionSet>();
        List<ObjectPermissions> objectPermissionsToInsert = new List<ObjectPermissions>();
        List<FieldPermissions> fieldPermissionsToInsert = new List<FieldPermissions>();

        for (Integer i = 1; i <= numberOfSets; i++) {
            String labelName = 'EeARMPerfTest' + i;
            String apiName = 'EeCARMPerfTest' + i;

            // Create the Permission Set
            PermissionSet permSet = new PermissionSet();
            permSet.Label = labelName;
            permSet.Name = apiName;
            permissionSetsToInsert.add(permSet);
        }

        try {
            // Insert Permission Sets
            insert permissionSetsToInsert;
            System.debug('Permission Sets created successfully: ' + permissionSetsToInsert.size());

            // Generate Object Permissions for the created Permission Sets
            for (PermissionSet permSet : [SELECT Id FROM PermissionSet WHERE Name LIKE 'EeCARMPerfTest%']) {
                for (Schema.SObjectType sObj : Schema.getGlobalDescribe().values()) {
                    String objectName = sObj.getDescribe().getName();
                    ObjectPermissions objPerm = new ObjectPermissions();
                    objPerm.ParentId = permSet.Id;
                    objPerm.SObjectType = objectName;
                    objPerm.PermissionsRead = true;
                    objPerm.PermissionsCreate = true;
                    objPerm.PermissionsEdit = true;
                    objPerm.PermissionsDelete = true;
                    objPerm.PermissionsViewAllRecords = true;
                    objPerm.PermissionsModifyAllRecords = true;
                    objectPermissionsToInsert.add(objPerm);
                }
            }

            // Insert Object Permissions
            insert objectPermissionsToInsert;
            System.debug('Object Permissions created successfully: ' + objectPermissionsToInsert.size());

            // Generate Field Permissions
            for (PermissionSet permSet : [SELECT Id FROM PermissionSet WHERE Name LIKE 'EeCARMPerfTest%']) {
                for (Schema.SObjectType sObj : Schema.getGlobalDescribe().values()) {
                    Map<String, Schema.SObjectField> fields = sObj.getDescribe().fields.getMap();
                    for (String fieldName : fields.keySet()) {
                        FieldPermissions fieldPerm = new FieldPermissions();
                        fieldPerm.ParentId = permSet.Id;
                        fieldPerm.SObjectType = sObj.getDescribe().getName();
                        fieldPerm.Field = fieldName;
                        fieldPerm.PermissionsRead = true;
                        fieldPerm.PermissionsEdit = true;
                        fieldPermissionsToInsert.add(fieldPerm);
                    }
                }
            }

            // Insert Field Permissions
            insert fieldPermissionsToInsert;
            System.debug('Field Permissions created successfully: ' + fieldPermissionsToInsert.size());

        } catch (Exception e) {
            System.debug('Failed to create Permission Sets and associated data. Error: ' + e.getMessage());
        }
    }
}