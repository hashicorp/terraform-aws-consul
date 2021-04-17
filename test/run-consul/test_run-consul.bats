#!/usr/bin/env bats
# Execute via: `bats --tap test_run-consul.bats`

command -v brew >/dev/null 2>&1 || ENVIRONMENT_LOCAL=false
if [[ "${ENVIRONMENT_LOCAL}" == "false" ]]; then
    load "/test/test_helper/bats-support/load.bash"
    load "/test/test_helper/bats-assert/load.bash"
    load "/test/test_helper/bats-file/load.bash"
else
    TEST_BREW_PREFIX="$(brew --prefix)"
    load "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
    load "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"
    load "${TEST_BREW_PREFIX}/lib/bats-file/load.bash"
fi

readonly RUN_CONSUL="${BATS_CWD}/../../modules/run-consul/run-consul"
readonly TEST_DIR_BASE="${BATS_TMPDIR}"
readonly CONSUL_CONFIG="${TEST_DIR_BASE}/default.json"

setup_mocks() {
    # It is important to source the tested script or library
    # before the function is stubbed or mocked.
    # shellcheck source=../../modules/run-consul/run-consul
    source "${RUN_CONSUL}"

    function chown() { echo "chown: mocked, but unneeded."; }
    export -f chown

    function sudo() { echo "sudo: mocked, but unneeded."; }
    export -f sudo

    function systemctl() { echo "systemctl: mocked, but unneeded."; }
    export -f systemctl

    function lookup_path_in_instance_metadata() { echo "lookup_path_in_instance_metadata: mocked, but unneeded.";}
    export -f lookup_path_in_instance_metadata

    function get_instance_tags() { echo "get_instance_tags: mocked, but unneeded."; }
    export -f get_instance_tags

    function get_instance_region() { echo "get_instance_region: mocked, but unneeded."; }
    export -f get_instance_region
}

call_generate_consul_config() {
    local -r server="true"
    local -r config_dir="${TEST_DIR_BASE}"
    local -r enable_connect="${1}"

    generate_consul_config \
       "${server}" \
       "${config_dir}" \
       "test" "test" "test" "test" "test" "test" "test" "test" \
       "test" "test" "test" 0 "test" 0 "test" "test" 0 "test" \
       "${enable_connect}"
}

@test "Consul Connect: activated" {
    # Prepare
    setup_mocks

    # Execute
    run execute --config-dir "${TEST_DIR_BASE}" --server --cluster-tag-key "test" --cluster-tag-value "test" --enable-connect

    # Verify
    assert_success
    assert_file_exist "${CONSUL_CONFIG}"
    run awk '/connect/,/}/' "${CONSUL_CONFIG}"
    assert_success
    assert_output --partial "connect"
    assert_output --partial "enabled"
    assert_output --partial "true"
}

@test "Consul Connect: deactivated" {
    # Prepare
    setup_mocks

    # Execute
    run execute --config-dir "${TEST_DIR_BASE}" --server --cluster-tag-key "test" --cluster-tag-value "test"

    # Verify
    assert_success
    assert_file_exist "${CONSUL_CONFIG}"
    run awk '/connect/,/}/' "${CONSUL_CONFIG}"
    assert_success
    refute_output --partial "connect"
    refute_output --partial "enabled"
    refute_output --partial "true"
}

@test "Consul Connect Configuration Generation: activated" {
    # Prepare
    setup_mocks

    # Execute
    run call_generate_consul_config "true"

    # Verify
    assert_success
    assert_file_exist "${CONSUL_CONFIG}"
    run awk '/connect/,/}/' "${CONSUL_CONFIG}"
    assert_success
    assert_output --partial "connect"
    assert_output --partial "enabled"
    assert_output --partial "true"
}

@test "Consul Connect Configuration Generation: deactivated" {
    # Prepare
    setup_mocks

    # Execute
    run call_generate_consul_config

    # Verify
    assert_success
    assert_file_exist "${CONSUL_CONFIG}"
    run awk '/connect/,/}/' "${CONSUL_CONFIG}"
    assert_success
    refute_output --partial "connect"
    refute_output --partial "enabled"
    refute_output --partial "true"
}
