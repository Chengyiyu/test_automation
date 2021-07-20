*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) using Redfish.

Resource        ../../lib/openbmc_ffdc.robot
Library         ../../lib/vpd_utils.py

Suite Setup     Redfish.Login
Suite Teardown  Redfish.Logout
Test Teardown   FFDC On Test Case Fail


*** Test Cases ***

Verify VPD Data Via Redfish
    [Documentation]  Verify VPD details via Redfish output.
    [Tags]  Verify_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component
    BMC
    Chassis
    CPU


*** Keywords ***

Verify Redfish VPD Data
    [Documentation]  Verify Redfish VPD data of given component.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${component_uri}=  Set Variable If
    ...  '${component}' == 'BMC'  /redfish/v1/Managers/bmc
    ...  '${component}' == 'Chassis'  /redfish/v1/Chassis/chassis
    ...  '${component}' == 'CPU'  /redfish/v1/Systems/system/Processors/cpu0

    # TODO: Verification for SparePartNumber and Location fields will be added later.
    @{vpd_fields}=  Create List  Model  PartNumber  SerialNumber
    FOR  ${field}  IN  @{vpd_fields}
      Verify Redfish VPD  ${component}  ${component_uri}  ${field}
    END


Verify Redfish VPD
    [Documentation]  Verify Redfish VPD of given URI.
    [Arguments]  ${component}  ${component_uri}  ${field}
    # Description of arguments:
    # component_uri       Redfish VPD uri (e.g. /redfish/v1/Systems/system/Processors/cpu1).
    # field               Redfish VPD field (Model)

    ${resp}=  Redfish.Get Properties  ${component_uri}
    ${vpd_field}=  Set Variable If
    ...  '${field}' == 'Model'  CC
    ...  '${field}' == 'PartNumber'  PN
    ...  '${field}' == 'SerialNumber'  SN
    ...  '${field}' == 'SparePartNumber'  FN
    ...  '${field}' == 'Location'  LocationCode

    ${vpd_component}=  Set Variable If
    ...  '${component}' == 'CPU'  /system/chassis/motherboard/cpu0
    ...  '${component}' == 'Chassis'  /system/chassis
    ...  '${component}' == 'BMC'  /system/chassis/motherboard/ebmc_card_bmc

    ${vpd_records}=  Vpdtool  -r -O ${vpd_component} -R VINI -K ${vpd_field}
    Should Be Equal As Strings  ${resp["${field}"]}  ${vpd_records['${vpd_component}']['${vpd_field}']}
