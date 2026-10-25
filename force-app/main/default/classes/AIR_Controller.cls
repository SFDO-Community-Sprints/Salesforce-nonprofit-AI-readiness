/**
 * Apex API for the AI Readiness Check Lightning components.
 */
public with sharing class AIR_Controller {
    // ------------------------------------------------------------------ DTOs

    public class ResultDTO {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String level;
        @AuraEnabled
        public String category;
        @AuraEnabled
        public String categoryLabel;
        @AuraEnabled
        public String topic;
        @AuraEnabled
        public Boolean critical;
        @AuraEnabled
        public String checkType;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String evidence;
        @AuraEnabled
        public String answer;
        @AuraEnabled
        public String notes;
        @AuraEnabled
        public String responsible;
        @AuraEnabled
        public Date dueDate;
        @AuraEnabled
        public String question;
        @AuraEnabled
        public String passCriteria;
        @AuraEnabled
        public String advice;
        @AuraEnabled
        public List<AIR_Catalogue.Resource> resources;
    }

    public class CategoryDTO {
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public AIR_ScoreService.Summary summary;
        @AuraEnabled
        public List<ResultDTO> results = new List<ResultDTO>();
    }

    public class DashboardDTO {
        @AuraEnabled
        public Boolean hasScan = false;
        @AuraEnabled
        public Id orgAssessmentId;
        @AuraEnabled
        public Datetime lastScanDate;
        @AuraEnabled
        public String lastScanBy;
        @AuraEnabled
        public Boolean scanStale = false;
        @AuraEnabled
        public Boolean companyAnswered = false;
        @AuraEnabled
        public AIR_ScoreService.Summary overall;
        @AuraEnabled
        public List<CategoryDTO> categories = new List<CategoryDTO>();
        @AuraEnabled
        public List<ResultDTO> criticalFailures = new List<ResultDTO>();
    }

    public class AssessmentDTO {
        @AuraEnabled
        public Id assessmentId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String level;
        @AuraEnabled
        public Datetime runDate;
        @AuraEnabled
        public String runBy;
        @AuraEnabled
        public Boolean stale = false;
        @AuraEnabled
        public AIR_ScoreService.Summary summary;
        @AuraEnabled
        public List<CategoryDTO> categories = new List<CategoryDTO>();
    }

    public class OwnersDTO {
        @AuraEnabled
        public String dpoName;
        @AuraEnabled
        public String securityOwner;
        @AuraEnabled
        public String adminOwner;
        @AuraEnabled
        public String dpoNotRequiredReason;
        @AuraEnabled
        public String stakeholders;
    }

    public class AgentUserDTO {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String profileName;
        @AuraEnabled
        public String licence;
        @AuraEnabled
        public Boolean isActive;
        @AuraEnabled
        public Boolean isAdminProfile;
    }

    public class ChecklistDTO {
        @AuraEnabled
        public AgentUserDTO agentUser;
        @AuraEnabled
        public Id assessmentId;
        @AuraEnabled
        public String level;
        @AuraEnabled
        public Id useCaseId;
        @AuraEnabled
        public String useCaseName;
        @AuraEnabled
        public OwnersDTO owners = new OwnersDTO();
        @AuraEnabled
        public AIR_ScoreService.Summary summary;
        @AuraEnabled
        public List<CategoryDTO> categories = new List<CategoryDTO>();
        @AuraEnabled
        public List<ResultDTO> automated = new List<ResultDTO>();
    }

    public class UseCaseDTO {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String businessOwner;
        @AuraEnabled
        public Id assessmentId;
        @AuraEnabled
        public Datetime assessedOn;
        @AuraEnabled
        public Decimal score;
        @AuraEnabled
        public Decimal coverage;
        @AuraEnabled
        public String health;
        @AuraEnabled
        public Integer criticalFailures;
    }

    public class AnswerInput {
        public String code;
        public String answer;
        public String notes;
        public String responsible;
        public Date dueDate;
    }

    // ------------------------------------------------------------------ mapping helpers

    @TestVisible
    private static ResultDTO toDto(AIR_Check__mdt check, AIR_Assessment_Result__c row) {
        ResultDTO dto = new ResultDTO();
        if (check != null) {
            dto.code = check.DeveloperName;
            dto.title = check.MasterLabel;
            dto.level = check.Level__c;
            dto.category = check.Category__c;
            dto.topic = check.Topic__c;
            dto.critical = check.Critical__c;
            dto.checkType = check.Check_Type__c;
            dto.question = check.Question__c;
            dto.passCriteria = check.Pass_Criteria__c;
            dto.advice = check.Advice__c;
            dto.resources = AIR_Catalogue.parseResources(check.Resources__c);
            dto.status = AIR_Catalogue.NOT_CHECKED;
            dto.evidence = check.Check_Type__c == AIR_Catalogue.TYPE_MANUAL ? 'Not answered yet.' : 'Not run yet.';
        }
        if (row != null) {
            dto.id = row.Id;
            dto.code = row.Check_Code__c;
            dto.title = String.isBlank(dto.title) ? row.Check_Title__c : dto.title;
            dto.category = String.isBlank(dto.category) ? row.Category__c : dto.category;
            dto.topic = String.isBlank(dto.topic) ? row.Topic__c : dto.topic;
            dto.critical = dto.critical == null ? row.Critical__c : dto.critical;
            dto.checkType = String.isBlank(dto.checkType) ? row.Check_Type__c : dto.checkType;
            dto.status = row.Status__c;
            dto.evidence = row.Evidence__c;
            dto.answer = row.Answer__c;
            dto.notes = row.Notes__c;
            dto.responsible = row.Responsible__c;
            dto.dueDate = row.Due_Date__c;
        }
        if (dto.resources == null) {
            dto.resources = new List<AIR_Catalogue.Resource>();
        }
        dto.critical = dto.critical == true;
        dto.categoryLabel = AIR_Catalogue.categoryLabel(dto.category);
        return dto;
    }

    /** Groups DTOs into the four dashboard categories (empty categories are skipped when skipEmpty). */
    @TestVisible
    private static List<CategoryDTO> groupByCategory(List<ResultDTO> dtos, Boolean skipEmpty) {
        Map<String, CategoryDTO> byCode = new Map<String, CategoryDTO>();
        List<String> categoryOrder = new List<String>(AIR_Catalogue.CATEGORY_ORDER);
        for (String code : AIR_Catalogue.CATEGORY_ORDER) {
            CategoryDTO c = new CategoryDTO();
            c.code = code;
            c.label = AIR_Catalogue.categoryLabel(code);
            byCode.put(code, c);
        }
        for (ResultDTO dto : dtos) {
            if (!byCode.containsKey(dto.category)) {
                CategoryDTO c = new CategoryDTO();
                c.code = dto.category;
                c.label = AIR_Catalogue.categoryLabel(dto.category);
                byCode.put(dto.category, c);
                categoryOrder.add(dto.category);
            }
            byCode.get(dto.category).results.add(dto);
        }
        List<CategoryDTO> result = new List<CategoryDTO>();
        for (String code : categoryOrder) {
            CategoryDTO c = byCode.get(code);
            AIR_ScoreService.Summary s = new AIR_ScoreService.Summary();
            for (ResultDTO dto : c.results) {
                s.add(dto.status, dto.critical);
            }
            c.summary = s.finish();
            if (!(skipEmpty && c.results.isEmpty())) {
                result.add(c);
            }
        }
        return result;
    }

    private static AIR_ScoreService.Summary summarize(List<ResultDTO> dtos) {
        AIR_ScoreService.Summary s = new AIR_ScoreService.Summary();
        for (ResultDTO dto : dtos) {
            s.add(dto.status, dto.critical);
        }
        return s.finish();
    }

    /** Catalogue checks of one level merged with the assessment's rows (missing rows show as Not checked). */
    private static List<ResultDTO> merged(String level, Id assessmentId, String checkType) {
        Map<String, AIR_Assessment_Result__c> rows = AIR_ScanService.resultsByCode(assessmentId);
        List<ResultDTO> dtos = new List<ResultDTO>();
        for (AIR_Check__mdt check : AIR_Catalogue.forLevel(level)) {
            if (checkType == null || check.Check_Type__c == checkType) {
                dtos.add(toDto(check, rows.get(check.DeveloperName)));
            }
        }
        return dtos;
    }

    private static Boolean isStale(Datetime runDate) {
        return runDate != null && runDate < System.now().addHours(-24);
    }

    private static AuraHandledException auraError(Exception e) {
        AuraHandledException ex = new AuraHandledException(e.getMessage());
        ex.setMessage(e.getMessage());
        return ex;
    }

    // ------------------------------------------------------------------ API

    /** Home dashboard: latest Company + latest Org assessment against all defined checks. */
    @AuraEnabled(cacheable=true)
    public static DashboardDTO getDashboard() {
        try {
            DashboardDTO dto = new DashboardDTO();
            AIR_Assessment__c org = AIR_ScanService.latest(AIR_Catalogue.LEVEL_ORG, null);
            AIR_Assessment__c company = AIR_ScanService.latest(AIR_Catalogue.LEVEL_COMPANY, null);

            List<ResultDTO> allResults = new List<ResultDTO>();
            allResults.addAll(merged(AIR_Catalogue.LEVEL_COMPANY, company == null ? null : company.Id, null));
            allResults.addAll(merged(AIR_Catalogue.LEVEL_ORG, org == null ? null : org.Id, null));

            dto.overall = summarize(allResults);
            dto.categories = groupByCategory(allResults, false);
            for (ResultDTO r : allResults) {
                if (r.critical && r.status == AIR_Catalogue.ATTENTION) {
                    dto.criticalFailures.add(r);
                }
            }
            dto.companyAnswered = company != null;
            if (org != null) {
                dto.hasScan = true;
                dto.orgAssessmentId = org.Id;
                dto.lastScanDate = org.Run_Date__c;
                dto.lastScanBy = org.CreatedBy.Name;
                dto.scanStale = isStale(org.Run_Date__c);
            }
            return dto;
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    @AuraEnabled
    public static Id runOrgScan() {
        try {
            return AIR_ScanService.runOrgScan();
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    /** Detail of one assessment (latest Org assessment when the id is null). */
    @AuraEnabled
    public static AssessmentDTO getAssessmentDetail(Id assessmentId) {
        try {
            AssessmentDTO dto = new AssessmentDTO();
            AIR_Assessment__c assessment;
            if (assessmentId == null) {
                assessment = AIR_ScanService.latest(AIR_Catalogue.LEVEL_ORG, null);
            } else {
                List<AIR_Assessment__c> found = [
                    SELECT Id, Name, Level__c, Use_Case__c, Run_Date__c, CreatedBy.Name
                    FROM AIR_Assessment__c
                    WHERE Id = :assessmentId
                    WITH USER_MODE
                ];
                assessment = found.isEmpty() ? null : found[0];
            }
            if (assessment == null) {
                dto.level = AIR_Catalogue.LEVEL_ORG;
                List<ResultDTO> empty = merged(AIR_Catalogue.LEVEL_ORG, null, null);
                dto.summary = summarize(empty);
                dto.categories = groupByCategory(empty, true);
                return dto;
            }
            dto.assessmentId = assessment.Id;
            dto.name = assessment.Name;
            dto.level = assessment.Level__c;
            dto.runDate = assessment.Run_Date__c;
            dto.runBy = assessment.CreatedBy.Name;
            dto.stale = isStale(assessment.Run_Date__c);
            List<ResultDTO> dtos = merged(assessment.Level__c, assessment.Id, null);
            dto.summary = summarize(dtos);
            dto.categories = groupByCategory(dtos, true);
            return dto;
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    /** Manual checklist for a level. Doesn't create anything until the first save. */
    @AuraEnabled
    public static ChecklistDTO getChecklist(String level, Id useCaseId) {
        try {
            if (level != AIR_Catalogue.LEVEL_IMPLEMENTATION) {
                useCaseId = null;
            }
            ChecklistDTO dto = new ChecklistDTO();
            dto.level = level;
            dto.useCaseId = useCaseId;
            if (useCaseId != null) {
                for (AIR_Use_Case__c uc : [
                    SELECT Name, Agent_User__c
                    FROM AIR_Use_Case__c
                    WHERE Id = :useCaseId
                    WITH USER_MODE
                ]) {
                    dto.useCaseName = uc.Name;
                    dto.agentUser = agentUser(uc.Agent_User__c);
                }
            }
            AIR_Assessment__c assessment = AIR_ScanService.latest(level, useCaseId);
            if (assessment != null) {
                dto.assessmentId = assessment.Id;
                dto.owners.dpoName = assessment.DPO_Name__c;
                dto.owners.securityOwner = assessment.Security_Owner__c;
                dto.owners.adminOwner = assessment.Admin_Owner__c;
                dto.owners.dpoNotRequiredReason = assessment.DPO_Not_Required_Reason__c;
                dto.owners.stakeholders = assessment.Stakeholders__c;
            }
            Id assessmentId = assessment == null ? null : assessment.Id;
            List<ResultDTO> manual = merged(level, assessmentId, AIR_Catalogue.TYPE_MANUAL);
            dto.categories = groupByCategory(manual, true);
            dto.automated = merged(level, assessmentId, AIR_Catalogue.TYPE_AUTOMATED);
            List<ResultDTO> everything = new List<ResultDTO>(manual);
            everything.addAll(dto.automated);
            dto.summary = summarize(everything);
            return dto;
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    /**
     * Saves manual answers (and, for Company, the responsible people).
     * answersJson: [{code, answer, notes, responsible, dueDate}]
     * ownersJson: {dpoName, securityOwner, adminOwner, dpoNotRequiredReason, stakeholders} or null
     */
    @AuraEnabled
    public static ChecklistDTO saveChecklist(String level, Id useCaseId, String answersJson, String ownersJson) {
        try {
            if (level != AIR_Catalogue.LEVEL_IMPLEMENTATION) {
                useCaseId = null;
            } else if (useCaseId == null) {
                throw new IllegalArgumentException('Choose a use case for an implementation assessment.');
            }
            AIR_Assessment__c assessment = AIR_ScanService.ensureAssessment(level, useCaseId);
            Map<String, AIR_Assessment_Result__c> rows = AIR_ScanService.resultsByCode(assessment.Id);
            Map<String, AIR_Check__mdt> checks = AIR_Catalogue.byCode();

            List<AIR_Assessment_Result__c> updates = new List<AIR_Assessment_Result__c>();
            if (String.isNotBlank(answersJson)) {
                List<AnswerInput> answers = (List<AnswerInput>) JSON.deserialize(answersJson, List<AnswerInput>.class);
                for (AnswerInput a : answers) {
                    AIR_Assessment_Result__c row = rows.get(a.code);
                    AIR_Check__mdt check = checks.get(a.code);
                    if (row == null || check == null || check.Check_Type__c != AIR_Catalogue.TYPE_MANUAL) {
                        continue;
                    }
                    String answer = String.isBlank(a.answer) ? null : a.answer;
                    updates.add(
                        new AIR_Assessment_Result__c(
                            Id = row.Id,
                            Answer__c = answer,
                            Status__c = AIR_Catalogue.statusForAnswer(answer),
                            Evidence__c = answer == null ? 'Not answered yet.' : 'Answered: ' + answer + '.',
                            Notes__c = a.notes,
                            Responsible__c = a.responsible,
                            Due_Date__c = a.dueDate
                        )
                    );
                }
            }
            if (!updates.isEmpty()) {
                Database.update(updates, AccessLevel.USER_MODE);
            }

            AIR_Assessment__c header = new AIR_Assessment__c(Id = assessment.Id);
            if (level != AIR_Catalogue.LEVEL_ORG) {
                header.Run_Date__c = System.now();
            }
            if (level == AIR_Catalogue.LEVEL_COMPANY && String.isNotBlank(ownersJson)) {
                OwnersDTO owners = (OwnersDTO) JSON.deserialize(ownersJson, OwnersDTO.class);
                header.DPO_Name__c = owners.dpoName;
                header.Security_Owner__c = owners.securityOwner;
                header.Admin_Owner__c = owners.adminOwner;
                header.DPO_Not_Required_Reason__c = owners.dpoNotRequiredReason;
                header.Stakeholders__c = owners.stakeholders;
            }
            Database.update(header, AccessLevel.USER_MODE);

            if (level == AIR_Catalogue.LEVEL_IMPLEMENTATION) {
                AIR_ScanService.runImplementationChecks(assessment.Id, useCaseId);
            }
            AIR_ScoreService.recalculate(new Set<Id>{ assessment.Id });
            return getChecklist(level, useCaseId);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    private static AgentUserDTO agentUser(Id userId) {
        if (userId == null) {
            return null;
        }
        List<User> users = [
            SELECT
                Id,
                Name,
                Username,
                IsActive,
                Profile.Name,
                Profile.UserLicense.Name,
                Profile.PermissionsModifyAllData
            FROM User
            WHERE Id = :userId
        ];
        if (users.isEmpty()) {
            return null;
        }
        AgentUserDTO dto = new AgentUserDTO();
        dto.id = users[0].Id;
        dto.name = users[0].Name;
        dto.username = users[0].Username;
        dto.profileName = users[0].Profile.Name;
        dto.licence = users[0].Profile.UserLicense.Name;
        dto.isActive = users[0].IsActive;
        dto.isAdminProfile = users[0].Profile.PermissionsModifyAllData;
        return dto;
    }

    /**
     * Registers the integration user an AI use case connects as (by username), then re-runs the
     * implementation checks so the access checks reflect that user.
     */
    @AuraEnabled
    public static ChecklistDTO setAgentUser(Id useCaseId, String username) {
        try {
            if (useCaseId == null) {
                throw new IllegalArgumentException('Choose a use case first.');
            }
            Id userId = null;
            if (String.isNotBlank(username)) {
                List<User> users = [SELECT Id FROM User WHERE Username = :username.trim() LIMIT 1];
                if (users.isEmpty()) {
                    throw new IllegalArgumentException('No user found with username ' + username.trim() + '.');
                }
                userId = users[0].Id;
            }
            Database.update(new AIR_Use_Case__c(Id = useCaseId, Agent_User__c = userId), AccessLevel.USER_MODE);
            return runUseCaseChecks(useCaseId);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    /** Re-runs the automated data quality checks for a use case. */
    @AuraEnabled
    public static ChecklistDTO runUseCaseChecks(Id useCaseId) {
        try {
            AIR_Assessment__c assessment = AIR_ScanService.ensureAssessment(
                AIR_Catalogue.LEVEL_IMPLEMENTATION,
                useCaseId
            );
            AIR_ScanService.runImplementationChecks(assessment.Id, useCaseId);
            AIR_ScoreService.recalculate(new Set<Id>{ assessment.Id });
            return getChecklist(AIR_Catalogue.LEVEL_IMPLEMENTATION, useCaseId);
        } catch (Exception e) {
            throw auraError(e);
        }
    }

    /** Use cases with their latest implementation assessment. */
    @AuraEnabled
    public static List<UseCaseDTO> getUseCases() {
        try {
            Map<Id, AIR_Assessment__c> latestByUseCase = new Map<Id, AIR_Assessment__c>();
            for (AIR_Assessment__c a : [
                SELECT Id, Use_Case__c, Run_Date__c, Score__c, Coverage__c, Health__c, Critical_Failures__c
                FROM AIR_Assessment__c
                WHERE Level__c = :AIR_Catalogue.LEVEL_IMPLEMENTATION AND Use_Case__c != NULL
                WITH USER_MODE
                ORDER BY Run_Date__c DESC NULLS LAST, CreatedDate DESC, Id DESC
                LIMIT 2000
            ]) {
                if (!latestByUseCase.containsKey(a.Use_Case__c)) {
                    latestByUseCase.put(a.Use_Case__c, a);
                }
            }
            List<UseCaseDTO> result = new List<UseCaseDTO>();
            for (AIR_Use_Case__c uc : [
                SELECT Id, Name, Status__c, Business_Owner__c
                FROM AIR_Use_Case__c
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 500
            ]) {
                UseCaseDTO dto = new UseCaseDTO();
                dto.id = uc.Id;
                dto.name = uc.Name;
                dto.status = uc.Status__c;
                dto.businessOwner = uc.Business_Owner__c;
                AIR_Assessment__c a = latestByUseCase.get(uc.Id);
                if (a != null) {
                    dto.assessmentId = a.Id;
                    dto.assessedOn = a.Run_Date__c;
                    dto.score = a.Score__c;
                    dto.coverage = a.Coverage__c;
                    dto.health = a.Health__c;
                    dto.criticalFailures = a.Critical_Failures__c == null ? 0 : a.Critical_Failures__c.intValue();
                } else {
                    dto.health = AIR_ScoreService.HEALTH_NOT_CHECKED;
                }
                result.add(dto);
            }
            return result;
        } catch (Exception e) {
            throw auraError(e);
        }
    }
}
