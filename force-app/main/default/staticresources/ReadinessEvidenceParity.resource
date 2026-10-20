[
  {
    "name": "erasure-scope",
    "kind": "erasure",
    "input": {
      "mode": "simulation",
      "systems": [
        {
          "id": "salesforce_demo",
          "category": "salesforce"
        }
      ],
      "evidence": [
        {
          "system_id": "salesforce_demo",
          "probe_id": "active_read_absent",
          "result": "observed",
          "evidence_ref": "synthetic_component_run",
          "reviewer_ref": "demo_reviewer"
        }
      ]
    },
    "expected": {
      "version": "erasure-evidence-coverage-v1",
      "mode": "simulation",
      "decision": "not_assessed",
      "independently_verified": false,
      "required_checks": 8,
      "reported_observations": 0,
      "reported_failures": 0,
      "simulated_failures": 0,
      "follow_ups": [
        {
          "category": "integrations",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "List the systems and copies that receive this information, and name an owner for each.",
          "basis": "missing_evidence"
        },
        {
          "category": "logs",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "List the systems and copies that receive this information, and name an owner for each.",
          "basis": "missing_evidence"
        },
        {
          "category": "backups",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "List the systems and copies that receive this information, and name an owner for each.",
          "basis": "missing_evidence"
        },
        {
          "category": "exports",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "List the systems and copies that receive this information, and name an owner for each.",
          "basis": "missing_evidence"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "recycle_bin_absent",
          "status": "unknown",
          "priority": "Medium",
          "owner": "Salesforce admin",
          "action": "Review approved deletion from the Recycle Bin and confirm what remains recoverable.",
          "basis": "missing_evidence"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "agent_output_absent",
          "status": "unknown",
          "priority": "Medium",
          "owner": "AI service owner",
          "action": "Stop affected agent use and check that erased information cannot appear in agent answers.",
          "basis": "missing_evidence"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "retention_approval",
          "status": "unknown",
          "priority": "Medium",
          "owner": "Privacy lead",
          "action": "Document which information may be retained, why, for how long and who approved it.",
          "basis": "missing_evidence"
        }
      ],
      "unknown_checks": 7,
      "checks": [
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "active_read_absent",
          "status": "simulated_observed"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "recycle_bin_absent",
          "status": "unknown"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "agent_output_absent",
          "status": "unknown"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce_demo",
          "probe_id": "retention_approval",
          "status": "unknown"
        },
        {
          "category": "integrations",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown"
        },
        {
          "category": "logs",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown"
        },
        {
          "category": "backups",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown"
        },
        {
          "category": "exports",
          "system_id": null,
          "probe_id": "destination_inventory",
          "status": "unknown"
        }
      ],
      "limitation": "Coverage only. References and reviewers are reported, not independently verified. Actual destinations, retention decisions, executable probes and restore/sync tests must be verified before assessing end-to-end erasure; no compliance conclusion is made."
    }
  },
  {
    "name": "erasure-failures",
    "kind": "erasure",
    "input": {
      "mode": "simulation",
      "systems": [
        {
          "id": "fictional_salesforce",
          "category": "salesforce"
        },
        {
          "id": "fictional_integrations",
          "category": "integrations"
        },
        {
          "id": "fictional_logs",
          "category": "logs"
        },
        {
          "id": "fictional_backups",
          "category": "backups"
        },
        {
          "id": "fictional_exports",
          "category": "exports"
        }
      ],
      "evidence": [
        {
          "system_id": "fictional_salesforce",
          "probe_id": "active_read_absent",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_salesforce",
          "probe_id": "recycle_bin_absent",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_salesforce",
          "probe_id": "agent_output_absent",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_salesforce",
          "probe_id": "retention_approval",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_integrations",
          "probe_id": "destination_absent",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_integrations",
          "probe_id": "sync_no_reintroduction",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_integrations",
          "probe_id": "retention_approval",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_logs",
          "probe_id": "stored_log_absent",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_logs",
          "probe_id": "new_log_no_reappearance",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_logs",
          "probe_id": "retention_approval",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_backups",
          "probe_id": "restore_no_reintroduction",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_backups",
          "probe_id": "retention_approval",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_exports",
          "probe_id": "export_copy_absent",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "system_id": "fictional_exports",
          "probe_id": "retention_approval",
          "result": "failed",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        }
      ]
    },
    "expected": {
      "version": "erasure-evidence-coverage-v1",
      "mode": "simulation",
      "decision": "not_assessed",
      "independently_verified": false,
      "required_checks": 14,
      "reported_observations": 0,
      "reported_failures": 0,
      "simulated_failures": 14,
      "follow_ups": [
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "active_read_absent",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Salesforce admin",
          "action": "Check that erased information no longer appears in active Salesforce records.",
          "basis": "fictional_failure"
        },
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "recycle_bin_absent",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Salesforce admin",
          "action": "Review approved deletion from the Recycle Bin and confirm what remains recoverable.",
          "basis": "fictional_failure"
        },
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "agent_output_absent",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "AI service owner",
          "action": "Stop affected agent use and check that erased information cannot appear in agent answers.",
          "basis": "fictional_failure"
        },
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "retention_approval",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "Document which information may be retained, why, for how long and who approved it.",
          "basis": "fictional_failure"
        },
        {
          "category": "integrations",
          "system_id": "fictional_integrations",
          "probe_id": "destination_absent",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Integration owner",
          "action": "Check that the connected service removed the information covered by the request.",
          "basis": "fictional_failure"
        },
        {
          "category": "integrations",
          "system_id": "fictional_integrations",
          "probe_id": "sync_no_reintroduction",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Integration owner",
          "action": "Test the next synchronization and prevent erased information from being copied back.",
          "basis": "fictional_failure"
        },
        {
          "category": "integrations",
          "system_id": "fictional_integrations",
          "probe_id": "retention_approval",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "Document which information may be retained, why, for how long and who approved it.",
          "basis": "fictional_failure"
        },
        {
          "category": "logs",
          "system_id": "fictional_logs",
          "probe_id": "stored_log_absent",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Operations owner",
          "action": "Review retained logs and apply the approved removal or retention procedure.",
          "basis": "fictional_failure"
        },
        {
          "category": "logs",
          "system_id": "fictional_logs",
          "probe_id": "new_log_no_reappearance",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Operations owner",
          "action": "Test new activity and ensure erased information is not written into logs again.",
          "basis": "fictional_failure"
        },
        {
          "category": "logs",
          "system_id": "fictional_logs",
          "probe_id": "retention_approval",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "Document which information may be retained, why, for how long and who approved it.",
          "basis": "fictional_failure"
        },
        {
          "category": "backups",
          "system_id": "fictional_backups",
          "probe_id": "restore_no_reintroduction",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Backup owner",
          "action": "Rehearse an approved restore with fictional records and prevent erased information from becoming active again.",
          "basis": "fictional_failure"
        },
        {
          "category": "backups",
          "system_id": "fictional_backups",
          "probe_id": "retention_approval",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "Document which information may be retained, why, for how long and who approved it.",
          "basis": "fictional_failure"
        },
        {
          "category": "exports",
          "system_id": "fictional_exports",
          "probe_id": "export_copy_absent",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Data owner",
          "action": "Locate exported copies, contact their owners and verify the approved removal or retention outcome.",
          "basis": "fictional_failure"
        },
        {
          "category": "exports",
          "system_id": "fictional_exports",
          "probe_id": "retention_approval",
          "status": "simulated_failed",
          "priority": "High",
          "owner": "Privacy lead",
          "action": "Document which information may be retained, why, for how long and who approved it.",
          "basis": "fictional_failure"
        }
      ],
      "unknown_checks": 0,
      "checks": [
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "active_read_absent",
          "status": "simulated_failed"
        },
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "recycle_bin_absent",
          "status": "simulated_failed"
        },
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "agent_output_absent",
          "status": "simulated_failed"
        },
        {
          "category": "salesforce",
          "system_id": "fictional_salesforce",
          "probe_id": "retention_approval",
          "status": "simulated_failed"
        },
        {
          "category": "integrations",
          "system_id": "fictional_integrations",
          "probe_id": "destination_absent",
          "status": "simulated_failed"
        },
        {
          "category": "integrations",
          "system_id": "fictional_integrations",
          "probe_id": "sync_no_reintroduction",
          "status": "simulated_failed"
        },
        {
          "category": "integrations",
          "system_id": "fictional_integrations",
          "probe_id": "retention_approval",
          "status": "simulated_failed"
        },
        {
          "category": "logs",
          "system_id": "fictional_logs",
          "probe_id": "stored_log_absent",
          "status": "simulated_failed"
        },
        {
          "category": "logs",
          "system_id": "fictional_logs",
          "probe_id": "new_log_no_reappearance",
          "status": "simulated_failed"
        },
        {
          "category": "logs",
          "system_id": "fictional_logs",
          "probe_id": "retention_approval",
          "status": "simulated_failed"
        },
        {
          "category": "backups",
          "system_id": "fictional_backups",
          "probe_id": "restore_no_reintroduction",
          "status": "simulated_failed"
        },
        {
          "category": "backups",
          "system_id": "fictional_backups",
          "probe_id": "retention_approval",
          "status": "simulated_failed"
        },
        {
          "category": "exports",
          "system_id": "fictional_exports",
          "probe_id": "export_copy_absent",
          "status": "simulated_failed"
        },
        {
          "category": "exports",
          "system_id": "fictional_exports",
          "probe_id": "retention_approval",
          "status": "simulated_failed"
        }
      ],
      "limitation": "Coverage only. References and reviewers are reported, not independently verified. Actual destinations, retention decisions, executable probes and restore/sync tests must be verified before assessing end-to-end erasure; no compliance conclusion is made."
    }
  },
  {
    "name": "actual_complete",
    "kind": "erasure",
    "input": {
      "mode": "actual",
      "systems": [
        {
          "id": "salesforce",
          "category": "salesforce",
          "destination_ref": "registry_entry",
          "owner_ref": "owner",
          "retention_policy_ref": "policy",
          "privacy_approver_ref": "approver"
        },
        {
          "id": "integrations",
          "category": "integrations",
          "destination_ref": "registry_entry",
          "owner_ref": "owner",
          "retention_policy_ref": "policy",
          "privacy_approver_ref": "approver"
        },
        {
          "id": "logs",
          "category": "logs",
          "destination_ref": "registry_entry",
          "owner_ref": "owner",
          "retention_policy_ref": "policy",
          "privacy_approver_ref": "approver"
        },
        {
          "id": "backups",
          "category": "backups",
          "destination_ref": "registry_entry",
          "owner_ref": "owner",
          "retention_policy_ref": "policy",
          "privacy_approver_ref": "approver"
        },
        {
          "id": "exports",
          "category": "exports",
          "destination_ref": "registry_entry",
          "owner_ref": "owner",
          "retention_policy_ref": "policy",
          "privacy_approver_ref": "approver"
        }
      ],
      "evidence": [
        {
          "system_id": "salesforce",
          "probe_id": "active_read_absent",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "salesforce",
          "probe_id": "recycle_bin_absent",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "salesforce",
          "probe_id": "agent_output_absent",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "salesforce",
          "probe_id": "retention_approval",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "integrations",
          "probe_id": "destination_absent",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "integrations",
          "probe_id": "sync_no_reintroduction",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "integrations",
          "probe_id": "retention_approval",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "logs",
          "probe_id": "stored_log_absent",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "logs",
          "probe_id": "new_log_no_reappearance",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "logs",
          "probe_id": "retention_approval",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "backups",
          "probe_id": "restore_no_reintroduction",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "backups",
          "probe_id": "retention_approval",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "exports",
          "probe_id": "export_copy_absent",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        },
        {
          "system_id": "exports",
          "probe_id": "retention_approval",
          "result": "observed",
          "evidence_ref": "run_01",
          "reviewer_ref": "reviewer_01"
        }
      ]
    },
    "expected": {
      "version": "erasure-evidence-coverage-v1",
      "mode": "actual",
      "decision": "not_assessed",
      "independently_verified": false,
      "required_checks": 14,
      "reported_observations": 14,
      "reported_failures": 0,
      "simulated_failures": 0,
      "follow_ups": [],
      "unknown_checks": 0,
      "checks": [
        {
          "category": "salesforce",
          "system_id": "salesforce",
          "probe_id": "active_read_absent",
          "status": "reported_observed"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce",
          "probe_id": "recycle_bin_absent",
          "status": "reported_observed"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce",
          "probe_id": "agent_output_absent",
          "status": "reported_observed"
        },
        {
          "category": "salesforce",
          "system_id": "salesforce",
          "probe_id": "retention_approval",
          "status": "reported_observed"
        },
        {
          "category": "integrations",
          "system_id": "integrations",
          "probe_id": "destination_absent",
          "status": "reported_observed"
        },
        {
          "category": "integrations",
          "system_id": "integrations",
          "probe_id": "sync_no_reintroduction",
          "status": "reported_observed"
        },
        {
          "category": "integrations",
          "system_id": "integrations",
          "probe_id": "retention_approval",
          "status": "reported_observed"
        },
        {
          "category": "logs",
          "system_id": "logs",
          "probe_id": "stored_log_absent",
          "status": "reported_observed"
        },
        {
          "category": "logs",
          "system_id": "logs",
          "probe_id": "new_log_no_reappearance",
          "status": "reported_observed"
        },
        {
          "category": "logs",
          "system_id": "logs",
          "probe_id": "retention_approval",
          "status": "reported_observed"
        },
        {
          "category": "backups",
          "system_id": "backups",
          "probe_id": "restore_no_reintroduction",
          "status": "reported_observed"
        },
        {
          "category": "backups",
          "system_id": "backups",
          "probe_id": "retention_approval",
          "status": "reported_observed"
        },
        {
          "category": "exports",
          "system_id": "exports",
          "probe_id": "export_copy_absent",
          "status": "reported_observed"
        },
        {
          "category": "exports",
          "system_id": "exports",
          "probe_id": "retention_approval",
          "status": "reported_observed"
        }
      ],
      "limitation": "Coverage only. References and reviewers are reported, not independently verified. Actual destinations, retention decisions, executable probes and restore/sync tests must be verified before assessing end-to-end erasure; no compliance conclusion is made."
    }
  },
  {
    "name": "poor",
    "kind": "safeguards",
    "input": {
      "mode": "simulation",
      "evidence": [
        {
          "check_id": "prerequisites",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "approval",
          "result": "fail",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "export_block",
          "result": "fail",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        }
      ]
    },
    "expected": {
      "score": "20.0",
      "coverage": "60.0",
      "passed": 1,
      "applicable": 5
    }
  },
  {
    "name": "improving",
    "kind": "safeguards",
    "input": {
      "mode": "simulation",
      "evidence": [
        {
          "check_id": "prerequisites",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "runtime_access",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "approval",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        }
      ]
    },
    "expected": {
      "score": "60.0",
      "coverage": "60.0",
      "passed": 3,
      "applicable": 5
    }
  },
  {
    "name": "pilot",
    "kind": "safeguards",
    "input": {
      "mode": "simulation",
      "evidence": [
        {
          "check_id": "prerequisites",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "runtime_access",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "approval",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "export_block",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "stop_control",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        }
      ]
    },
    "expected": {
      "score": "100.0",
      "coverage": "100.0",
      "passed": 5,
      "applicable": 5
    }
  },
  {
    "name": "blocked",
    "kind": "safeguards",
    "input": {
      "mode": "simulation",
      "evidence": [
        {
          "check_id": "prerequisites",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "runtime_access",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "approval",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "export_block",
          "result": "fail",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        },
        {
          "check_id": "stop_control",
          "result": "pass",
          "evidence_ref": "fictional_run",
          "reviewer_ref": "fictional_reviewer"
        }
      ]
    },
    "expected": {
      "score": "80.0",
      "coverage": "100.0",
      "passed": 4,
      "applicable": 5
    }
  },
  {
    "name": "unknown",
    "kind": "safeguards",
    "input": {
      "mode": "simulation",
      "evidence": []
    },
    "expected": {
      "score": "0.0",
      "coverage": "0.0",
      "passed": 0,
      "applicable": 5
    }
  }
]
