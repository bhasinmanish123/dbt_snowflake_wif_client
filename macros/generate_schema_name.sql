{% macro generate_schema_name(custom_schema_name, node) -%}

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
