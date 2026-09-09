{% macro generate_schema_name(custom_schema_name, node) -%}

    {#
        PR CI runs (pull_request, on ci OR sit target):
            → CI_<github_actor>_<custom_schema>  (personal, isolated per developer)
            → e.g. CI_BHASINMANISH123_PREP, CI_BHASINMANISH123_RPT

        Push/merge & all other runs (deploy: prod/uat/prd):
            → standard folder-based routing (PREP, RPT, etc.)
            → NO personal prefix (proper deployment schemas)

        Why:
            - GITHUB_ACTOR is set on ALL runs, so we ALSO check
              GITHUB_EVENT_NAME == 'pull_request' to isolate ONLY PR CI.
            - custom_schema_name (folder +schema) is respected so PREP/RPT
              routing is not collapsed into one schema.
    #}

    {%- set default_schema = target.schema -%}
    {%- set github_actor = env_var('GITHUB_ACTOR', '') -%}
    {%- set github_event = env_var('GITHUB_EVENT_NAME', '') -%}

    {#- CI targets that get per-developer isolation on PRs -#}
    {%- set ci_targets = ['ci', 'sit'] -%}

    {%- if target.name in ci_targets and github_event == 'pull_request' and github_actor != '' -%}

        {%- set actor_clean = github_actor | upper | replace('-', '_') | replace('.', '_') -%}

        {%- if custom_schema_name is not none -%}
            CI_{{ actor_clean }}_{{ custom_schema_name | trim | upper }}
        {%- else -%}
            CI_{{ actor_clean }}
        {%- endif -%}

    {%- else -%}

        {%- if custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- else -%}
            {{ default_schema }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
