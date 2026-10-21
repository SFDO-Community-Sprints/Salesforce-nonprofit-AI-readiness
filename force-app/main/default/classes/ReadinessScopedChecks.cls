/** Read-only use-case collectors. Data is measured as the scanning user, never impersonated. */
public with sharing class ReadinessScopedChecks {
    private static final String DATA='Data quality', ACCESS='Access and safeguards';
    private static void add(List<Object> out,String id,String label,String groupName,String status,String actual,String expected,String action) {
        out.add(new Map<String,Object>{'id'=>'scope_'+id,'label'=>label,'group'=>groupName,'severity'=>'Medium','status'=>status,'actual'=>actual,'expected'=>expected,'action'=>action,'url'=>'/lightning/n/AI_Readiness'});
    }
    private static Decimal numberValue(Object value) { return value==null?null:Decimal.valueOf(String.valueOf(value)); }
    public static List<Object> collect(Map<String,Object> useCase) {
        List<Object> out=new List<Object>();
        if(useCase==null) return out;
        Map<String,List<String>> objects=new Map<String,List<String>>();
        Decimal completeness,days;
        try {
            completeness=numberValue(useCase.get('minimumCompleteness')); days=numberValue(useCase.get('freshDays'));
            if(completeness!=null&&(completeness<0||completeness>100)) throw new ScopeException();
            if(days!=null&&(days<1||days>3650||days!=days.setScale(0))) throw new ScopeException();
            List<Object> fields=(List<Object>)useCase.get('groundingFields');
            if(fields==null||fields.isEmpty()||fields.size()>12) throw new ScopeException();
            for(Object value:fields) {
                String key=String.valueOf(value);
                if(!Pattern.matches('^[A-Za-z][A-Za-z0-9_]*\\.[A-Za-z][A-Za-z0-9_]*$',key)) throw new ScopeException();
                List<String> parts=key.split('\\.'); String obj=parts[0],field=parts[1];
                Schema.SObjectType typ=Schema.getGlobalDescribe().get(obj);
                if(typ==null||!typ.getDescribe().isQueryable()||!typ.getDescribe().fields.getMap().containsKey(field)) throw new ScopeException();
                if(!objects.containsKey(obj)) objects.put(obj,new List<String>());
                if(!objects.get(obj).contains(field)) objects.get(obj).add(field);
            }
            if(objects.size()>3) throw new ScopeException();
        } catch(Exception ignored) {
            add(out,'invalid','Grounding scope',DATA,'unknown','Invalid or unsupported scope','1-12 valid fields across at most 3 queryable objects; valid explicit policies','Correct the use-case scope and policies.'); return out;
        }
        if(useCase.get('policyApproved')!=true||String.isBlank((String)useCase.get('policyReference'))) { completeness=null;days=null; }
        security(out,useCase,objects);
        sharingInventory(out,objects);
        for(String obj:objects.keySet()) {
            if(Limits.getLimitQueries()-Limits.getQueries()<20) {add(out,'budget_'+obj,'Scoped collection: '+obj,DATA,'unknown','Query budget reserved for evidence and history','Complete bounded collection','Run a narrower grounding scope; no unmeasured check is passed.');continue;}
            data(out,obj,objects.get(obj),completeness,days);
        }
        return out;
    }
    private class ScopeException extends Exception {}
    private static void security(List<Object> out,Map<String,Object> config,Map<String,List<String>> objects) {
        if(!FeatureManagement.checkPermission('Readiness_Read_Org_Security')) {
            add(out,'identity','Intended assistant identity',ACCESS,'unknown','Security Reader required','Visible intended identity and effective grants','Assign the focused Security Reader role; no setup pass inferred.'); return;
        }
        try {
            Id identity=(Id)String.valueOf(config.get('integrationUserId'));
            if(identity==null||identity.getSObjectType()!=User.SObjectType) throw new ScopeException();
            List<SObject> users=Database.query('SELECT Id,IsActive,ProfileId FROM User WHERE Id=:identity WITH USER_MODE');
            if(users.isEmpty()) throw new ScopeException();
            SObject actor=users[0]; Id profileId=(Id)actor.get('ProfileId');
            add(out,'identity_active','Intended identity active',ACCESS,(Boolean)actor.get('IsActive')?'pass':'fail',(Boolean)actor.get('IsActive')?'Active identity':'Inactive identity','Active intended integration identity','Review the selected account; active status does not prove allowed or denied runtime behavior.');
            List<SObject> assignments=Database.query('SELECT PermissionSetId,PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId=:identity AND IsActive=true AND IsRevoked=false WITH USER_MODE LIMIT 2000');
            if(assignments.size()==2000) throw new ScopeException();
            Set<Id> grants=new Set<Id>(), groups=new Set<Id>(); Boolean grouped=false;
            for(SObject assignment:assignments) { if(assignment.get('PermissionSetGroupId')!=null) groups.add((Id)assignment.get('PermissionSetGroupId')); else grants.add((Id)assignment.get('PermissionSetId')); }
            for(SObject profile:Database.query('SELECT Id FROM PermissionSet WHERE ProfileId=:profileId WITH USER_MODE')) grants.add((Id)profile.get('Id'));
            if(!groups.isEmpty()) {
                List<SObject> states=Database.query('SELECT Id,Status FROM PermissionSetGroup WHERE Id IN :groups WITH USER_MODE');
                if(states.size()!=groups.size()) grouped=true;
                for(SObject state:states) if(state.get('Status')!='Updated') grouped=true;
                List<SObject> aggregates=Database.query('SELECT Id,PermissionSetGroupId FROM PermissionSet WHERE PermissionSetGroupId IN :groups AND Type=\'Group\' WITH USER_MODE');
                if(aggregates.size()!=groups.size()) grouped=true;
                for(SObject aggregate:aggregates) grants.add((Id)aggregate.get('Id'));
            }
            if(grants.isEmpty()) throw new ScopeException();
            for(SObject activation:Database.query('SELECT HasActivationRequired FROM PermissionSet WHERE Id IN :grants WITH USER_MODE')) if((Boolean)activation.get('HasActivationRequired')) grouped=true;
            if(grouped) {
                add(out,'effective_grants','Effective identity grants',ACCESS,'unknown','Group aggregate unavailable, recalculating, or session activation required','Recalculated aggregate permissions with muting applied','Review effective group permissions and recalculation before evaluating access; component grants are not effective grants.');
            } else {
                Boolean broad=false,apiOnly=false;
                for(SObject grant:Database.query('SELECT PermissionsViewAllData,PermissionsModifyAllData,PermissionsApiUserOnly FROM PermissionSet WHERE Id IN :grants WITH USER_MODE')) {
                    broad=broad||(Boolean)grant.get('PermissionsViewAllData')||(Boolean)grant.get('PermissionsModifyAllData'); apiOnly=apiOnly||(Boolean)grant.get('PermissionsApiUserOnly');
                }
                add(out,'global_broad','Identity org-wide data grants',ACCESS,broad?'fail':'pass',broad?'View All Data or Modify All Data granted':'No org-wide data grant found','No broad org-wide grants','Use narrow object and field permissions; runtime boundaries require separate verification.');
                add(out,'api_only','API-only identity restriction',ACCESS,apiOnly?'pass':'unknown',apiOnly?'API-only permission granted':'API-only permission absent','API-only restriction for the selected integration identity','Confirm this account is dedicated to the use case. API-only metadata does not prove exclusive use.');
                Set<String> objectNames=objects.keySet(); Map<String,Boolean> reads=new Map<String,Boolean>(),wide=new Map<String,Boolean>(); Set<String> fieldReads=new Set<String>();
                for(SObject permission:Database.query('SELECT SobjectType,PermissionsRead,PermissionsViewAllRecords,PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId IN :grants AND SobjectType IN :objectNames WITH USER_MODE')) {
                    String obj=(String)permission.get('SobjectType');
                    reads.put(obj,reads.get(obj)==true||(Boolean)permission.get('PermissionsRead'));
                    wide.put(obj,wide.get(obj)==true||(Boolean)permission.get('PermissionsViewAllRecords')||(Boolean)permission.get('PermissionsModifyAllRecords'));
                }
                Set<String> selectedFields=new Set<String>();for(String obj:objects.keySet()) for(String field:objects.get(obj)) selectedFields.add(obj+'.'+field);
                List<SObject> fieldGrants=Database.query('SELECT Field,PermissionsRead FROM FieldPermissions WHERE ParentId IN :grants AND SobjectType IN :objectNames AND Field IN :selectedFields WITH USER_MODE LIMIT 10000');
                if(fieldGrants.size()==10000) throw new ScopeException();
                for(SObject permission:fieldGrants) if((Boolean)permission.get('PermissionsRead')) fieldReads.add((String)permission.get('Field'));
                for(String obj:objects.keySet()) {
                    add(out,'read_'+obj,'Identity object read: '+obj,ACCESS,broad||reads.get(obj)==true?'pass':'fail',broad||reads.get(obj)==true?'Read granted':'Read not granted','Read for selected grounding object','Verify the actual assistant can read only its approved scope.');
                    add(out,'broad_'+obj,'Identity broad object grants: '+obj,ACCESS,broad||wide.get(obj)==true?'fail':'pass',broad||wide.get(obj)==true?'Broad record grant found':'No broad record grant found','No View All or Modify All for scoped objects','Review record access and approved exceptions.');
                    Integer explicitFields=0,implicitFields=0;
                    for(String field:objects.get(obj)) {
                        if(fieldReads.contains(obj+'.'+field)) explicitFields++;
                        else implicitFields++;
                    }
                    add(out,'fields_'+obj,'Identity grounding field grants: '+obj,ACCESS,implicitFields==0&&reads.get(obj)==true?'pass':'unknown',explicitFields+' explicit readable fields; '+implicitFields+' without explicit rows','Effective readable selected fields','Missing FieldPermissions rows can represent implicit standard-field access; verify effective access, never infer denial from missing rows.');
                }
            }
        } catch(Exception ignored) { add(out,'identity_visibility','Intended identity permissions',ACCESS,'unknown','Identity or setup visibility unavailable','Valid visible intended user and complete grant metadata','Select an integration user and confirm setup visibility; no permission pass inferred.'); }
        add(out,'dedicated','Dedicated integration identity ownership',ACCESS,'unknown','Account dedication is not inferable from grants','Named owner and confirmation of exclusive approved use','Confirm the selected account is dedicated to this use case and has an accountable owner.');
        add(out,'runtime','Actual assistant access boundaries',ACCESS,'unknown','Metadata is not executed assistant evidence','Actual allowed and forbidden requests with the intended assistant','Run the safeguard tests using the real assistant identity and tools.');
    }
    private static void sharingInventory(List<Object> out,Map<String,List<String>> objects) {
        if(!FeatureManagement.checkPermission('Readiness_Read_Org_Security')) {
            for(String obj:objects.keySet()) {
                add(out,'sharing_'+obj,'Grounding sharing model: '+obj,ACCESS,'unknown','Security Reader required','Approved internal and external sharing for the use case','Review sharing metadata and record-level runtime access.');
                add(out,'guest_'+obj,'Guest grounding object access: '+obj,ACCESS,'unknown','Security Reader required','Approved guest exposure policy','Review active guest profiles and effective object grants.');
            }
            return;
        }
        Set<String> names=objects.keySet();Map<String,String> models=new Map<String,String>();
        try {
            for(SObject entity:Database.query('SELECT QualifiedApiName,InternalSharingModel,ExternalSharingModel FROM EntityDefinition WHERE QualifiedApiName IN :names WITH USER_MODE')) models.put((String)entity.get('QualifiedApiName'),'Internal: '+String.valueOf(entity.get('InternalSharingModel'))+'; external: '+String.valueOf(entity.get('ExternalSharingModel')));
        } catch(Exception ignored) {}
        for(String obj:names) add(out,'sharing_'+obj,'Grounding sharing model: '+obj,ACCESS,'unknown',models.containsKey(obj)?models.get(obj):'Sharing metadata unavailable','Approved sharing policy for this object and use case','Compare sharing defaults, rules and actual assistant access to the approved policy; a sharing model alone is not a security verdict.');
        Map<String,String> guestInventory=new Map<String,String>();
        try {
            List<SObject> guests=Database.query('SELECT Id,ProfileId FROM User WHERE IsActive=true AND UserType=\'Guest\' WITH USER_MODE LIMIT 2000');
            if(guests.size()==2000) throw new ScopeException();
            Set<Id> guestIds=new Set<Id>(),profiles=new Set<Id>(),grants=new Set<Id>(),groups=new Set<Id>();
            for(SObject guest:guests) {guestIds.add((Id)guest.get('Id'));profiles.add((Id)guest.get('ProfileId'));}
            for(SObject profile:Database.query('SELECT Id FROM PermissionSet WHERE ProfileId IN :profiles WITH USER_MODE')) grants.add((Id)profile.get('Id'));
            List<SObject> assignments=Database.query('SELECT PermissionSetId,PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId IN :guestIds AND IsActive=true AND IsRevoked=false WITH USER_MODE LIMIT 2000');
            if(assignments.size()==2000) throw new ScopeException();
            for(SObject assignment:assignments) {if(assignment.get('PermissionSetGroupId')!=null) groups.add((Id)assignment.get('PermissionSetGroupId'));else grants.add((Id)assignment.get('PermissionSetId'));}
            if(!groups.isEmpty()) {
                List<SObject> states=Database.query('SELECT Id,Status FROM PermissionSetGroup WHERE Id IN :groups WITH USER_MODE');
                if(states.size()!=groups.size()) throw new ScopeException();
                for(SObject state:states) if(state.get('Status')!='Updated') throw new ScopeException();
                List<SObject> aggregates=Database.query('SELECT Id FROM PermissionSet WHERE PermissionSetGroupId IN :groups AND Type=\'Group\' WITH USER_MODE');
                if(aggregates.size()!=groups.size()) throw new ScopeException();
                for(SObject aggregate:aggregates) grants.add((Id)aggregate.get('Id'));
            }
            Boolean globalBroad=false;
            for(SObject grant:Database.query('SELECT PermissionsViewAllData,PermissionsModifyAllData,HasActivationRequired FROM PermissionSet WHERE Id IN :grants WITH USER_MODE')) {
                if((Boolean)grant.get('HasActivationRequired')) throw new ScopeException();
                globalBroad=globalBroad||(Boolean)grant.get('PermissionsViewAllData')||(Boolean)grant.get('PermissionsModifyAllData');
            }
            Set<String> readable=new Set<String>(),broad=new Set<String>();
            for(SObject permission:Database.query('SELECT SobjectType,PermissionsRead,PermissionsViewAllRecords,PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId IN :grants AND SobjectType IN :names WITH USER_MODE')) {
                if((Boolean)permission.get('PermissionsRead')) readable.add((String)permission.get('SobjectType'));
                if((Boolean)permission.get('PermissionsViewAllRecords')||(Boolean)permission.get('PermissionsModifyAllRecords')) broad.add((String)permission.get('SobjectType'));
            }
            for(String obj:names) guestInventory.put(obj,guests.isEmpty()?'No visible active guest identities':(globalBroad||readable.contains(obj)?'Guest object read granted':'No guest object read grant found')+'; '+(globalBroad||broad.contains(obj)?'broad record grant found':'no broad record grant found'));
        } catch(Exception ignored) {}
        for(String obj:names) add(out,'guest_'+obj,'Guest grounding object access: '+obj,ACCESS,'unknown',guestInventory.containsKey(obj)?guestInventory.get(obj):'Guest metadata incomplete or unavailable','Approved guest exposure policy and runtime verification','Review whether guest access is intended. Profile/direct/recalculated group grants are configuration evidence, not complete effective record access.');
    }
    private static void data(List<Object> out,String obj,List<String> fields,Decimal completeness,Decimal days) {
        Schema.DescribeSObjectResult description=Schema.getGlobalDescribe().get(obj).getDescribe();
        Map<String,Schema.SObjectField> metadata=description.fields.getMap();
        Integer total;
        try { total=Database.countQuery('SELECT COUNT() FROM '+obj+' WITH USER_MODE'); }
        catch(Exception ignored) { add(out,'data_'+obj,'Scoped data: '+obj,DATA,'unknown','Current scanner cannot read the scope','Accessible aggregate data','Grant the scanner only its approved scope; it does not impersonate the assistant.');return; }
        if(total<5) { add(out,'cohort_'+obj,'Scoped data: '+obj,DATA,'unknown','Small cohort withheld','At least 5 accessible records','Use representative data; individual values and small aggregates are withheld.');return; }
        Integer freeText=0,missingHelp=0,similar=0;
        Set<String> selectedNames=new Set<String>(fields);
        for(String selected:fields) {
            String base=selected.toLowerCase().replace('__c','').replace('_','');
            String selectedLabel=metadata.get(selected).getDescribe().getLabel().toLowerCase().replaceAll('[^a-z0-9]','');
            for(String candidate:metadata.keySet()) {
                if(selectedNames.contains(candidate)) continue;
                String name=candidate.toLowerCase().replace('__c','').replace('_','');
                String label=metadata.get(candidate).getDescribe().getLabel().toLowerCase().replaceAll('[^a-z0-9]','');
                if(name==base||label==selectedLabel||(base.length()>=5&&name.length()>=5&&(name.contains(base)||base.contains(name)))) similar++;
            }
        }
        add(out,'similar_'+obj,'Similarly named grounding fields: '+obj,DATA,'unknown',similar+' candidate name or label similarities','Human-confirmed unambiguous grounding field meaning','Review similarly named fields in Object Manager; name similarity is an inventory heuristic, not a data quality verdict.');
        for(String field:fields) {
            Schema.DescribeFieldResult info=metadata.get(field).getDescribe();
            if(String.isBlank(info.getInlineHelpText())) missingHelp++;
            if(new Set<String>{'STRING','TEXTAREA'}.contains(String.valueOf(info.getType()).toUpperCase())) freeText++;
            String status='unknown',actual='Not measured';
            try {
                if(!info.isAccessible()||!info.isFilterable()) throw new ScopeException();
                Integer missing=Database.countQuery('SELECT COUNT() FROM '+obj+' WHERE '+field+'=null WITH USER_MODE');
                Decimal present=(Decimal.valueOf(total-missing)*100/total).setScale(1);
                actual=missing>0&&missing<5?'Population percentage withheld; a small missing-value cohort exists':present+'% populated (current scanner)'; status=completeness==null?'unknown':present>=completeness?'pass':'fail';
                if(info.getType()==Schema.DisplayType.Picklist) {
                    Integer other=Database.countQuery('SELECT COUNT() FROM '+obj+' WHERE '+field+'=\'Other\' WITH USER_MODE');
                    // Small category counts are suppressed even when the full cohort is larger.
                    actual+='; Other: '+(other>0&&other<5?'withheld':String.valueOf(other));
                    add(out,'other_'+obj+'_'+field,'Other choice review: '+obj+'.'+field,DATA,'unknown',other==0?'No Other choices found':other<5?'Other choices exist; small count withheld':other+' Other choices','Approved object-specific policy for Other choices','Review Other values separately; completeness policy does not define acceptable picklist choices.');
                }
            } catch(Exception ignored) {}
            add(out,'complete_'+obj+'_'+field,'Grounding completeness: '+obj+'.'+field,DATA,status,actual,completeness==null?'Explicit approved completeness threshold':completeness+'% populated','Review missing values and Other choices. No approved policy means no score.');
        }
        add(out,'metadata_'+obj,'Grounding metadata and free text: '+obj,DATA,'unknown',freeText+' selected free-text fields; '+missingHelp+' selected fields without inline help','Reviewed field meaning, description and approved text use','Review field descriptions and similarly named fields; inline help alone does not prove semantic quality.');
        String classification='Classification metadata unavailable';
        if(FeatureManagement.checkPermission('Readiness_Read_Org_Security')) {
            try {
                Set<String> selected=new Set<String>(fields);Integer described=0,classified=0,seen=0;
                for(SObject definition:Database.query('SELECT QualifiedApiName,Description,SecurityClassification FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName=:obj WITH USER_MODE')) {
                    if(!selected.contains((String)definition.get('QualifiedApiName'))) continue;
                    seen++; if(!String.isBlank((String)definition.get('Description'))) described++;
                    if(!String.isBlank((String)definition.get('SecurityClassification'))) classified++;
                }
                add(out,'descriptions_'+obj,'Grounding field descriptions: '+obj,DATA,seen!=fields.size()?'unknown':described==seen?'pass':'fail',described+' selected fields with descriptions','Descriptions for all '+fields.size()+' selected fields','Review meaning and similarly named fields; populated descriptions still require semantic review.');
                classification=classified+' of '+fields.size()+' selected fields classified';
            } catch(Exception ignored) {add(out,'descriptions_'+obj,'Grounding field descriptions: '+obj,DATA,'unknown','Metadata unavailable','Readable selected field descriptions','Review field descriptions in Object Manager.');}
        }
        add(out,'sensitive_'+obj,'Grounding data classification: '+obj,'Privacy and erasure','unknown',classification,'Reviewed sensitivity classification and approved assistant exposure','Review selected fields, including special-category and minors data; classification alone is not proof that exposure is approved.');
        try {
            if(days==null||!metadata.containsKey('LastModifiedDate')) throw new ScopeException();
            Datetime cutoff=Datetime.now().addDays(-days.intValue());
            Integer stale=Database.countQuery('SELECT COUNT() FROM '+obj+' WHERE LastModifiedDate<:cutoff WITH USER_MODE');
            add(out,'fresh_'+obj,'Grounding freshness: '+obj,DATA,stale==0?'pass':'fail',stale>0&&stale<5?'Stale count withheld; stale records exist':stale+' records older than approved window','All accessible records modified within '+days+' days','Confirm last modification reflects content review; exclude or review stale grounding records.');
        } catch(Exception ignored) { add(out,'fresh_'+obj,'Grounding freshness: '+obj,DATA,'unknown','No explicit policy or unavailable timestamp','Approved freshness window and accessible timestamp','Set an approved freshness policy; modification time alone is not knowledge curation evidence.'); }
        if(fields.contains('Email')&&new Set<String>{'Contact','Lead'}.contains(obj)) {
            try {
                List<SObject> duplicateGroups=Database.query('SELECT COUNT(Id) duplicates FROM '+obj+' WHERE Email!=null WITH USER_MODE GROUP BY Email HAVING COUNT(Id)>1 LIMIT 1');
                add(out,'duplicates_'+obj,'Repeated grounding email indicator: '+obj,DATA,duplicateGroups.isEmpty()?'pass':'fail',duplicateGroups.isEmpty()?'No repeated email group':'Repeated email exists; values withheld','No repeated email indicators','Review legitimate shared addresses before merging; this is not a matching-rule audit.');
            } catch(Exception ignored) {add(out,'duplicates_'+obj,'Repeated grounding email indicator: '+obj,DATA,'unknown','Not available','Readable email aggregate','Review duplicate and matching rules separately.');}
        } else add(out,'duplicates_'+obj,'Grounding duplicate indicator: '+obj,DATA,'unknown','No supported scoped email field','Approved object-specific matching policy','Select Contact.Email or Lead.Email, or review object-specific matching evidence.');
        if(fields.contains('AccountId')&&new Set<String>{'Contact','Opportunity'}.contains(obj)) {
            try {
                Integer orphan=Database.countQuery('SELECT COUNT() FROM '+obj+' WHERE AccountId=null WITH USER_MODE');
                add(out,'orphans_'+obj,'Grounding Account linkage: '+obj,DATA,orphan==0?'pass':'fail',orphan>0&&orphan<5?'Unlinked count withheld; unlinked records exist':orphan+' without Account','All scoped donor records linked to an Account','Review whether each unlinked record should have a donor Account.');
            } catch(Exception ignored) {add(out,'orphans_'+obj,'Grounding Account linkage: '+obj,DATA,'unknown','Not available','Accessible scoped linkage aggregate','Review object access and account linkage.');}
        } else add(out,'orphans_'+obj,'Grounding parent linkage: '+obj,DATA,'unknown','No supported selected parent field','Approved parent linkage policy','Select Contact.AccountId or Opportunity.AccountId, or provide object-specific linkage evidence.');
    }
}
