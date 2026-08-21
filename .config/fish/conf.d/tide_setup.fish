# Bootstrap fisher + plugins from fish_plugins and apply the tide prompt
# config, once per machine. Bump TIDE_CONFIG_VERSION after changing the
# `tide configure` flags to re-apply on every machine.
status is-interactive; or exit

set -l TIDE_CONFIG_VERSION 1

if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher update
end

if functions -q tide; and test "$tide_config_version" != "$TIDE_CONFIG_VERSION"
    tide configure --auto --style=Lean --prompt_colors='True color' \
        --show_time='12-hour format' --lean_prompt_height='Two lines' \
        --prompt_connection=Dotted --prompt_connection_andor_frame_color=Lightest \
        --prompt_spacing=Compact --icons='Many icons' --transient=No
    and set -U tide_config_version $TIDE_CONFIG_VERSION
end
