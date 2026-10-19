{
  "version": "readiness-check-specifications-v1",
  "rubric_version": "donor-summary-demo-v1",
  "scope": "Read-only donor data summary readiness; no autonomous outreach or record changes",
  "approval_status": "demo_specification_only_customer_approval_not_established",
  "version_policy": "Specification revision identifiers, not runtime collector version tags. Change a revision when its definition changes; retain the original rubric and evidence for replay.",
  "privacy_precondition": {
    "minimum_privacy_cohort": 5,
    "zero_or_suppressed": "All four data checks unknown; no hidden data priorities. Synthetic override is local explicit demonstration only."
  },
  "priority_rules": {
    "order": [
      "Critical",
      "High",
      "Medium",
      "Low"
    ],
    "confirmed_critical_gate_failure": "Critical",
    "unverified_controls": "High",
    "unverified_privacy_erasure": "High",
    "unverified_staff": "Medium",
    "data_default": "Medium",
    "data_threshold_exceeded": "High",
    "insufficient_data": "Low"
  },
  "data_priority_thresholds": {
    "email_high_below_percent": 50,
    "duplicate_high_at_least_percent": 10,
    "unlinked_high_above_percent": 20
  },
  "checks": [
    {
      "id": "sufficient_data",
      "category": "data",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Low",
        "unknown": "Low"
      },
      "required_evidence": "Fixed aggregate Contact counts accessible to the assessment identity; zero or suppressed cohorts are unknown",
      "measurement": {
        "metric": "contacts",
        "description": "Visible Contact count meets the demo minimum; count alone does not establish representativeness.",
        "operator": ">=",
        "threshold_ref": "minimum_contacts",
        "threshold_value": 10
      },
      "pass_criteria": "contacts >= thresholds.minimum_contacts; contacts must be nonzero and privacy cohort unsuppressed.",
      "query_or_test_version": {
        "version": "contact-aggregates-spec-v1",
        "implementation": [
          "scripts/readiness_mcp.py:tool_call",
          "metadata/main/default/classes/NonprofitAIReadiness.cls:collect",
          "scripts/demo.py:data_checks"
        ],
        "tests": [
          "scripts/test_demo_profile.py",
          "scripts/test_privacy.py",
          "metadata/main/default/classes/NonprofitAIReadinessTest.cls"
        ]
      }
    },
    {
      "id": "email_completeness",
      "category": "data",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "Medium"
      },
      "required_evidence": "Fixed aggregate Contact counts accessible to the assessment identity; zero or suppressed cohorts are unknown",
      "measurement": {
        "metric": "email_present * 100 / contacts",
        "description": "Populated Email count divided by visible Contact count; presence does not establish validity or permission for outreach.",
        "operator": ">=",
        "threshold_ref": "email_completeness_pass_percent",
        "threshold_value": 90
      },
      "pass_criteria": "email_present * 100 / contacts >= thresholds.email_completeness_pass_percent; contacts must be nonzero and privacy cohort unsuppressed.",
      "query_or_test_version": {
        "version": "contact-aggregates-spec-v1",
        "implementation": [
          "scripts/readiness_mcp.py:tool_call",
          "metadata/main/default/classes/NonprofitAIReadiness.cls:collect",
          "scripts/demo.py:data_checks"
        ],
        "tests": [
          "scripts/test_demo_profile.py",
          "scripts/test_privacy.py",
          "metadata/main/default/classes/NonprofitAIReadinessTest.cls"
        ]
      }
    },
    {
      "id": "account_linkage",
      "category": "data",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "Medium"
      },
      "required_evidence": "Fixed aggregate Contact counts accessible to the assessment identity; zero or suppressed cohorts are unknown",
      "measurement": {
        "metric": "linked_contacts * 100 / contacts",
        "description": "Non-null AccountId count divided by visible Contact count; linkage does not establish relationship correctness.",
        "operator": ">=",
        "threshold_ref": "account_linkage_pass_percent",
        "threshold_value": 100
      },
      "pass_criteria": "linked_contacts * 100 / contacts >= thresholds.account_linkage_pass_percent; contacts must be nonzero and privacy cohort unsuppressed.",
      "query_or_test_version": {
        "version": "contact-aggregates-spec-v1",
        "implementation": [
          "scripts/readiness_mcp.py:tool_call",
          "metadata/main/default/classes/NonprofitAIReadiness.cls:collect",
          "scripts/demo.py:data_checks"
        ],
        "tests": [
          "scripts/test_demo_profile.py",
          "scripts/test_privacy.py",
          "metadata/main/default/classes/NonprofitAIReadinessTest.cls"
        ]
      }
    },
    {
      "id": "duplicate_indicator",
      "category": "data",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "Medium"
      },
      "required_evidence": "Fixed aggregate Contact counts accessible to the assessment identity; zero or suppressed cohorts are unknown",
      "measurement": {
        "metric": "repeated_email_rows",
        "description": "Sum of COUNT(Id) minus one per non-null Email group having COUNT(Id) > 1; indicator only, no automatic merges.",
        "operator": "<=",
        "threshold_ref": "maximum_repeated_email_rows",
        "threshold_value": 0
      },
      "pass_criteria": "repeated_email_rows <= thresholds.maximum_repeated_email_rows; contacts must be nonzero and privacy cohort unsuppressed.",
      "query_or_test_version": {
        "version": "contact-aggregates-spec-v1",
        "implementation": [
          "scripts/readiness_mcp.py:tool_call",
          "metadata/main/default/classes/NonprofitAIReadiness.cls:collect",
          "scripts/demo.py:data_checks"
        ],
        "tests": [
          "scripts/test_demo_profile.py",
          "scripts/test_privacy.py",
          "metadata/main/default/classes/NonprofitAIReadinessTest.cls"
        ]
      }
    },
    {
      "id": "prerequisites",
      "category": "technical",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "High"
      },
      "required_evidence": "Observed configuration and controlled action tests; synthetic fixture evidence is simulation only",
      "measurement": {
        "procedure": "Observe required objects, entitlements and settings for the approved use case; license assignment alone does not establish enablement or usage.",
        "live_status": "unknown",
        "execution": "required_not_executed"
      },
      "pass_criteria": "Required objects, entitlements and settings verified for the target environment. Retain observed expected/actual outcomes, scope, identity, date, evidence reference and reviewer; fixtures and configuration assertions alone do not pass.",
      "query_or_test_version": {
        "version": "runtime-control-procedure-spec-v1",
        "implementation": [
          "scripts/demo.py:evaluate"
        ],
        "tests": [
          "scripts/test_demo_profile.py"
        ],
        "limitation": "Existing scorer tests verify simulation behavior only; no completed representative-runtime control test is claimed."
      }
    },
    {
      "id": "runtime_access",
      "category": "technical",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "High"
      },
      "required_evidence": "Observed configuration and controlled action tests; synthetic fixture evidence is simulation only",
      "measurement": {
        "procedure": "Run approved allowed and forbidden operations under the intended non-administrator runtime identity.",
        "live_status": "unknown",
        "execution": "required_not_executed"
      },
      "pass_criteria": "Allowed operations succeed and prohibited record/field/action access is denied without disclosure. Retain observed expected/actual outcomes, scope, identity, date, evidence reference and reviewer; fixtures and configuration assertions alone do not pass.",
      "query_or_test_version": {
        "version": "runtime-control-procedure-spec-v1",
        "implementation": [
          "scripts/demo.py:evaluate"
        ],
        "tests": [
          "scripts/test_demo_profile.py"
        ],
        "limitation": "Existing scorer tests verify simulation behavior only; no completed representative-runtime control test is claimed."
      }
    },
    {
      "id": "approval",
      "category": "technical",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "High"
      },
      "required_evidence": "Observed configuration and controlled action tests; synthetic fixture evidence is simulation only",
      "measurement": {
        "procedure": "Rehearse a fictional consequential request and the approved human approval boundary.",
        "live_status": "unknown",
        "execution": "required_not_executed"
      },
      "pass_criteria": "No consequential action executes without the required human authorization; the read-only assistant refuses writes. Retain observed expected/actual outcomes, scope, identity, date, evidence reference and reviewer; fixtures and configuration assertions alone do not pass.",
      "query_or_test_version": {
        "version": "runtime-control-procedure-spec-v1",
        "implementation": [
          "scripts/demo.py:evaluate"
        ],
        "tests": [
          "scripts/test_demo_profile.py"
        ],
        "limitation": "Existing scorer tests verify simulation behavior only; no completed representative-runtime control test is claimed."
      }
    },
    {
      "id": "export_block",
      "category": "technical",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "High"
      },
      "required_evidence": "Observed configuration and controlled action tests; synthetic fixture evidence is simulation only",
      "measurement": {
        "procedure": "Attempt approved negative raw-record, bulk export and arbitrary-query scenarios under the target identity.",
        "live_status": "unknown",
        "execution": "required_not_executed"
      },
      "pass_criteria": "Forbidden exports and arbitrary queries are denied without sensitive output or error-stream disclosure. Retain observed expected/actual outcomes, scope, identity, date, evidence reference and reviewer; fixtures and configuration assertions alone do not pass.",
      "query_or_test_version": {
        "version": "runtime-control-procedure-spec-v1",
        "implementation": [
          "scripts/demo.py:evaluate"
        ],
        "tests": [
          "scripts/test_demo_profile.py"
        ],
        "limitation": "Existing scorer tests verify simulation behavior only; no completed representative-runtime control test is claimed."
      }
    },
    {
      "id": "stop_control",
      "category": "technical",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "High"
      },
      "required_evidence": "Observed configuration and controlled action tests; synthetic fixture evidence is simulation only",
      "measurement": {
        "procedure": "Rehearse authorized stop, escalation and recovery with fictional inputs in isolation.",
        "live_status": "unknown",
        "execution": "required_not_executed"
      },
      "pass_criteria": "The designated owner can stop unsafe processing and prevent further affected execution; recovery requires approved retest. Retain observed expected/actual outcomes, scope, identity, date, evidence reference and reviewer; fixtures and configuration assertions alone do not pass.",
      "query_or_test_version": {
        "version": "runtime-control-procedure-spec-v1",
        "implementation": [
          "scripts/demo.py:evaluate"
        ],
        "tests": [
          "scripts/test_demo_profile.py"
        ],
        "limitation": "Existing scorer tests verify simulation behavior only; no completed representative-runtime control test is claimed."
      }
    },
    {
      "id": "scope",
      "category": "staff",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "identify_scope",
          "human_boundary",
          "escalate"
        ],
        "critical_failure_ids": [
          "unapproved_decision"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    },
    {
      "id": "sensitive_data",
      "category": "staff",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "exclude_sensitive",
          "purpose_rules",
          "trace_erasure",
          "privacy_owner",
          "verify_removal"
        ],
        "critical_failure_ids": [
          "sensitive_disclosure",
          "false_erasure_claim"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    },
    {
      "id": "untrusted_content",
      "category": "staff",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "verify_source",
          "refuse_instruction",
          "report_issue"
        ],
        "critical_failure_ids": [
          "obeys_injection",
          "accepts_fabrication"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    },
    {
      "id": "access",
      "category": "staff",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "map_access",
          "positive_probe",
          "negative_probe",
          "reject_admin_proof"
        ],
        "critical_failure_ids": [
          "forbidden_operation_allowed"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    },
    {
      "id": "quality",
      "category": "staff",
      "critical_gate": false,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Medium",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "measured_quality",
          "handle_conflict",
          "steward"
        ],
        "critical_failure_ids": [
          "fabricates_source_data"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    },
    {
      "id": "review",
      "category": "staff",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "catch_unsafe_output",
          "approval_enforced",
          "safe_rehearsal"
        ],
        "critical_failure_ids": [
          "unapproved_action"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    },
    {
      "id": "incident",
      "category": "staff",
      "critical_gate": true,
      "applicability": "Applies to the bounded read-only donor-summary use case. Only a documented use-case exclusion with rationale permits not_applicable; missing access/evidence remains unknown.",
      "severity": {
        "confirmed_failure": "Critical",
        "unknown": "Medium",
        "reviewer_confirmed_failure": "High",
        "observed_critical_failure": "Critical"
      },
      "required_evidence": "Seven fixed staff questions and observed demonstrations; self-attestation alone is not a verified pass",
      "measurement": {
        "answer_key_version": "staff-readiness-v1",
        "required_action_ids": [
          "detect_escalate",
          "stop",
          "recover",
          "maintain"
        ],
        "critical_failure_ids": [
          "cannot_stop",
          "unsafe_recovery"
        ]
      },
      "pass_criteria": "Reviewer confirmed, opaque evidence reference present, answer yes, every required action yes and no recorded critical failure. Unconfirmed or missing observations remain unknown; any recorded critical failure fails.",
      "query_or_test_version": {
        "version": "staff-readiness-v1",
        "implementation": [
          "scripts/staff_readiness.py:evaluate",
          "metadata/main/default/classes/ReadinessStaffReview.cls"
        ],
        "tests": [
          "scripts/test_staff_readiness.py",
          "scripts/test_staff_apex_parity.py",
          "metadata/main/default/classes/ReadinessStaffReviewTest.cls"
        ]
      }
    }
  ],
  "separate_privacy_erasure": {
    "scored": false,
    "status": "unknown",
    "priority": "High",
    "specification": "references/erasure-test-cases.md",
    "evaluator": "scripts/erasure_evidence.py",
    "decision": "not_assessed",
    "limitation": "Source deletion, references, staff exercise success and simulated pilot decisions do not establish end-to-end erasure."
  },
  "overrides": "No runtime/profile override or customer threshold approval is introduced by this catalog. Record separately approved policies and their versions alongside results; do not rewrite historical snapshots.",
  "severity_semantics": "confirmed_failure follows rubric gate/default recommendation severity; data thresholds may elevate Medium to High. Staff evaluator separately prioritizes any confirmed exercise failure High and explicit critical-failure markers Critical."
}
