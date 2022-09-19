tableextension 50129 GLSetupExt extends "General Ledger Setup"
{
    fields
    {
        field(50100; "Close AP"; Boolean)
        {
            Caption = 'Closed for AP';
            DataClassification = CustomerContent;
        }
    }

}
pageextension 50130 GLSetupExt extends "General ledger Setup"
{
    layout
    {
        addafter(UnitAmountDecimalPlaces)
        {
            field("Close AP"; "Close AP")
            {
                Caption = 'Closed for AP';
                ApplicationArea = All;
            }
        }
    }
}

codeunit 50127 PurchaseJournalPostCode1
{
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrentJnlBatchName: Code[10];
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        Genjournalbatch: Record "Gen. Journal Batch";
        Isbtchentriesavailable: Boolean;
        JobQueuesUsed: Boolean;
        JobQueueVisible: Boolean;
        GenJnlLine: Record "Gen. Journal Line";


    procedure RunCodeUnit(var Batchname: Text[100]) Returnvalue: Text[100]
    var
        result: Text[50];
        GlSetup: record "General Ledger Setup";
        CheckAP: Boolean;
    begin
        if (Batchname <> '')
        then begin
            GenJnlLine.SetFilter("Journal Batch Name", Batchname);
            GenJnlLine.SetFilter("Journal Template Name", 'PURCHASES');
            CurrentJnlBatchName := Batchname;

            if GlSetup.FindFirst() then begin
                if GenJnlLine.FindSet()
                then
                    repeat
                        if (GenJnlLine."Posting Date" < GlSetup."Allow Posting From")
                        then begin
                            GenJnlLine."Posting Date" := GlSetup."Allow Posting From";
                            GenJnlLine.Modify();
                            CheckAP := false;
                        end;
                        if GlSetup."Close AP"
                        then begin
                            CheckAP := true;
                        end;

                        Isbtchentriesavailable := true;
                    Until GenJnlLine.Next() = 0;
            end;
            if CheckAP <> true then begin
                CODEUNIT.Run(CODEUNIT::"GenJournalPostNew1", GenJnlLine);
                CurrentJnlBatchName := GenJnlLine.GetRangeMax("Journal Batch Name");
                SetJobQueueVisibility();
                result := 'Success';
                ReturnValue := result;
            end else begin
                result := 'UnSuccess: AP is Closed';
                ReturnValue := result;
            end;
        end
        else begin
            result := 'UnSuccess';
            ReturnValue := result;
        end;

    end;

    procedure DeleteCurrentBatch(var Batchname: Text[100])
    begin
        if Batchname <> ''
        then begin
            Genjournalbatch."Journal Template Name" := 'PURCHASES';
            Genjournalbatch.Name := Batchname;
            Genjournalbatch.Delete();
        end;
    end;

    local procedure SetJobQueueVisibility()
    begin
        JobQueueVisible := GenJnlLine."Job Queue Status" = GenJnlLine."Job Queue Status"::"Scheduled for Posting";
        JobQueuesUsed := GeneralLedgerSetup.JobQueueActive();
    end;
}
