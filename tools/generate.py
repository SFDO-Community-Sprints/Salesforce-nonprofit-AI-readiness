#!/usr/bin/env python3
"""Generates the declarative metadata for AIR (objects, fields, custom metadata
records, permission set, tabs, app, FlexiPages).

Run from the repo root:  python3 tools/generate.py
Apex and LWC source are hand-written and not touched by this script.
"""
import os
import shutil
import sys
from xml.sax.saxutils import escape

sys.path.insert(0, os.path.dirname(__file__))
from catalogue import CHECKS  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..", "force-app", "main", "default")
NS = 'xmlns="http://soap.sforce.com/2006/04/metadata"'
HEAD = '<?xml version="1.0" encoding="UTF-8"?>\n'


def write(path, content):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(HEAD + content.strip() + "\n")


def e(s):
    return escape(s or "")


# --------------------------------------------------------------------------- fields
def field_xml(f, cmdt=False):
    name, label, ftype = f["name"], f["label"], f["type"]
    parts = [f"<fullName>{name}</fullName>"]
    if f.get("help"):
        parts.append(f"<inlineHelpText>{e(f['help'])}</inlineHelpText>")
    parts.append(f"<label>{e(label)}</label>")
    if cmdt:
        parts.append("<fieldManageability>DeveloperControlled</fieldManageability>")
    if ftype == "Text":
        parts += [f"<length>{f.get('length', 255)}</length>", "<required>false</required>", "<type>Text</type>"]
    elif ftype == "LongTextArea":
        parts += [f"<length>{f.get('length', 32768)}</length>", "<type>LongTextArea</type>",
                  f"<visibleLines>{f.get('lines', 4)}</visibleLines>"]
    elif ftype == "TextArea":
        parts += ["<required>false</required>", "<type>TextArea</type>"]
    elif ftype == "Checkbox":
        parts += [f"<defaultValue>{'true' if f.get('default') else 'false'}</defaultValue>", "<type>Checkbox</type>"]
    elif ftype in ("Number", "Percent", "Currency"):
        prec, scale = {"Number": (18, 0), "Percent": (5, 1), "Currency": (16, 2)}[ftype]
        prec, scale = f.get("precision", prec), f.get("scale", scale)
        parts += [f"<precision>{prec}</precision>", "<required>false</required>",
                  f"<scale>{scale}</scale>", f"<type>{ftype}</type>"]
    elif ftype in ("Date", "DateTime"):
        parts += ["<required>false</required>", f"<type>{ftype}</type>"]
    elif ftype == "Picklist":
        vals = "".join(
            f"<value><fullName>{e(v)}</fullName><default>false</default><label>{e(v)}</label></value>"
            for v in f["values"])
        parts += ["<required>false</required>", "<type>Picklist</type>",
                  f"<valueSet><restricted>true</restricted><valueSetDefinition><sorted>false</sorted>{vals}"
                  "</valueSetDefinition></valueSet>"]
    elif ftype == "Lookup":
        parts += ["<deleteConstraint>SetNull</deleteConstraint>", f"<referenceTo>{f['ref']}</referenceTo>",
                  f"<relationshipLabel>{e(f['rel_label'])}</relationshipLabel>",
                  f"<relationshipName>{f['rel_name']}</relationshipName>",
                  "<required>false</required>", "<type>Lookup</type>"]
    elif ftype == "MasterDetail":
        parts += [f"<referenceTo>{f['ref']}</referenceTo>",
                  f"<relationshipLabel>{e(f['rel_label'])}</relationshipLabel>",
                  f"<relationshipName>{f['rel_name']}</relationshipName>",
                  "<relationshipOrder>0</relationshipOrder>",
                  "<reparentableMasterDetail>false</reparentableMasterDetail>",
                  "<type>MasterDetail</type>",
                  "<writeRequiresMasterRead>false</writeRequiresMasterRead>"]
    else:
        raise ValueError(ftype)
    first, rest = parts[0], parts[1:]
    rest.sort(key=lambda x: x[1:x.index(">")].split(" ")[0])
    return f"<CustomField {NS}>" + first + "".join(rest) + "</CustomField>"


STATUS = ["Passed", "Needs attention", "Not checked"]

OBJECTS = [
    dict(name="AIR_Use_Case__c", label="AI Use Case", plural="AI Use Cases",
         description="A planned AI implementation that gets its own implementation assessment.",
         name_field=dict(label="Use Case Name", type="Text"), sharing="ReadWrite",
         fields=[
             dict(name="Status__c", label="Status", type="Picklist",
                  values=["Idea", "Assessing", "Approved", "Live", "Rejected"]),
             dict(name="Description__c", label="Description", type="LongTextArea",
                  help="What is the use case?"),
             dict(name="Added_Value__c", label="Added Value", type="LongTextArea",
                  help="How does it add value?"),
             dict(name="What_We_Lose__c", label="What We Lose", type="LongTextArea",
                  help="What will you lose by introducing AI here (for example personal contact)?"),
             dict(name="Mitigation__c", label="Mitigation", type="LongTextArea",
                  help="How will you manage what you lose?"),
             dict(name="Handover_Points__c", label="Handover Points", type="LongTextArea",
                  help="When does the AI hand over to a person, and to and from the end client?"),
             dict(name="Success_Criteria__c", label="Success Criteria", type="LongTextArea",
                  help="When will this AI implementation be considered a success?"),
             dict(name="Expected_Costs__c", label="Expected Costs", type="Currency"),
             dict(name="Expected_Gains__c", label="Expected Gains", type="Currency"),
             dict(name="Cost_Benefit_Notes__c", label="Cost vs Gains Notes", type="LongTextArea",
                  help="Do the expected costs weigh up to the expected gains?"),
             dict(name="Data_In_Scope__c", label="Data In Scope", type="LongTextArea",
                  help="Which data will the AI touch? Describe it in plain words."),
             dict(name="Grounding_Fields__c", label="Grounding Fields", type="LongTextArea", lines=6,
                  help="One field per line as Object.Field (for example Contact.Email). The data quality checks for this use case run on these fields."),
             dict(name="Agent_User__c", label="AI Integration User", type="Lookup", ref="User",
                  rel_label="AI Use Cases (Integration User)", rel_name="AIR_Agent_Use_Cases",
                  help="The dedicated integration user this AI connects as. Never a System Administrator. The access checks for this use case run against this user."),
             dict(name="Business_Owner__c", label="Business Owner", type="Text", length=120),
         ]),
    dict(name="AIR_Assessment__c", label="AI Readiness Assessment", plural="AI Readiness Assessments",
         description="One assessment run at Company, Org or Implementation level.",
         name_field=dict(label="Assessment", type="AutoNumber", format="AIR-{0000}"), sharing="ReadWrite",
         fields=[
             dict(name="Level__c", label="Level", type="Picklist", values=["Company", "Org", "Implementation"]),
             dict(name="Use_Case__c", label="Use Case", type="Lookup", ref="AIR_Use_Case__c",
                  rel_label="Assessments", rel_name="Assessments"),
             dict(name="Run_Date__c", label="Run Date", type="DateTime"),
             dict(name="Score__c", label="Score", type="Percent"),
             dict(name="Coverage__c", label="Checks Completed", type="Percent"),
             dict(name="Passed_Count__c", label="Passed", type="Number"),
             dict(name="Attention_Count__c", label="Needs Attention", type="Number"),
             dict(name="Not_Checked_Count__c", label="Not Checked", type="Number"),
             dict(name="Critical_Failures__c", label="Critical Failures", type="Number"),
             dict(name="Health__c", label="Health", type="Text", length=30),
             dict(name="DPO_Name__c", label="Data Protection Officer", type="Text", length=120),
             dict(name="Security_Owner__c", label="Security Owner", type="Text", length=120),
             dict(name="Admin_Owner__c", label="Salesforce Admin Owner", type="Text", length=120),
             dict(name="DPO_Not_Required_Reason__c", label="Why No DPO Is Required", type="LongTextArea"),
             dict(name="Stakeholders__c", label="Stakeholders", type="LongTextArea",
                  help="Other people or roles involved: management, board, external partner or consultancy."),
         ]),
    dict(name="AIR_Assessment_Result__c", label="AI Readiness Result", plural="AI Readiness Results",
         description="The result of one check within one assessment.",
         name_field=dict(label="Result", type="AutoNumber", format="R-{00000}"), sharing="ControlledByParent",
         fields=[
             dict(name="Assessment__c", label="Assessment", type="MasterDetail", ref="AIR_Assessment__c",
                  rel_label="Results", rel_name="Results"),
             dict(name="Check_Code__c", label="Check Code", type="Text", length=40),
             dict(name="Check_Title__c", label="Check", type="Text", length=80),
             dict(name="Category__c", label="Category", type="Text", length=20),
             dict(name="Topic__c", label="Topic", type="Text", length=5),
             dict(name="Critical__c", label="Critical", type="Checkbox"),
             dict(name="Check_Type__c", label="Check Type", type="Text", length=20),
             dict(name="Status__c", label="Status", type="Picklist", values=STATUS),
             dict(name="Evidence__c", label="Evidence", type="LongTextArea"),
             dict(name="Answer__c", label="Answer", type="Picklist", values=["Yes", "Partially", "No", "Not sure"]),
             dict(name="Notes__c", label="Notes", type="LongTextArea"),
             dict(name="Responsible__c", label="Responsible", type="Text", length=120),
             dict(name="Due_Date__c", label="Due Date", type="Date"),
         ]),
]

CMDT_FIELDS = [
    dict(name="Category__c", label="Category", type="Text", length=20),
    dict(name="Topic__c", label="Topic", type="Text", length=5),
    dict(name="Level__c", label="Level", type="Text", length=20),
    dict(name="Check_Type__c", label="Check Type", type="Text", length=20),
    dict(name="Critical__c", label="Critical", type="Checkbox"),
    dict(name="Question__c", label="Question", type="LongTextArea", length=2000, lines=3),
    dict(name="Pass_Criteria__c", label="Pass Criteria", type="TextArea"),
    dict(name="Advice__c", label="Advice", type="LongTextArea", length=4000, lines=4),
    dict(name="Resources__c", label="Resources", type="LongTextArea", length=2000, lines=3),
    dict(name="Handler__c", label="Handler", type="Text", length=80),
    dict(name="Sort_Order__c", label="Sort Order", type="Number", precision=4, scale=0),
    dict(name="Active__c", label="Active", type="Checkbox", default=True),
]


def gen_objects():
    for o in OBJECTS:
        nf = o["name_field"]
        if nf["type"] == "AutoNumber":
            name_xml = (f"<nameField><displayFormat>{nf['format']}</displayFormat><label>{e(nf['label'])}</label>"
                        "<trackHistory>false</trackHistory><type>AutoNumber</type></nameField>")
        else:
            name_xml = (f"<nameField><label>{e(nf['label'])}</label><trackHistory>false</trackHistory>"
                        "<type>Text</type></nameField>")
        write(f"objects/{o['name']}/{o['name']}.object-meta.xml", f"""
<CustomObject {NS}>
    <allowInChatterGroups>false</allowInChatterGroups>
    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>
    <deploymentStatus>Deployed</deploymentStatus>
    <description>{e(o['description'])}</description>
    <enableActivities>false</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>false</enableHistory>
    <enableLicensing>false</enableLicensing>
    <enableReports>true</enableReports>
    <enableSearch>{'true' if o['name'] == 'AIR_Use_Case__c' else 'false'}</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <label>{e(o['label'])}</label>
    {name_xml}
    <pluralLabel>{e(o['plural'])}</pluralLabel>
    <sharingModel>{o['sharing']}</sharingModel>
    <visibility>Public</visibility>
</CustomObject>""")
        for f in o["fields"]:
            write(f"objects/{o['name']}/fields/{f['name']}.field-meta.xml", field_xml(f))

    write("objects/AIR_Check__mdt/AIR_Check__mdt.object-meta.xml", f"""
<CustomObject {NS}>
    <description>AI Readiness check catalogue. One record per check.</description>
    <label>AIR Check</label>
    <pluralLabel>AIR Checks</pluralLabel>
    <visibility>Public</visibility>
</CustomObject>""")
    for f in CMDT_FIELDS:
        write(f"objects/AIR_Check__mdt/fields/{f['name']}.field-meta.xml", field_xml(f, cmdt=True))


# --------------------------------------------------------------------------- CMDT records
def gen_checks():
    out = os.path.join(ROOT, "customMetadata")
    if os.path.isdir(out):
        shutil.rmtree(out)
    codes = set()
    for i, c in enumerate(CHECKS):
        assert len(c["label"]) <= 40, c["label"]
        assert c["code"] not in codes, c["code"]
        assert c["category"] in ("DQ", "ACCESS", "STAFF", "PRIVACY")
        assert c["level"] in ("Company", "Org", "Implementation")
        assert c["type"] in ("Automated", "Manual")
        assert (c["type"] == "Automated") == bool(c["handler"]), c["code"]
        codes.add(c["code"])

        def sv(field, value):
            if value is None or value == "":
                return f'<values><field>{field}</field><value xsi:nil="true"/></values>'
            return f'<values><field>{field}</field><value xsi:type="xsd:string">{e(value)}</value></values>'

        vals = [
            '<values><field>Active__c</field><value xsi:type="xsd:boolean">true</value></values>',
            sv("Advice__c", c["advice"]),
            sv("Category__c", c["category"]),
            sv("Check_Type__c", c["type"]),
            f'<values><field>Critical__c</field><value xsi:type="xsd:boolean">{"true" if c["critical"] else "false"}</value></values>',
            sv("Handler__c", c["handler"]),
            sv("Level__c", c["level"]),
            sv("Pass_Criteria__c", c["pass_criteria"]),
            sv("Question__c", c["question"]),
            sv("Resources__c", c["resources"]),
            f'<values><field>Sort_Order__c</field><value xsi:type="xsd:double">{(i + 1) * 10}</value></values>',
            sv("Topic__c", c["topic"]),
        ]
        write(f"customMetadata/AIR_Check.{c['code']}.md-meta.xml", f"""
<CustomMetadata {NS} xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>{e(c['label'])}</label>
    <protected>false</protected>
    {''.join(vals)}
</CustomMetadata>""")
    return len(CHECKS)


# --------------------------------------------------------------------------- UI metadata
PAGES = [
    # tab api name, label, lwc, motif
    ("AIR_Home", "AI Readiness", "airHome", "Custom91: Shield"),
    ("AIR_Org_Scan", "Org Scan", "airScanResults", "Custom39: Telescope"),
    ("AIR_Checklists", "Checklists", "airChecklistWizard", "Custom18: Form"),
    ("AIR_Use_Cases", "Use Cases", "airUseCases", "Custom67: Gears"),
]
OBJECT_TABS = [("AIR_Assessment__c", "Custom62: Chalkboard"), ("AIR_Use_Case__c", "Custom9: Lightning")]
CLASSES = ["AIR_Controller", "AIR_ScanService", "AIR_ScoreService",
           "AIR_AutomatedChecks", "AIR_CheckOutcome", "AIR_CheckContext", "AIR_Catalogue"]


def gen_ui():
    for api, label, cmp, motif in PAGES:
        write(f"flexipages/{api}.flexipage-meta.xml", f"""
<FlexiPage {NS}>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentName>{cmp}</componentName>
                <identifier>c_{cmp}</identifier>
            </componentInstance>
        </itemInstances>
        <name>main</name>
        <type>Region</type>
    </flexiPageRegions>
    <masterLabel>{e(label)}</masterLabel>
    <template>
        <name>flexipage:defaultAppHomeTemplate</name>
    </template>
    <type>AppPage</type>
</FlexiPage>""")
        write(f"tabs/{api}.tab-meta.xml", f"""
<CustomTab {NS}>
    <flexiPage>{api}</flexiPage>
    <label>{e(label)}</label>
    <motif>{motif}</motif>
</CustomTab>""")
    for obj, motif in OBJECT_TABS:
        write(f"tabs/{obj}.tab-meta.xml", f"""
<CustomTab {NS}>
    <customObject>true</customObject>
    <motif>{motif}</motif>
</CustomTab>""")

    tabs = "".join(f"<tabs>{t}</tabs>" for t in [p[0] for p in PAGES] + [o[0] for o in OBJECT_TABS])
    write("applications/AIR_AI_Readiness.app-meta.xml", f"""
<CustomApplication {NS}>
    <brand>
        <headerColor>#0B5CAB</headerColor>
        <shouldOverrideOrgTheme>false</shouldOverrideOrgTheme>
    </brand>
    <description>AI Readiness Check: how ready are your org and organisation to use AI?</description>
    <formFactors>Large</formFactors>
    <isNavAutoTempTabsDisabled>false</isNavAutoTempTabsDisabled>
    <isNavPersonalizationDisabled>false</isNavPersonalizationDisabled>
    <isNavTabPersistenceDisabled>false</isNavTabPersistenceDisabled>
    <label>AI Readiness Check</label>
    <navType>Standard</navType>
    {tabs}
    <uiType>Lightning</uiType>
</CustomApplication>""")

    # permission set
    fps, ops = [], []
    for o in OBJECTS:
        ops.append(f"<objectPermissions><allowCreate>true</allowCreate><allowDelete>true</allowDelete>"
                   f"<allowEdit>true</allowEdit><allowRead>true</allowRead><modifyAllRecords>false</modifyAllRecords>"
                   f"<object>{o['name']}</object><viewAllRecords>false</viewAllRecords></objectPermissions>")
        for f in o["fields"]:
            if f["type"] == "MasterDetail":
                continue
            fps.append(f"<fieldPermissions><editable>true</editable><field>{o['name']}.{f['name']}</field>"
                       f"<readable>true</readable></fieldPermissions>")
    classes = "".join(f"<classAccesses><apexClass>{c}</apexClass><enabled>true</enabled></classAccesses>"
                      for c in CLASSES)
    tabsettings = "".join(f"<tabSettings><tab>{t}</tab><visibility>Visible</visibility></tabSettings>"
                          for t in [p[0] for p in PAGES] + [o[0] for o in OBJECT_TABS])
    write("permissionsets/AIR_Admin.permissionset-meta.xml", f"""
<PermissionSet {NS}>
    <applicationVisibilities>
        <application>AIR_AI_Readiness</application>
        <visible>true</visible>
    </applicationVisibilities>
    {classes}
    <customMetadataTypeAccesses>
        <enabled>true</enabled>
        <name>AIR_Check__mdt</name>
    </customMetadataTypeAccesses>
    <description>Full access to the AI Readiness Check app. Assign to the admins who run the assessment.</description>
    {''.join(sorted(fps))}
    <hasActivationRequired>false</hasActivationRequired>
    <label>AI Readiness Admin</label>
    {''.join(ops)}
    {tabsettings}
</PermissionSet>""")


if __name__ == "__main__":
    gen_objects()
    n = gen_checks()
    gen_ui()
    print(f"Generated objects, {n} checks, UI metadata and permission set.")
