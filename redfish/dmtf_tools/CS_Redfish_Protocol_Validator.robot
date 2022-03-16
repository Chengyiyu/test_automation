*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Protocol-Validator.
...                DMTF tool.

Library            OperatingSystem
Library            ../../lib/gen_robot_print.py
Resource           ../../lib/dmtf_tools_utils.robot
Resource           ../../lib/bmc_redfish_resource.robot
Resource           ../../lib/bmc_redfish_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rpv_dir_path}    Redfish-Protocol-Validator
${rpv_github_url}  https://github.com/DMTF/Redfish-Protocol-Validator.git
${cmd_str_master}  ${DEFAULT_PYTHON} ${rpv_dir_path}${/}rf_protocol_validator.py
...                -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD} --report-dir ${EXECDIR}${/}logs${/} --no-cert-check --avoid-http-redirect

*** Test Case ***

Test BMC Redfish Using Redfish Protocol Validator
    [Documentation]  Check conformance with a Redfish Protocol interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Protocol_Validator

    Download DMTF Tool  ${rpv_dir_path}  ${rpv_github_url}

    ${output}=  Run DMTF Tool  ${rpv_dir_path}  ${cmd_str_master}

    Redfish Protocol Validator Result  ${output}


Run Redfish Protocol Validator With Additional Roles
    [Documentation]  Check Redfish conformance using the Redfish Protocol Validator.
    ...  Run the validator as additional non-admin user roles.
    [Tags]  Run_Redfish_Protocol_Validator_With_Additional_Roles
    [Template]  Create User And Run Protocol Validator

    #username      password             role        enabled
    operator_user  ${OPENBMC_PASSWORD}  Operator    ${True}
    readonly_user  ${OPENBMC_PASSWORD}  ReadOnly    ${True}


*** Keywords ***

Create User And Run Protocol Validator
    [Documentation]  Create user and run validator.
    [Arguments]   ${username}  ${password}  ${role}  ${enabled}
    [Teardown]  Delete User Created  ${username}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role                The role of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish.Login
    Redfish Create User  ${username}  ${password}  ${role}  ${enabled}
    Redfish.Logout

    Download DMTF Tool  ${rpv_dir_path}  ${rpv_github_url}

    ${cmd}=  Catenate  ${DEFAULT_PYTHON} ${rpv_dir_path}${/}rf_protocol_validator.py
    ...  -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${username}
    ...  -p ${password} --report-dir ${EXECDIR}${/}logs_${username}${/} --no-cert-check --avoid-http-redirect

    Rprint Vars  cmd

    ${output}=  Run DMTF Tool  ${rpv_dir_path}  ${cmd}

    Redfish Service Validator Result  ${output}


Delete User Created
    [Documentation]  Delete user.
    [Arguments]   ${username}

    # Description of argument(s):
    # username            The username to be deleted.

    Redfish.Login
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}
    Redfish.Logout
