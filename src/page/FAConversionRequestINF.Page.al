namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// Request dialog of the FA conversion: asks for the acquisition date and for the quantity (all convertible
/// units or a given number from each selected line) before the selected posted transfer lines are converted
/// to fixed assets. The dialog reads and writes nothing in the database.
/// </summary>
page 60014 "FA Conversion Request INF"
{
    Caption = 'Convert to Fixed Assets';
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Acquisition)
            {
                Caption = 'Acquisition';

                field(AcquisitionDate; AcquisitionDateValue)
                {
                    Caption = 'Acquisition Date';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the acquisition date of the fixed assets. It is the posting date of the negative inventory adjustment and of the FA acquisition, and depreciation starts on 1 January of this year.';

                    trigger OnValidate()
                    begin
                        FAConversionRequestMgt.ValidateAcquisitionDate(AcquisitionDateValue, LatestDocumentPostingDate, LatestDocumentNo);
                    end;
                }
            }
            group(QuantityGroup)
            {
                Caption = 'Quantity';

                field(ConvertMode; ConvertModeValue)
                {
                    Caption = 'Convert';
                    ToolTip = 'Specifies whether all convertible units of each selected line are converted, or only the quantity entered below from each selected line.';

                    trigger OnValidate()
                    begin
                        QuantityToConvertEnabled := ConvertModeValue = ConvertModeValue::Quantity;
                        if not QuantityToConvertEnabled then
                            QuantityToConvertValue := 0;
                    end;
                }
                field(QuantityToConvert; QuantityToConvertValue)
                {
                    Caption = 'Quantity to Convert';
                    Enabled = QuantityToConvertEnabled;
                    ShowMandatory = QuantityToConvertEnabled;
                    ToolTip = 'Specifies how many units of each selected line are converted. It cannot exceed the convertible quantity of any selected line.';

                    trigger OnValidate()
                    begin
                        FAConversionRequestMgt.ValidateQuantity(TempSourceLines, ConvertModeValue, QuantityToConvertValue);
                    end;
                }
            }
            group(Selection)
            {
                Caption = 'Selection';
                Editable = false;

                field(SelectedLines; SelectedLinesValue)
                {
                    Caption = 'Selected Lines';
                    ToolTip = 'Specifies how many posted lines are selected.';
                }
                field(ConvertibleQuantity; ConvertibleQuantityValue)
                {
                    Caption = 'Convertible Quantity';
                    ToolTip = 'Specifies how many units can still be converted from the selected lines.';
                }
                field(AlreadyConverted; AlreadyConvertedValue)
                {
                    Caption = 'Already Converted';
                    ToolTip = 'Specifies how many fixed assets were already created from the selected lines.';
                }
                field(ItemNo; ItemNoValue)
                {
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the number of the item on the selected line.';
                    Visible = SingleLineSelected;
                }
                field(Description; DescriptionValue)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the item on the selected line.';
                    Visible = SingleLineSelected;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializeDefaults();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            FAConversionRequestMgt.ValidateRequest(TempSourceLines, AcquisitionDateValue, ConvertModeValue, QuantityToConvertValue);

        exit(true);
    end;

    var
        TempSourceLines: Record "FA Conv. Source Line INF" temporary;
        FAConversionRequestMgt: Codeunit "FA Conversion Request Mgt. INF";
        LatestDocumentPostingDate: Date;
        AcquisitionDateValue: Date;
        ConvertModeValue: Enum "FA Conv. Quantity Mode INF";
        LatestDocumentNo: Code[20];
        ItemNoValue: Code[20];
        DescriptionValue: Text[100];
        AlreadyConvertedValue: Integer;
        ConvertibleQuantityValue: Integer;
        QuantityToConvertValue: Integer;
        SelectedLinesValue: Integer;
        QuantityToConvertEnabled: Boolean;
        SingleLineSelected: Boolean;

    /// <summary>
    /// Hands the selected source lines to the dialog before it is opened. The dialog shares the rows of the
    /// buffer with the caller and neither inserts nor deletes rows; it shows their totals and starts with the
    /// default request: the work date as acquisition date and all convertible units.
    /// </summary>
    /// <param name="TempFAConvSourceLine">The request buffer filled by a Collect procedure of the request engine.</param>
    procedure SetSourceLines(var TempFAConvSourceLine: Record "FA Conv. Source Line INF" temporary)
    begin
        TempSourceLines.Copy(TempFAConvSourceLine, true);
        InitializeDefaults();
        LoadSummary();
        LatestDocumentPostingDate := TempSourceLines.GetLatestDocumentPostingDate(LatestDocumentNo);
    end;

    /// <summary>
    /// Returns the request that the user entered. Call it after the dialog was closed with OK.
    /// </summary>
    /// <param name="NewAcquisitionDate">Receives the acquisition date.</param>
    /// <param name="NewConvertMode">Receives whether all convertible units or a given quantity per line is converted.</param>
    /// <param name="NewQuantityToConvert">Receives the quantity per line; only meaningful when the mode is Quantity.</param>
    procedure GetRequest(var NewAcquisitionDate: Date; var NewConvertMode: Enum "FA Conv. Quantity Mode INF"; var NewQuantityToConvert: Integer)
    begin
        NewAcquisitionDate := AcquisitionDateValue;
        NewConvertMode := ConvertModeValue;
        NewQuantityToConvert := QuantityToConvertValue;
    end;

    /// <summary>
    /// Sets the default request: the work date as acquisition date, all convertible units, no quantity.
    /// The work date is only read.
    /// </summary>
    local procedure InitializeDefaults()
    begin
        AcquisitionDateValue := WorkDate();
        ConvertModeValue := ConvertModeValue::All;
        QuantityToConvertValue := 0;
        QuantityToConvertEnabled := false;
    end;

    /// <summary>
    /// Calculates the totals of the selected lines and, for a single selected line, its item and description.
    /// </summary>
    local procedure LoadSummary()
    begin
        SelectedLinesValue := 0;
        ConvertibleQuantityValue := 0;
        AlreadyConvertedValue := 0;
        ItemNoValue := '';
        DescriptionValue := '';

        if TempSourceLines.FindSet() then
            repeat
                SelectedLinesValue += 1;
                ConvertibleQuantityValue += TempSourceLines."Convertible Quantity";
                AlreadyConvertedValue += TempSourceLines."Converted Quantity";
                ItemNoValue := TempSourceLines."Item No.";
                DescriptionValue := TempSourceLines.Description;
            until TempSourceLines.Next() = 0;

        SingleLineSelected := SelectedLinesValue = 1;
    end;
}
