*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Variables           variables.py


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Get orders
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Log    ${URL}
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[url]
    Click Button    OK
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Fill and submit the form orders for the team
    [Arguments]    ${orders}
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    alias:legs    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    5x    1.5 sec    OrderBut

 Store the receipt as a PDF file
    [Arguments]    ${orders}
    ${pdf}=    Get Element Attribute    alias:Receipt    outerHTML
    ${filepath}=    Set Variable    ${orders}
    Html To Pdf    ${pdf}    ${OUTPUT_DIR}${/}${filepath}.pdf

 Take a screenshot of the robot
    [Arguments]    ${orders}
    ${screenshot}=    Capture Element Screenshot
    ...    id:robot-preview-image
    ...    ${OUTPUT_DIR}${/}${orders}.png
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}${orders}.pdf
    ...    ${OUTPUT_DIR}${/}${orders}.png
    Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}${orders}.pdf

OrderBut
    Click Button    order
    Wait Until Page Contains Element    alias:Receipt

New order
    Click Button    order-another
    Wait Until Keyword Succeeds    5x    1.5 sec    Close modal

Close modal
    Wait Until Page Contains Element    alias:modal
    Click Button    OK

Get orders
    ${orders}=    Read table from CSV    orders.csv

    FOR    ${row}    IN    @{orders}
        Fill and submit the form orders for the team    ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        New order
    END

Create a ZIP file of the receipts
    Archive Folder With ZIP
    ...    ${CURDIR}${/}output
    ...    orders.zip
    ...    recursive=True
    ...    include=*.pdf
    ...    exclude=/.*
    @{files}=    List Archive    orders.zip
    FOR    ${pdf}    IN    ${files}
        Log    ${pdf}
    END
