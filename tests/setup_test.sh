#!/bin/bash
set -eu

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
source <(sed '$d' "$repo_dir/setup.sh")

test_selection() (
    local expected="$1"
    shift
    local calls=""
    setup_environment() { calls+="env:$1 "; }
    setup_mosquitto() { calls+="mosquitto "; }
    setup_influxdb() { calls+="influxdb "; }
    setup_grafana() { calls+="grafana "; }
    setup_adafruit() { calls+="adafruit "; }
    setup_telegram_bot() { calls+="telegram "; }
    setup_aiagents() { calls+="ai "; }
    main "$@" >/dev/null
    if [ "$calls" != "$expected" ]; then
        printf 'Expected "%s", got "%s"\n' "$expected" "$calls" >&2
        exit 1
    fi
)

all="env:true mosquitto influxdb grafana adafruit telegram ai "
test_selection "$all" --recreate-venv
test_selection "$all" --all --recreate-venv
test_selection "env:false mosquitto influxdb grafana adafruit telegram ai "
test_selection "env:true telegram " --recreate-venv --telegram
test_selection "env:true ai " --ai --recreate-venv
test_selection "env:true " --recreate-venv --env-setup
test_selection "env:false " --env-setup

test_environment_packages() (
    local recreate="$1"
    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$temp_dir"' EXIT
    export HOME="$temp_dir"
    local pip_log="$temp_dir/pip.log"
    command_exists() { return 0; }
    systemctl() { return 0; }
    python3() {
        mkdir -p "$3/bin"
        printf 'export VIRTUAL_ENV="%s"\n' "$3" > "$3/bin/activate"
    }
    pip() { printf '%s\n' "$*" >> "$pip_log"; }

    if [ "$recreate" = true ]; then
        mkdir -p "$HOME/siotdenv"
        touch "$HOME/siotdenv/old-package"
    fi
    setup_environment "$recreate" >/dev/null
    if [ -e "$HOME/siotdenv/old-package" ]; then
        printf 'The old virtual environment was not removed\n' >&2
        exit 1
    fi
    local expected
    expected="$(printf 'install --upgrade pip\ninstall setuptools wheel boto3')"
    if [ "$(cat "$pip_log")" != "$expected" ]; then
        printf 'Unexpected pip commands for recreate=%s:\n' "$recreate" >&2
        cat "$pip_log" >&2
        exit 1
    fi
)

test_aiagents_packages() (
    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$temp_dir"' EXIT
    export HOME="$temp_dir" PROJECT_DIR="$temp_dir/project" VIRTUAL_ENV="$temp_dir"
    local pip_log="$temp_dir/pip.log"
    command_exists() { [ "$1" != ollama ]; }
    sudo() { printf 'sudo %s\n' "$*" >> "$pip_log"; }
    curl() { printf 'install-script'; }
    sh() { printf 'sh %s\n' "$(cat)" >> "$pip_log"; }
    ollama() { printf 'ollama %s\n' "$*" >> "$pip_log"; }
    sleep() { :; }
    uname() { [ "$1" = "-s" ] && echo Linux || echo aarch64; }
    pip() { printf '%s\n' "$*" >> "$pip_log"; }

    setup_aiagents >/dev/null
    local expected
    expected="$(printf 'install smolagents[litellm] python-dotenv\nsudo apt-get install -y libgl1\ninstall torch>=2.12,<2.15 torchvision --index-url https://download.pytorch.org/whl/cpu\ninstall ultralytics opencv-python ncnn\nsudo apt-get install -y curl zstd\nsh install-script\nollama list\nollama pull qwen3:0.6b')"
    if [ "$(cat "$pip_log")" != "$expected" ]; then
        printf 'Unexpected install commands for setup_aiagents:\n' >&2
        cat "$pip_log" >&2
        exit 1
    fi
)

test_aiagents_packages
test_environment_packages false
test_environment_packages true
printf 'Setup tests passed\n'
