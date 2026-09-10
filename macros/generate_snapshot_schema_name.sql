{#-
    generate_snapshot_schema_name
    -----------------------------------------------------------------
    Snapshot schema routing (mirrors generate_schema_name for models):

    PR CI runs (pull_request, on ci OR sit target):
        → CI_<github_actor>_<custom_schema>  (isolated per developer)
        → e.g. CI_BHASINMANISH123_HIST_R360
        → each developer's PR gets its OWN snapshot schema
        → no risk to the shared/real snapshot schemas

    Push/merge & all other runs (deploy: prod/sit/uat/prd):
        → standard folder-based routing (HIST_R360, etc.)
        → the real shared snapshot schema (no duplication in deploy)

    Why check GITHUB_EVENT_NAME:
        GITHUB_ACTOR is set on ALL runs (PR and push), so we ALSO
        check pull_request to isolate ONLY on PR CI.
-#}

{% macro generate_snapshot_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- set github_actor = env_var('GITHUB_ACTOR', '') -%}
    {%- set github_event = env_var('GITHUB_EVENT_NAME', '') -%}

    {%- set ci_targets = ['ci', 'sit'] -%}

    {%- if target.name in ci_targets and github_event == 'pull_request' and github_actor != '' -%}

        {%- set actor_clean = github_actor | upper | replace('-', '_') | replace('.', '_') -%}

        {%- if custom_schema_name is not none -%}
            CI_{{ actor_clean }}_{{ custom_schema_name | trim | upper }}
        {%- else -%}
            CI_{{ actor_clean }}
        {%- endif -%}

    {%- else -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
