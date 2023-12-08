page 60000 "FA Conversion Wizard"
{
    Caption = 'FA Conversion';
    PageType = NavigatePage;
    SourceTable = "FA Conversion Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(StandardBanner)
            {
                Caption = '', Locked = true;
                Editable = false;
                Visible = TopBannerVisible and not FinishActionEnabled;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = 'Media Reference';
                }
            }
            group(FinishedBanner)
            {
                Caption = '', Locked = true;
                Editable = false;
                Visible = TopBannerVisible and FinishActionEnabled;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = 'Media Reference';
                }
            }

            group(Step1)
            {
                Visible = Step1Visible;
                Caption = 'Step1';
                group("Welcome to FA Conversion")
                {
                    Caption = 'Welcome to FA Conversion Setup';
                    Visible = Step1Visible;
                    group(Group18)
                    {
                        Caption = '', Locked = true;
                        InstructionalText = 'Step1 - Replace this text with some instructions.';
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    group(Group22)
                    {
                        Caption = '', Locked = true;
                        InstructionalText = 'Step1 - Replace this text with some more instructions.';
                    }
                }
            }

            group(Step2)
            {
                Caption = '', Locked = true;
                InstructionalText = 'Step2 - Replace this text with some instructions.';
                Visible = Step2Visible;
                //You might want to add fields here
            }


            group(Step3)
            {
                Visible = Step3Visible;
                Caption = 'Step3';
                group(Group23)
                {
                    Caption = '', Locked = true;
                    InstructionalText = 'Step3 - Replace this text with some instructions.';
                }
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Group25)
                    {
                        Caption = '', Locked = true;
                        InstructionalText = 'To save this setup, choose Finish.';
                    }
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit();
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage();
    var
        FAConversionSetup: Record "FA Conversion Setup";
    begin
        Rec.Init();
        if FAConversionSetup.Get() then
            Rec.TransferFields(FAConversionSetup);

        Rec.Insert(false);

        Step := Step::Start;
        EnableControls();
    end;

    var
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        Step: Option Start,Step2,Finish;
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        TopBannerVisible: Boolean;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Finish:
                ShowStep3();
        end;
    end;

    local procedure StoreRecordVar()
    var
        FAConversionSetup: Record "FA Conversion Setup";
    begin
        if not FAConversionSetup.Get() then begin
            FAConversionSetup.Init();
            FAConversionSetup.Insert(false);
        end;

        FAConversionSetup.TransferFields(Rec, false);
        FAConversionSetup.Modify(true);
    end;


    local procedure FinishAction()
    begin
        StoreRecordVar();
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStep1()
    begin
        Step1Visible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowStep2()
    begin
        Step2Visible := true;
    end;

    local procedure ShowStep3()
    begin
        Step3Visible := true;

        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
            MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
                MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
        then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;
}