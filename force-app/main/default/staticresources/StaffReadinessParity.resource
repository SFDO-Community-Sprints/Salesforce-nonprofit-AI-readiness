[
  {
    "name": "all_pass",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 7,
        "applicable": 7,
        "score": "100.0",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_evidence_complete",
      "follow_up": []
    }
  },
  {
    "name": "all_unknown",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": []
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "unknown",
          "sensitive_data": "unknown",
          "untrusted_content": "unknown",
          "access": "unknown",
          "quality": "unknown",
          "review": "unknown",
          "incident": "unknown"
        },
        "passed": 0,
        "applicable": 7,
        "score": "0.0",
        "coverage": "0.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        },
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        },
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        },
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        },
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        },
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        },
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "all_fail",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "fail",
          "sensitive_data": "fail",
          "untrusted_content": "fail",
          "access": "fail",
          "quality": "fail",
          "review": "fail",
          "incident": "fail"
        },
        "passed": 0,
        "applicable": 7,
        "score": "0.0",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        },
        {
          "question_id": "sensitive_data",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        },
        {
          "question_id": "untrusted_content",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        },
        {
          "question_id": "access",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        },
        {
          "question_id": "quality",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        },
        {
          "question_id": "review",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        },
        {
          "question_id": "incident",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "one_of_seven",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "unknown",
          "untrusted_content": "unknown",
          "access": "unknown",
          "quality": "unknown",
          "review": "unknown",
          "incident": "unknown"
        },
        "passed": 1,
        "applicable": 7,
        "score": "14.3",
        "coverage": "14.3"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        },
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        },
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        },
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        },
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        },
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "scope_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "fail",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        }
      ]
    }
  },
  {
    "name": "scope_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "unknown",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        }
      ]
    }
  },
  {
    "name": "scope_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "unknown",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        }
      ]
    }
  },
  {
    "name": "scope_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "unknown",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        }
      ]
    }
  },
  {
    "name": "scope_unapproved_decision",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": [
            "unapproved_decision"
          ]
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "fail",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "scope:unapproved_decision"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        }
      ]
    }
  },
  {
    "name": "sensitive_data_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "fail",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ]
    }
  },
  {
    "name": "sensitive_data_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "unknown",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ]
    }
  },
  {
    "name": "sensitive_data_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "unknown",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ]
    }
  },
  {
    "name": "sensitive_data_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "unknown",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ]
    }
  },
  {
    "name": "sensitive_data_sensitive_disclosure",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": [
            "sensitive_disclosure"
          ]
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "fail",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "sensitive_data:sensitive_disclosure"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ]
    }
  },
  {
    "name": "sensitive_data_false_erasure_claim",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": [
            "false_erasure_claim"
          ]
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "fail",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "sensitive_data:false_erasure_claim"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ]
    }
  },
  {
    "name": "untrusted_content_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "fail",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "untrusted_content",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        }
      ]
    }
  },
  {
    "name": "untrusted_content_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "unknown",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        }
      ]
    }
  },
  {
    "name": "untrusted_content_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "unknown",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        }
      ]
    }
  },
  {
    "name": "untrusted_content_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "unknown",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        }
      ]
    }
  },
  {
    "name": "untrusted_content_obeys_injection",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": [
            "obeys_injection"
          ]
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "fail",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "untrusted_content:obeys_injection"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "untrusted_content",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        }
      ]
    }
  },
  {
    "name": "untrusted_content_accepts_fabrication",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": [
            "accepts_fabrication"
          ]
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "fail",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "untrusted_content:accepts_fabrication"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "untrusted_content",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        }
      ]
    }
  },
  {
    "name": "access_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "fail",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "access",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        }
      ]
    }
  },
  {
    "name": "access_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "unknown",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        }
      ]
    }
  },
  {
    "name": "access_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "unknown",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        }
      ]
    }
  },
  {
    "name": "access_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "unknown",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        }
      ]
    }
  },
  {
    "name": "access_forbidden_operation_allowed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": [
            "forbidden_operation_allowed"
          ]
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "fail",
          "quality": "pass",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "access:forbidden_operation_allowed"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "access",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        }
      ]
    }
  },
  {
    "name": "quality_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "fail",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "quality",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        }
      ]
    }
  },
  {
    "name": "quality_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "unknown",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        }
      ]
    }
  },
  {
    "name": "quality_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "unknown",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        }
      ]
    }
  },
  {
    "name": "quality_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "unknown",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        }
      ]
    }
  },
  {
    "name": "quality_fabricates_source_data",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": [
            "fabricates_source_data"
          ]
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "fail",
          "review": "pass",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "quality:fabricates_source_data"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "quality",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        }
      ]
    }
  },
  {
    "name": "review_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "fail",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "review",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        }
      ]
    }
  },
  {
    "name": "review_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "unknown",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        }
      ]
    }
  },
  {
    "name": "review_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "unknown",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        }
      ]
    }
  },
  {
    "name": "review_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "unknown",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        }
      ]
    }
  },
  {
    "name": "review_unapproved_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": [
            "unapproved_action"
          ]
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "fail",
          "incident": "pass"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "review:unapproved_action"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "review",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        }
      ]
    }
  },
  {
    "name": "incident_failed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "no",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "fail"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "incident",
          "priority": "High",
          "impact": "Required staff actions were not fully demonstrated.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "incident_missing_action",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "unknown"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "incident_missing_ref",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": null,
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "unknown"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "incident_unconfirmed",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": false,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "unknown"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "85.7"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "incident_cannot_stop",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": [
            "cannot_stop"
          ]
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "fail"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "incident:cannot_stop"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "incident",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "incident_unsafe_recovery",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": [
            "unsafe_recovery"
          ]
        }
      ]
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "pass",
          "untrusted_content": "pass",
          "access": "pass",
          "quality": "pass",
          "review": "pass",
          "incident": "fail"
        },
        "passed": 6,
        "applicable": 7,
        "score": "85.7",
        "coverage": "100.0"
      },
      "critical_failures": [
        "incident:unsafe_recovery"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "incident",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "freshness_boundary",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ],
      "freshness_policy": {
        "as_of": "2026-10-19",
        "max_age_days": 30,
        "observed_on": {
          "scope": "2026-09-19",
          "sensitive_data": "2026-09-18"
        }
      }
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "pass",
          "sensitive_data": "unknown",
          "untrusted_content": "unknown",
          "access": "unknown",
          "quality": "unknown",
          "review": "unknown",
          "incident": "unknown"
        },
        "passed": 1,
        "applicable": 7,
        "score": "14.3",
        "coverage": "14.3"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        },
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        },
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        },
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        },
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        },
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "freshness_missing",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ],
      "freshness_policy": {
        "as_of": "2026-10-19",
        "max_age_days": 30,
        "observed_on": {}
      }
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "unknown",
          "sensitive_data": "unknown",
          "untrusted_content": "unknown",
          "access": "unknown",
          "quality": "unknown",
          "review": "unknown",
          "incident": "unknown"
        },
        "passed": 0,
        "applicable": 7,
        "score": "0.0",
        "coverage": "0.0"
      },
      "critical_failures": [],
      "decision": "staff_readiness_not_established",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        },
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        },
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        },
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        },
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        },
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        },
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  },
  {
    "name": "freshness_preserves_critical",
    "snapshot": {
      "version": "staff-readiness-v1",
      "mode": "actual",
      "reviews": [
        {
          "question_id": "scope",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "identify_scope": "yes",
            "human_boundary": "yes",
            "escalate": "yes"
          },
          "critical_failures": [
            "unapproved_decision"
          ]
        },
        {
          "question_id": "sensitive_data",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "exclude_sensitive": "yes",
            "purpose_rules": "yes",
            "trace_erasure": "yes",
            "privacy_owner": "yes",
            "verify_removal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "untrusted_content",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "verify_source": "yes",
            "refuse_instruction": "yes",
            "report_issue": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "access",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "map_access": "yes",
            "positive_probe": "yes",
            "negative_probe": "yes",
            "reject_admin_proof": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "quality",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "measured_quality": "yes",
            "handle_conflict": "yes",
            "steward": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "review",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "catch_unsafe_output": "yes",
            "approval_enforced": "yes",
            "safe_rehearsal": "yes"
          },
          "critical_failures": []
        },
        {
          "question_id": "incident",
          "answer": "yes",
          "reviewer_confirmed": true,
          "evidence_ref": "private_parity_ref",
          "actions": {
            "detect_escalate": "yes",
            "stop": "yes",
            "recover": "yes",
            "maintain": "yes"
          },
          "critical_failures": []
        }
      ],
      "freshness_policy": {
        "as_of": "2026-10-19",
        "max_age_days": 0,
        "observed_on": {}
      }
    },
    "expected": {
      "staff": {
        "checks": {
          "scope": "fail",
          "sensitive_data": "unknown",
          "untrusted_content": "unknown",
          "access": "unknown",
          "quality": "unknown",
          "review": "unknown",
          "incident": "unknown"
        },
        "passed": 0,
        "applicable": 7,
        "score": "0.0",
        "coverage": "14.3"
      },
      "critical_failures": [
        "scope:unapproved_decision"
      ],
      "decision": "blocked_by_observed_critical_failure",
      "follow_up": [
        {
          "question_id": "scope",
          "priority": "Critical",
          "impact": "An observed unsafe action blocks a pilot until corrected and retested.",
          "next_step": "Demonstrate: Explain the approved donor-summary scope and excluded decisions. Reserve eligibility, safeguarding, awards and payments for the approved human decision process. Demonstrate the documented escalation route and approved scope artifact."
        },
        {
          "question_id": "sensitive_data",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Keep sensitive notes out of unapproved tools and use approved minimized evidence. Explain the approved purpose and data-handling rules; donation does not authorize every AI use. Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process. Identify the privacy owner and route retention exceptions for review. Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        },
        {
          "question_id": "untrusted_content",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Compare the donation claim with its source and reject unsupported content. Treat the source instruction as untrusted and refuse the export. Report the suspicious source and unsupported claim through the approved route."
        },
        {
          "question_id": "access",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed. Observe an allowed operation under the intended identity in an authorized isolated exercise. Observe a forbidden read or action denied under that same identity. Explain why an administrator's successful test does not prove the assistant's access is restricted."
        },
        {
          "question_id": "quality",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds. Flag missing or conflicting information without inventing or merging values. Identify the data steward and demonstrate the correction/escalation process."
        },
        {
          "question_id": "review",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the unsafe disclosure and proposed consequential change. Observe that sending or changing is blocked until the authorized trained reviewer approves. Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        },
        {
          "question_id": "incident",
          "priority": "Medium",
          "impact": "Staff capability has not been established by confirmed evidence.",
          "next_step": "Demonstrate: Identify the operational owner and use appropriate monitoring and escalation. Demonstrate the approved disable/stop path in an authorized isolated exercise. Rehearse recovery for allowed writes, or document why write recovery is inapplicable. Identify who updates training and controls after changes."
        }
      ]
    }
  }
]
