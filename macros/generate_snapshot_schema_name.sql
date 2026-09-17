{% macro generate_snapshot_schema_name(custom_schema_name, node) -%}

    {#
        Snapshot schema isolation — SAME logic as generate_schema_name.
        Snapshots must be isolated per-developer on CI so concurrent PR
        builds don't corrupt each other's SCD history.

        Four conditions (all true) → isolate:
            1. target.name in ['ci', 'sit']
            2. DBT_CI_RUN == 'true'
            3. GITHUB_ACTOR != ''
            4. GITHUB_EVENT_NAME in ['pull_request', 'push']

            pull_request → CI_<actor>_<schema>
            push         → <actor>_<schema>

        Deploy / non-CI → shared schema (HIST etc.)
    #}

    {%- set default_schema = target.schema -%}
    {%- set github_actor = env_var('GITHUB_ACTOR', '') -%}
    {%- set github_event = env_var('GITHUB_EVENT_NAME', '') -%}
    {%- set dbt_ci_run = env_var('DBT_CI_RUN', 'false') -%}

    {%- set ci_targets = ['ci', 'sit'] -%}

    {%- if target.name in ci_targets and dbt_ci_run == 'true' and github_actor != '' and github_event in ['pull_request', 'push'] -%}

        {%- set actor_clean = (
            github_actor
            | upper
            | replace('-', '_')
            | replace('.', '_')
            | replace('_HELIA', '')
        ) -%}

        {%- if custom_schema_name is not none -%}
            {%- if github_event == 'pull_request' -%}
                CI_{{ actor_clean }}_{{ custom_schema_name | trim | upper }}
            {%- else -%}
                {{ actor_clean }}_{{ custom_schema_name | trim | upper }}
            {%- endif -%}
        {%- else -%}
            {%- if github_event == 'pull_request' -%}
                CI_{{ actor_clean }}
            {%- else -%}
                {{ actor_clean }}
            {%- endif -%}
        {%- endif -%}

    {%- else -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
