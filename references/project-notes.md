# Project notes and assessment requirements

Sprint notes supplied by Rimon Hanna on 21 October 2026, organized for reference. These describe the intended product, proposed checks and acceptance scenarios. They are not a statement that every item is implemented, verified or legally approved. Unfinished prompts and design decisions remain open below.

## Purpose and user stories

**Who:** An internal Salesforce administrator, with or without external support, who has been asked to implement AI in an org.

**What:** A tool that helps the administrator think through implementation requirements and discuss them with colleagues and management.

**Why:** AI implementation is a complex topic that can overwhelm administrators and management. The tool should structure their thinking and keep important requirements visible.

**How:** An app page combining automated checks and human-entered assessments to provide an immediate, understandable overview of AI readiness. Guidance should use plain language, explain Salesforce best practices and link to relevant Trailhead learning. A partner or consultancy should be able to extend the baseline.

The assessment should help answer:

- Is the organization ready to implement and operate AI?
- Will data security follow best practices and the organization's existing protocols?
- Which issues need attention before readiness can be established?
- Who is responsible for each issue, including stakeholders and accountable roles?
- What is the current GDPR/AVG compliance position, and how could AI implementation affect it?
- Which mundane or time-consuming tasks in existing workflows could benefit from AI automation?

Automated configuration checks should support this discussion. They cannot establish staff competence or organizational/legal compliance by themselves.

## Questions before an AI implementation

- How secure is the data?
- What is the use case, and how does it add value?
- Where are the handover points between AI, humans and the end client?
- What could be lost or put at risk, and how will that risk be managed?
- What will count as a successful implementation?
- Do expected gains justify expected costs?

The supplied notes associate the following value-assessment topics with **Pierre-Marie Boutet**: ROI, KPIs, cost reduction, social impact and a decision matrix. The detailed decision matrix remains to be defined.

## Blocking topics and expected assessment feedback

| Topic | Concern to assess | Expected guidance |
| --- | --- | --- |
| External interfaces | Donor information could be exposed through insecure interfaces, disclosed publicly or obtained by bad actors. | Identify permitted interfaces, data destinations and access boundaries for the specific use case. |
| Sensitive information | Internal or external users could obtain sensitive information they should not access. | Apply least privilege and demonstrate role-specific access, including allowed and forbidden requests. |
| Internal data protocols | Rules are needed for moving data into particular locations and systems. Temporary restrictions may be needed when a user is in a high-risk region. | Record approved data-handling, security and GDPR/AVG policies, their sign-off and relevant exceptions. |
| Excessive agent rights | View All, Modify All and unnecessary information can give an agent excessive scope. Unnecessary data in the org also increases exposure. | Keep agent functions narrow. Review permission sets and muting where applicable, and scope access to the use case. |
| Missing ownership | Nobody may be accountable for risk, privacy, security or ongoing operation. | Name the administrator, security owner, AI use-case owner and DPO or other appropriate privacy owner. |
| AI/LLM management | Staff may not know which corporate or private LLMs are permitted, for which purposes, or under which data-handling terms. | Identify approved providers, permitted uses and conditions for safe use. |
| Data quality | Incomplete, inconsistent or outdated information, including Knowledge content, can undermine AI output. | Scope validation and freshness checks to the information the agent will use. Assign owners for correction and review. |

Each check should provide understandable feedback and advice. The notes also propose a low-level presentation/video, such as a Loom walkthrough, showing how to create an MCP connection with minimum necessary access. That resource still needs to be defined.

The supplied resource on DPO requirements is [When is a DPO legally required?](https://www.gdpr-advisor.com/when-is-a-dpo-legally-required-understanding-the-gdpr-criteria/). It is a resource to fact-check, not a determination of an individual organization's obligations.

## Deliverable and assessment levels

The intended deliverable is a managed assessment package with an app page and checklists at three levels:

1. **Implementation/use-case level:** checks specific to a proposed agent or AI implementation.
2. **Org level:** Salesforce configuration and data readiness.
3. **Company level:** ownership, policies, processes and business readiness.

**Open design decision:** Decide how checklist responses, observations and results are stored at each level, including the roles of records and custom metadata. The original notes pose this as a question rather than a settled design.

The original app-content outline and end-goal prompts are unfinished and need further definition.

## Data quality assessment criteria

Scope checks to the objects and fields on which the agent will ground its answers or actions.

### Completeness

- Fill rate of fields the agent will read or reason over, per object.
- Picklist fields where blank or Other values exceed an agreed threshold.
- Volume of free-form and rich-text data.

### Duplicates and integrity

- Whether duplicate and matching rules are active on Contact, Account and Lead, and whether they block or only alert.
- Estimated duplicate rates, including matching email or matching name and postal code.
- Orphaned records, including Contacts without Accounts and Opportunities/Gifts without a donor.

### Freshness

- Records still active and in agent scope that have not been modified within an agreed number of years.
- For Data Libraries or uploaded grounding files: what they contain, who curates them and when they were last reviewed.

### Consistency and metadata

- Free-text fields that should use controlled values, such as country, state or payment method.
- Unused or duplicate fields on in-scope objects, such as multiple Preferred Email fields.
- Whether in-scope fields have descriptions and help text. The proposed check treats unclear metadata as a readiness concern because an agent may use metadata to interpret field meaning.

Thresholds, validation methods and object coverage require definition and fact-checking. A matching indicator is not by itself proof of a duplicate person.

## Staff readiness

Use a guided flow with human input and observed evidence. Staff readiness cannot be established automatically from configuration alone.

### Named roles

Record who is responsible for:

- Salesforce administration.
- GDPR/AVG and privacy, including a DPO where one is required or the person handling those responsibilities otherwise.
- Security decisions, including access grants and integration approvals.
- The AI use case, including authority to switch the actual agent off.

### Process ownership

For each process, ask **who owns it** and **whether it is documented**:

- Data entry and imports, including Data Import Wizard/Data Loader access and checking import results.
- Deduplication and merging.
- Integrations feeding data into Salesforce, including forms, payment processors, iRaiser and email tools.
- Knowledge article creation and review.
- Access requests and offboarding, including how quickly leavers are deactivated.
- Subject access and erasure requests.
- Reviewing AI output and handling complaints or errors.

### Escalation and handover

- When an agent cannot or should not act, who receives the handover and how?
- Who reviews conversation logs, and how often?
- What is the response process if the agent exposes information it should not?

## Data policies

Use a guided assessment to determine alignment between organizational policies and Salesforce implementation.

### GDPR/AVG and consent

- Is lawful basis recorded per contact or processing purpose?
- Is consent captured in Salesforce, using consent objects, Individual or custom fields, and actually used to filter outreach?
- Does the erasure process cover records, files, field history, the Recycle Bin, backups and connected tools?
- If an external LLM provider is used, what are its data-retention terms?

### Retention

- Are written retention periods defined for each data type?
- Are those rules reflected in Salesforce through scheduled deletion, archiving, anonymization and field-history retention settings?

### Sensitive and special-category information

- Does the organization hold information concerning health, religion, ethnicity, beneficiary vulnerability or minors?
- Is relevant information identified through field classification or data-sensitivity metadata?
- Is it excluded from agent access? If needed for an agent function, is there an approved organizational policy governing that access?

**Open topic:** The AI and LLM policy section in the original outline requires further content.

## Safeguard acceptance scenarios

These are tests of the **actual AI account and connected workflow**, not substitutes performed only as a system administrator or within the assessment app.

| Area | Actor | Test | Expected result |
| --- | --- | --- | --- |
| Allowed access | Actual AI account | Ask the assistant to access, retrieve or display information it is permitted to access. | The permitted information is displayed correctly. |
| Forbidden access | The same actual AI account | Ask the assistant to access, retrieve or display information it is not permitted to access. | Restricted information is not displayed; access is denied or a suitable error is returned. |
| Human approval | Actual AI account and authorized human reviewer | Request an export containing sensitive fields before approval has been given. | Export is blocked, with an access/approval error or a Not approved response. |
| Stopping the assistant | Authorized human user and actual AI account | Operate a verifiable kill switch for the actual assistant. | The AI assistant is switched off. Pausing the assessment app alone does not meet this criterion. |
| Alerts and incident response | Actual AI account and designated alert recipient | Attempt an unapproved or unauthorized data export. | Export is stopped and an email alert is sent to the designated person or people. Confirm the responsible person receives and responds to the alert. |

Safe recovery is part of the stated stopping-assistant objective, but the supplied test steps do not yet define its procedure or expected recovery result. That acceptance detail remains open.

## Work identified in the notes

- Fact-check the proposed criteria and resources.
- Build and validate minimum-access patterns for a Salesforce integration identity, MCP and Salesforce-initiated interactions.
- Define checklist content and automated checks.
- Define the maintenance strategy.
- Build the package.
- Complete project administration, including incorporation in sprint archives.
- Collect relevant Trailhead, technical and legal resources.

The notes establish product intent. Completion and acceptance must be tracked separately against actual implementation and observed evidence.
