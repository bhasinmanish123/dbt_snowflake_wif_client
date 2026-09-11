#!/usr/bin/env python3
"""
sync_dbt_cloud_jobs.py — verify + create/update dbt Cloud jobs from YAML.

Usage:
    python scripts/sync_dbt_cloud_jobs.py dbt_cloud_jobs/jobs.yml

Env vars:
    DBT_CLOUD_API_TOKEN    dbt Cloud service token
    DBT_CLOUD_ACCOUNT_ID   dbt Cloud account ID
    DBT_CLOUD_HOST         (optional) default cloud.getdbt.com

For each job in YAML:
    exists (by name) → UPDATE
    missing          → CREATE
(Does NOT delete jobs missing from YAML — safe by default.)
"""
import os
import sys
import yaml
import requests

TOKEN = os.environ["DBT_CLOUD_API_TOKEN"]
ACCOUNT_ID = os.environ["DBT_CLOUD_ACCOUNT_ID"]
HOST = os.environ.get("DBT_CLOUD_HOST", "cloud.getdbt.com")

BASE = f"https://{HOST}/api/v2/accounts/{ACCOUNT_ID}"
HEADERS = {"Authorization": f"Token {TOKEN}", "Content-Type": "application/json"}


def list_jobs(project_id):
    resp = requests.get(f"{BASE}/jobs/", headers=HEADERS, params={"project_id": project_id})
    resp.raise_for_status()
    return {j["name"]: j for j in resp.json()["data"]}


def build_payload(project_id, environment_id, name, job):
    cron = job.get("schedule", {}).get("cron", "0 * * * *")
    return {
        "account_id": int(ACCOUNT_ID),
        "project_id": int(project_id),
        "environment_id": int(job.get("environment_id", environment_id)),
        "name": name,
        "execute_steps": job["execute_steps"],
        "triggers": job.get("triggers", {"schedule": True, "github_webhook": False}),
        "settings": {"threads": job.get("threads", 4), "target_name": job.get("target", "prod")},
        "schedule": {"cron": cron, "date": {"type": "custom_cron", "cron": cron}},
        "state": 1,
    }


def create_job(payload):
    r = requests.post(f"{BASE}/jobs/", headers=HEADERS, json=payload)
    r.raise_for_status()
    print(f"  CREATED: {payload['name']} (id={r.json()['data']['id']})")


def update_job(job_id, payload):
    payload["id"] = job_id
    r = requests.post(f"{BASE}/jobs/{job_id}/", headers=HEADERS, json=payload)
    r.raise_for_status()
    print(f"  UPDATED: {payload['name']} (id={job_id})")


def main(yaml_path):
    with open(yaml_path) as f:
        cfg = yaml.safe_load(f)

    project_id = cfg["project_id"]
    environment_id = cfg["environment_id"]

    print(f"Syncing jobs from {yaml_path} (project_id={project_id})")
    existing = list_jobs(project_id)
    print(f"Found {len(existing)} existing job(s).")

    for key, job in cfg["jobs"].items():
        name = job["name"]
        payload = build_payload(project_id, environment_id, name, job)
        if name in existing:
            update_job(existing[name]["id"], payload)
        else:
            create_job(payload)

    print("Sync complete.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python sync_dbt_cloud_jobs.py <jobs.yml>")
        sys.exit(2)
    main(sys.argv[1])
