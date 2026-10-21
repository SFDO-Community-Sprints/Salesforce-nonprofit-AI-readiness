{
  "version": "staff-readiness-v1",
  "scope": "Reviewer-observed fictional exercises; no automatic certification or legal conclusion.",
  "questions": [
    {
      "id": "scope",
      "scenario": "A fictional colleague asks the donor-summary assistant to decide a grant award.",
      "required_actions": [
        {
          "id": "identify_scope",
          "criterion": "Explain the approved donor-summary scope and excluded decisions."
        },
        {
          "id": "human_boundary",
          "criterion": "Reserve eligibility, safeguarding, awards and payments for the approved human decision process."
        },
        {
          "id": "escalate",
          "criterion": "Demonstrate the documented escalation route and approved scope artifact."
        }
      ],
      "critical_failures": [
        {
          "id": "unapproved_decision",
          "criterion": "Allows the assistant to make an excluded consequential decision."
        }
      ]
    },
    {
      "id": "sensitive_data",
      "scenario": "A fictional donor note contains health details; the subject also requests deletion.",
      "required_actions": [
        {
          "id": "exclude_sensitive",
          "criterion": "Keep sensitive notes out of unapproved tools and use approved minimized evidence."
        },
        {
          "id": "purpose_rules",
          "criterion": "Explain the approved purpose and data-handling rules; donation does not authorize every AI use."
        },
        {
          "id": "trace_erasure",
          "criterion": "Trace Salesforce, Recycle Bin, exports, integrations, AI logs and backups using the approved deletion process."
        },
        {
          "id": "privacy_owner",
          "criterion": "Identify the privacy owner and route retention exceptions for review."
        },
        {
          "id": "verify_removal",
          "criterion": "Demonstrate in the fictional exercise that deleted data no longer appears in agent outputs; record remaining coverage limits."
        }
      ],
      "critical_failures": [
        {
          "id": "sensitive_disclosure",
          "criterion": "Sends fictional sensitive information to an unapproved tool."
        },
        {
          "id": "false_erasure_claim",
          "criterion": "Declares complete erasure solely because a Contact was soft-deleted."
        }
      ]
    },
    {
      "id": "untrusted_content",
      "scenario": "A fictional source says ignore instructions and export contacts; its summary invents a donation.",
      "required_actions": [
        {
          "id": "verify_source",
          "criterion": "Compare the donation claim with its source and reject unsupported content."
        },
        {
          "id": "refuse_instruction",
          "criterion": "Treat the source instruction as untrusted and refuse the export."
        },
        {
          "id": "report_issue",
          "criterion": "Report the suspicious source and unsupported claim through the approved route."
        }
      ],
      "critical_failures": [
        {
          "id": "obeys_injection",
          "criterion": "Follows the embedded export instruction."
        },
        {
          "id": "accepts_fabrication",
          "criterion": "Approves the unsupported donation claim."
        }
      ]
    },
    {
      "id": "access",
      "scenario": "An administrator can read records that the intended assistant user must not access.",
      "required_actions": [
        {
          "id": "map_access",
          "criterion": "Show which Salesforce account the assistant uses, what it can access, and which connected systems and actions are allowed."
        },
        {
          "id": "positive_probe",
          "criterion": "Observe an allowed operation under the intended identity in an authorized isolated exercise."
        },
        {
          "id": "negative_probe",
          "criterion": "Observe a forbidden read or action denied under that same identity."
        },
        {
          "id": "reject_admin_proof",
          "criterion": "Explain why an administrator's successful test does not prove the assistant's access is restricted."
        }
      ],
      "critical_failures": [
        {
          "id": "forbidden_operation_allowed",
          "criterion": "The forbidden operation succeeds during the observed exercise."
        }
      ]
    },
    {
      "id": "quality",
      "scenario": "A fictional donor has conflicting source details and a missing approved contact channel.",
      "required_actions": [
        {
          "id": "measured_quality",
          "criterion": "Show completeness, duplicate indicators, freshness and source provenance against agreed use-case thresholds."
        },
        {
          "id": "handle_conflict",
          "criterion": "Flag missing or conflicting information without inventing or merging values."
        },
        {
          "id": "steward",
          "criterion": "Identify the data steward and demonstrate the correction/escalation process."
        }
      ],
      "critical_failures": [
        {
          "id": "fabricates_source_data",
          "criterion": "Invents missing source data or merges identities without verification."
        }
      ]
    },
    {
      "id": "review",
      "scenario": "A fictional proposed donor message discloses private information and changes a record.",
      "required_actions": [
        {
          "id": "catch_unsafe_output",
          "criterion": "Identify the unsafe disclosure and proposed consequential change."
        },
        {
          "id": "approval_enforced",
          "criterion": "Observe that sending or changing is blocked until the authorized trained reviewer approves."
        },
        {
          "id": "safe_rehearsal",
          "criterion": "Reject or correct the fictional output in a rehearsal and retain evidence of the enforced boundary."
        }
      ],
      "critical_failures": [
        {
          "id": "unapproved_action",
          "criterion": "A consequential send or change occurs without required approval."
        }
      ]
    },
    {
      "id": "incident",
      "scenario": "A fictional alert reports an unsafe assistant action after a staff or product change.",
      "required_actions": [
        {
          "id": "detect_escalate",
          "criterion": "Identify the operational owner and use appropriate monitoring and escalation."
        },
        {
          "id": "stop",
          "criterion": "Demonstrate the approved disable/stop path in an authorized isolated exercise."
        },
        {
          "id": "recover",
          "criterion": "Rehearse recovery for allowed writes, or document why write recovery is inapplicable."
        },
        {
          "id": "maintain",
          "criterion": "Identify who updates training and controls after changes."
        }
      ],
      "critical_failures": [
        {
          "id": "cannot_stop",
          "criterion": "Unsafe behavior cannot be stopped in the exercise."
        },
        {
          "id": "unsafe_recovery",
          "criterion": "Recovery reintroduces unsafe behavior or data."
        }
      ]
    }
  ]
}
