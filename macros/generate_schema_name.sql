{% macro generate_schema_name(custom_schema_name, node) -%}

    {#
        Schema routing logic:

        PR CI runs (pull_request on sit):
            → CI_<github_actor>_<custom_schema>  (personal, isolated per developer)
            → respects folder-based +schema (PREP/RPT) with a personal prefix
            → e.g. CI_502010371_HELIA_PREP, CI_502010371_HELIA_RPT

        Push/merge & all other runs (sit deploy, uat, prd):
            → standard folder-based routing (PREP, RPT, etc.)
            → uses custom_schema_name from +schema: config
            → NO personal prefix (proper deployment schemas)

        Why:
            - GITHUB_ACTOR is set on ALL runs, so we must ALSO check
              GITHUB_EVENT_NAME == 'pull_request' to isolate ONLY PR CI.
            - custom_schema_name (from folder +schema) must be respected
              so PREP/RPT routing is not collapsed into one schema.
    #}

    {%- set default_schema = target.schema -%}
    {%- set github_actor = env_var('GITHUB_ACTOR', '') -%}
    {%- set github_event = env_var('GITHUB_EVENT_NAME', '') -%}

    {#- Personal CI schema ONLY for pull_request runs on the sit target -#}
    {%- if target.name == 'sit' and github_event == 'pull_request' and github_actor != '' -%}

        {%- set actor_clean = github_actor | upper | replace('-', '_') | replace('.', '_') -%}

        {%- if custom_schema_name is not none -%}
            CI_{{ actor_clean }}_{{ custom_schema_name | trim | upper }}
        {%- else -%}
            CI_{{ actor_clean }}
        {%- endif -%}

    {%- else -%}

        {#- Deploy / non-PR runs: standard folder-based schema routing -#}
        {%- if custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- else -%}
            {{ default_schema }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
