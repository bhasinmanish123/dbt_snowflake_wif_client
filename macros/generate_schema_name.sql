{% macro generate_schema_name(custom_schema_name, node) -%}

    {#
        ci target + GITHUB_ACTOR set → DEV_USERNAME (personal, auto-created)
        prod target                  → PROD (fixed, shared)
    #}

    {%- set default_schema = target.schema -%}

    {%- if target.name == 'ci' -%}
        {%- set github_actor = env_var('GITHUB_ACTOR', '') -%}
        {%- if github_actor != '' -%}
            DEV_{{ github_actor | upper | replace('-', '_') | replace('.', '_') }}
        {%- else -%}
            {{ default_schema }}
        {%- endif -%}

    {%- elif target.name == 'prod' -%}
        {{ default_schema }}

    {%- else -%}
        {{ default_schema }}

    {%- endif -%}

{%- endmacro %}
