// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 50138 CustomerListExt extends "General Ledger Entries"
{
    actions
    {
        addafter(ReverseTransaction)
        {
            action("Move & Reverse")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Monthly Intercompany';
                Image = MoveToNextPeriod;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Move ledger entries to respective companies and reverse original entries';

                trigger OnAction()
                var
                    GLEntries: Record "G/L Entry";
                begin
                    CurrPage.SetSelectionFilter(GLEntries);
                    REPORT.RunModal(REPORT::"Move Reverse Entries", true, true, GLEntries);
                end;

            }
        }
    }
}

report 50139 "Move Reverse Entries"
{
    Caption = '';
    ProcessingOnly = true;


    dataset
    {
        dataitem(SourceGLEntries; "G/L Entry")
        {
            DataItemTableView = sorting("Entry No.") order(ascending);
            trigger OnAfterGetRecord()
            var
                GLEnt: Record "G/L Entry";
                GLEntN: Record "G/L Entry";
                generalBatch: Record "Gen. Journal Batch";
                //GenJnlLine: Record "Gen. Journal Line";
                DimEntry: Record "Dimension Set Entry";
                VendorCard: Record Vendor;
                DimProject: text;
                DimDept: Text;
                DimComp: Text;
                DimVend: Text;
                DateValStart: Date;
                DateValEnd: Date;
                StartDate: text;
                EndDate: Text;
                EndDatePart: Text;
                prevGL: Text;
                prevDept: Text;
                prevPrj: Text;
                prevComp: Text;
                GJPage: Page "General Journal";
                //                ConsolidatedAmount: Decimal;
                GLDims: list of [text];
                i: Integer;
                AccountNumber: Text;
                AccNum: Integer;
                Amnt: Decimal;
                postmonthname: text;

            //                TempExcelBuff: Record "Excel Buffer" temporary;
            begin
                StartDate := Token(DateOf, '..');
                EndDatePart := Token(DateOf, '..');
                EndDate := EndDatePart.Substring(2);
                Evaluate(DateValStart, StartDate);
                Evaluate(DateValEnd, EndDate);

                GLEnt.SetRange("Posting Date", DateValStart, DateValEnd);
                GLEnt.SetCurrentKey("G/L Account No.");
                GLEnt.SetAscending("G/L Account No.", true);
                GLEnt.SetFilter("G/L Account No.", '>=%1|=%2|=%3', '50000', '11010', '11030');
                ExclBuff.NewRow();
                ExclBuff.AddColumn('Posting Date', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Document Type', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Document No.', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Account Type', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('G/L Account No.', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Account Name', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Description', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Amount', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Amount $', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('External Document No.', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Project Code', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Department Code', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Company Code', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
                ExclBuff.AddColumn('Vendor Code', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);


                if GLEnt.FindSet() then
                    repeat
                        DimComp := '';
                        DimDept := '';
                        DimProject := '';
                        //ConsolidatedAmount := 0;
                        DimEntry.SetFilter("Dimension Set ID", '%1', GLEnt."Dimension Set ID");
                        if DimEntry.FindSet() then
                            repeat
                                if DimEntry."Dimension Code" = 'PROJECT' then begin
                                    DimProject := DimEntry."Dimension Value Code"
                                end;
                                if DimEntry."Dimension Code" = 'DEPARTMENT' then begin
                                    DimDept := DimEntry."Dimension Value Code"
                                end;
                                if DimEntry."Dimension Code" = 'COMPANY' then begin
                                    DimComp := DimEntry."Dimension Value Code"
                                end;
                                if DimEntry."Dimension Code" = 'VENDOR' then begin
                                    dimVend := DimEntry."Dimension Value Name";
                                    //Message('val name %1', DimEntry."Dimension Value Name");
                                    //Message('val code %1', DimEntry."Dimension Value Code");
                                    VendorCard.Init();
                                    VendorCard.SetFilter("No.", DimEntry."Dimension Value Code");
                                    if VendorCard.FindFirst() then begin
                                        DimVend := VendorCard.Name;
                                    end;
                                end;
                            until DimEntry.Next() = 0;


                        if DimComp = 'ANCORA' THEN begin
                            CheckAndCreateBatch('Ancora Innovation, LLC', generalBatch);
                            Create2Journals('Ancora Innovation, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;

                        if dimComp = 'FOUR POINTS' then begin
                            CheckAndCreateBatch('Four Points Innovation LLC', generalBatch);
                            Create2Journals('Four Points Innovation LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;

                        if DimComp = 'POSEIDON' then begin
                            //CheckAndCreateBatch('zzz_Poseidon_01122021', generalBatch);
                            //Create2Journals('zzz_Poseidon_01122021', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                            CheckAndCreateBatch('Poseidon Innovation, LLC', generalBatch);
                            Create2Journals('Poseidon Innovation, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;

                        if DimComp = '3DC' THEN begin
                            //    CheckAndCreateBatch('Deerfield D&D, LLC', generalBatch);
                            //    Create2Journals('Deerfield D&D, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, ConsolidatedAmount, DateValEnd);
                        end;
                        if DimComp = 'BLACKFAN' THEN begin
                            CheckAndCreateBatch('Blackfan Circle Inn, LLC', generalBatch);
                            Create2Journals('Blackfan Circle Inn, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'BLUE INNO' THEN begin
                            CheckAndCreateBatch('Bluefield Innovations, LLC', generalBatch);
                            Create2Journals('Bluefield Innovations, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'BLUE ONE' THEN begin
                            CheckAndCreateBatch('Blue One Biosciences, LLC', generalBatch);
                            Create2Journals('Blue One Biosciences, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'DEERFIELD BI' THEN begin
                            CheckAndCreateBatch('Deerfield BI, LLC', generalBatch);
                            Create2Journals('Deerfield BI, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'EXOHALT' THEN begin
                            CheckAndCreateBatch('Exohalt Therapeutics, LLC', generalBatch);
                            Create2Journals('Exohalt Therapeutics, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'GALIUM' THEN begin
                            CheckAndCreateBatch('Galium Biosciences LLC', generalBatch);
                            Create2Journals('Galium Biosciences LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'GREAT LAKES' THEN begin
                            CheckAndCreateBatch('Great Lakes Discovery, LLC', generalBatch);
                            Create2Journals('Great Lakes Discovery, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'HUDSON' THEN begin
                            CheckAndCreateBatch('Hudson Heights Innovations LLC', generalBatch);
                            Create2Journals('Hudson Heights Innovations LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'LAB1636' THEN begin
                            CheckAndCreateBatch('Lab1636, LLC', generalBatch);
                            Create2Journals('Lab1636, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'ORCHARD' THEN begin
                            CheckAndCreateBatch('Orchard Innovations, LLC', generalBatch);
                            Create2Journals('Orchard Innovations, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'LAKESIDE' THEN begin
                            CheckAndCreateBatch('Lakeside Discovery, LLC', generalBatch);
                            Create2Journals('Lakeside Discovery, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'PINNACLE' THEN begin
                            //CheckAndCreateBatch('zzz_Pinnacle_0112021', generalBatch);
                            //Create2Journals('zzz_Pinnacle_0112021', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                            CheckAndCreateBatch('Pinnacle Hill, LLC', generalBatch);
                            Create2Journals('Pinnacle Hill, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'RIVERWAY' THEN begin
                            CheckAndCreateBatch('Riverway Discoveries, LLC', generalBatch);
                            Create2Journals('Riverway Discoveries, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'WESTLOOP' THEN begin
                            CheckAndCreateBatch('West Loop Innovations, LLC', generalBatch);
                            Create2Journals('West Loop Innovations, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'POS 1 INC' THEN begin
                            CheckAndCreateBatch('Poseidon Innovation 1, Inc.', generalBatch);
                            Create2Journals('Poseidon Innovation 1, Inc.', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'EMPIRE' THEN begin
                            CheckAndCreateBatch('Empire Deerfield D&D, LLC', generalBatch);
                            Create2Journals('Empire Deerfield D&D, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'BLUE SQUARE' THEN BEGIN
                            CheckAndCreateBatch('Blue Square Discoveries, LLC', generalBatch);
                            Create2Journals('Blue Square Discoveries, LLC', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                        if DimComp = 'DFBI 4, INC.' THEN BEGIN
                            CheckAndCreateBatch('DFBI 4, Inc.', generalBatch);
                            Create2Journals('DFBI 4, Inc.', GLEnt, DimProject, DimDept, DimComp, DimVend, DateValEnd);
                        end;
                    until GLEnt.Next() = 0;
                if boolError then begin

                    ExclBuff.CreateNewBook('Error Entries');
                    //FillExcelBuffer(ExclBuff);
                    ExclBuff.WriteSheet('', CompanyName(), UserId());
                    ExclBuff.CloseBook();
                    ExclBuff.OpenExcel();
                end;


            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {

                group(Options)
                {
                    Caption = 'Monthly Intercompany Transactions';

                    field(DateOf; DateOf)
                    {
                        ApplicationArea = All;
                        Caption = 'Date';
                        Editable = true;
                    }
                }
            }
        }

        actions
        {
        }

    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if boolError then begin
            Message(CopySuccessWithErrorMsg);
        end else begin
            Message(CopySuccessMsg);
        end;
    end;

    var
        VarCompany: Text;
        DateOf: Text;
        CopySuccessMsg: Label 'Journals created successfully.';
        CopySuccessWithErrorMsg: Label 'Operation Completed with errors. Please check exported Excel.';
        MissingSourceErr: Label 'Could not find an account schedule with the specified name to copy from.';
        NewNameExistsErr: Label 'The new account schedule already exists.';
        NewNameMissingErr: Label 'You must specify a name for the new account schedule.';
        CompanyMissingErr: Label 'You must select a Company';
        CopySourceNameMissingErr: Label 'You must specify a valid name for the source account schedule to copy from.';
        MultipleSourcesErr: Label 'You can only copy one account schedule at a time.';
        CompanySetUpInProgressMsg: Label 'Company %1 was just created, and we are still setting it up for you.\This may take up to 10 minutes, so take a short break before you begin to use %2.', Comment = '%1 - a company name,%2 - our product name';
        ExclBuff: Record "Excel Buffer" temporary;
        boolError: Boolean;

    local procedure Token(VAR Text: Text[1024]; Separator: Text[2]) Token: Text[1024]
    var
        Pos: Integer;
    begin
        Pos := STRPOS(Text, Separator);
        IF Pos > 0 THEN BEGIN
            Token := COPYSTR(Text, 1, Pos - 1);
            IF Pos + 1 <= STRLEN(Text) THEN
                Text := COPYSTR(Text, Pos + 1)
            ELSE
                Text := '';
        END ELSE BEGIN
            Token := Text;
            Text := '';
        END;
    end;

    local procedure CheckAndCreateBatch(CompanyName: Text; GenBatch: Record "Gen. Journal Batch")
    begin
        genBatch.SetFilter(Name, '%1', 'CPY3DC');
        if NOT genBatch.Find('+') then begin
            genBatch.Init();
            genBatch.Name := 'CPY3DC';
            genBatch.Description := 'Copied from GLE';
            genBatch."No. Series" := 'GENJNL';
            genBatch."Journal Template Name" := 'GENERAL';
            genBatch.Insert(true);
        end;

        GenBatch.ChangeCompany(CompanyName);
        genBatch.SetFilter(Name, '%1', 'CPY3DC');
        if NOT genBatch.Find('+') then begin
            genBatch.Init();
            genBatch.Name := 'CPY3DC';
            genBatch.Description := 'Copied from GLE';
            // genBatch."Bal. Account Type" := "Bal. Account Type"::"G/L Account";
            genBatch."No. Series" := 'GENJNL';
            genBatch."Journal Template Name" := 'GENERAL';
            genBatch.Insert(true);
        end;
    end;


    local procedure Create2Journals(CompanyName: Text;
     GLEnt: Record "G/L Entry";
     Project: Text;
     Dept: Text;
     Company: Text;
     Vendor: Text;
     postDate: Date)
    var
        result: list of [Text];
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        ResponseText: Text;
        contentHeaders: HttpHeaders;
        dimMgt: Codeunit DimensionManagement;
        DimVal1: Record "Dimension Value";
        DimVal2: Record "Dimension Value";
        DimVal3: Record "Dimension Value";
        DimVal4: Record "Dimension Value";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLineNo: Integer;
        VendCode: Text;
        OldDimSetID: Integer;
        NewDimSetID: Integer;
        DimSetEnt: Record "Dimension Set Entry";
        dimSetTemp: Record "Dimension Set Entry" temporary;
        payload: Text;
        DocType: Enum "Gen. Journal Document Type";
        postMonthName: Text;
        DimValID: Integer;
        url: text;
        ProjValID: Integer;
        DeptValID: Integer;
        CompValID: Integer;
        VendValID: Integer;
        concat: Text;
        day: Integer;
        month: Integer;
        year: Integer;
        finalPostDate: Text;
        VendorRec: Record Vendor;
        AmountTxt: Text;
        AmountDec: Decimal;
        brk: List of [Text];
        LineWithQuotes: List of [Text];
        inter: Text;
        liner: Text;
        sessionId: Integer;
        ok: Boolean;
    begin
        postMonthName := FORMAT(postDate, 0, '<Month Text> <Year4>');
        GenJnlLine.SetFilter("Journal Template Name", 'GENERAL');
        GenJnlLine.SetFilter("Journal Batch Name", 'CPY3DC');
        if GenJnlLine.Find('+') then begin
            GenJnlLineNo := GenJnlLine."Line No.";
        end;

        GenJnlLine.Init;
        GenJnlLine."Journal Template Name" := 'General';
        GenJnlLine."Journal Batch Name" := 'CPY3DC';
        GenJnlLineNo := GenJnlLineNo + 10000;
        GenJnlLine."Line No." := GenJnlLineNo;
        GenJnlLine."Posting Date" := postDate;
        GenJnlLine."Document Type" := "Gen. Journal Document Type"::" ";
        GenJnlLine.Description := postMonthName + ' Intercompany';
        GenJnlLine.Amount := GLEnt.Amount * (-1);
        GenJnlLine."External Document No." := GLEnt."External Document No.";
        GenJnlLine."Account No." := GLEnt."G/L Account No.";
        GenJnlLine."shortcut Dimension 1 Code" := GLEnt."Global Dimension 1 Code";
        GenJnlLine."shortcut Dimension 2 Code" := GLEnt."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := GLEnt."Dimension Set ID";
        GenJnlLine.Insert();

        GenJnlLine.Init;
        GenJnlLine."Journal Template Name" := 'General';
        GenJnlLine."Journal Batch Name" := 'CPY3DC';
        GenJnlLineNo := GenJnlLineNo + 10000;
        GenJnlLine."Line No." := GenJnlLineNo;
        GenJnlLine."Posting Date" := postDate;
        GenJnlLine."Document Type" := "Gen. Journal Document Type"::" ";
        GenJnlLine.Description := postMonthName + ' Intercompany';
        GenJnlLine.Amount := GLEnt.Amount;
        GenJnlLine."External Document No." := GLEnt."External Document No.";
        GenJnlLine."Dimension Set ID" := GLEnt."Dimension Set ID";

        if Company = 'ANCORA' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12035';
                    end;
                'ANC-001|M4':
                    begin
                        GenJnlLine."Account No." := '12036';
                    end;
                'ANC-002|M5':
                    begin
                        GenJnlLine."Account No." := '12037';
                    end;
                'ANC-003|PMP22':
                    begin
                        GenJnlLine."Account No." := '12038';
                    end;
            end;
        end;
        if Company = 'FOUR POINTS' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12095';
                    end;
            end
        end;
        if Company = 'BLACKFAN' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12110';
                    end;
            end;
        end;
        if Company = 'BLUE ONE' then begin
            Case Project of
                'BLUE-001|POL-I':
                    begin
                        GenJnlLine."Account No." := '12040';
                    end;
            end;
        end;
        if Company = 'BLUE Q' then begin
            Case Project of
                'BLUE-003|POLQ':
                    begin
                        GenJnlLine."Account No." := '12045';
                    end;
            end;
        end;
        if Company = 'GALIUM' then begin
            case Project of
                'BLUE-002|GABA':
                    begin
                        GenJnlLine."Account No." := '12060';
                    end;
                'BLUE-004|NSMASE2':
                    begin
                        GenJnlLine."Account No." := '12055';
                    end;
            end;
        end;
        if Company = 'BLUE INNO' then begin
            Case Project of
                'BLUE-002|GABA':
                    begin
                        GenJnlLine."Account No." := '12060';
                    end;
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12050';
                    end;
            end;
        end;
        if Company = 'GREAT LAKES' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12120';
                    end;
            end;
        end;
        if Company = 'BLUE SQUARE' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12130';
                    end;
            end
        end;
        if Company = 'EMPIRE' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12135';
                    end;
            end
        end;
        if Company = 'RIVERWAY' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12125';
                    end;
            end;
        end;
        if Company = 'EXOHALT' then begin
            Case Project of
                'BLUE-004|NSMASE2':
                    begin
                        GenJnlLine."Account No." := '12055';
                    end;
            end;
        end;
        if Company = 'HUDSON' then begin
            Case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12065';
                    end;
            end;
        end;
        if Company = 'LAB1636' then begin
            Case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12070';
                    end;
                'LAB-001|GABA ASD':
                    begin
                        GenJnlLine."Account No." := '12071';
                    end;
                'LAB-002|FABP4':
                    begin
                        GenJnlLine."Account No." := '12072';
                    end;
            end;
        end;
        if Company = 'LAKESIDE' then begin
            Case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12075';
                    end;
                'LAKE-001|ANNEXIN A6':
                    begin
                        GenJnlLine."Account No." := '12076';
                    end;
                'LAKE-002|SEC':
                    begin
                        GenJnlLine."Account No." := '12077';
                    end;
                'LAKE-003|PKD2':
                    begin
                        GenJnlLine."Account No." := '12078';
                    end;
            end;
        end;
        if Company = 'ORCHARD' then begin
            case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12115';
                    end;
            end;
        end;
        if Company = 'PINNACLE' then begin
            Case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12080';
                    end;
                'PINN-001|NSD2':
                    begin
                        GenJnlLine."Account No." := '12081';
                    end;
                'PINN-002|CDK5/2':
                    begin
                        GenJnlLine."Account No." := '12082';
                    end;
            end;
        end;
        if Company = 'POSEIDON' then begin
            Case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12085';
                    end;
                'POS-001|BET':
                    begin
                        GenJnlLine."Account No." := '12086';
                    end;
                'POS-002|MEF2C':
                    begin
                        GenJnlLine."Account No." := '12087';
                    end;
                'POS-003|GSD1A':
                    begin
                        GenJnlLine."Account No." := '12088';
                    end;

            end;
        end;
        if Company = 'WESTLOOP' then begin
            Case Project of
                '3DC|GENERAL':
                    begin
                        GenJnlLine."Account No." := '12090';
                    end;
            END;
        END;
        if Company = 'DEERFIELD BI' then begin
            case Project of
                'DFBI-001|PPM1D':
                    begin
                        GenJnlLine."Account No." := '12100';
                    end;
                'DFBI-002|PRMT5':
                    begin
                        GenJnlLine."Account No." := '12101';
                    end;
                'DFBI-003|SHOC2':
                    begin
                        GenJnlLine."Account No." := '12102';
                    end;
                'DFBI-004|KRAS':
                    begin
                        GenJnlLine."Account No." := '12104';
                    end;
                'DFBI-005|SHANK3':
                    begin
                        GenJnlLine."Account No." := '12105';
                    end;
            end;
        end;
        if Company = 'POS 1 INC' then begin
            case Project of
                'POS 1 INC':
                    begin
                        GenJnlLine."Account No." := '12140';
                    end;
            end;
        end;
        if Company = 'DFBI 4, INC.' then begin
            case Project of
                'DFBI 4 INC':
                    begin
                        GenJnlLine."Account No." := '12145';
                    end;
            end;
        end;

        GenJnlLine."shortcut Dimension 1 Code" := GLEnt."Global Dimension 1 Code";
        GenJnlLine."shortcut Dimension 2 Code" := GLEnt."Global Dimension 2 Code";
        GenJnlLine.Insert();

        //        GenJnlLine.ChangeCompany(CompanyName);
        //        GenJnlLine.SetFilter("Journal Template Name", 'GENERAL');
        //        GenJnlLine.SetFilter("Journal Batch Name", 'CPY3DC');
        //        if GenJnlLine.Find('+') then begin
        //            GenJnlLineNo := GenJnlLine."Line No.";
        //        end;











        /*      GenJnlLine.Init;
              GenJnlLine."Journal Template Name" := 'General';
              GenJnlLine."Journal Batch Name" := 'CPY3DC';
              GenJnlLineNo := GenJnlLineNo + 10000;
              GenJnlLine."Line No." := GenJnlLineNo;
              GenJnlLine."Posting Date" := postDate;
              GenJnlLine."Document Type" := "Gen. Journal Document Type"::" ";
              GenJnlLine.Description := postMonthName + ' Intercompany';
              GenJnlLine.Amount := GLEnt.Amount * (-1);
              GenJnlLine."External Document No." := GLEnt."External Document No.";
              GenJnlLine."Account No." := GLEnt."G/L Account No.";
              GenJnlLine."shortcut Dimension 1 Code" := GLEnt."Global Dimension 1 Code";
              GenJnlLine."shortcut Dimension 2 Code" := GLEnt."Global Dimension 2 Code";
              GenJnlLine."Dimension Set ID" := GLEnt."Dimension Set ID";
              GenJnlLine.Insert();
      Session.StartSession(sessionId,Codeunit::DimensionManagement, CompanyName);







              GenJnlLine.Init;
              GenJnlLine."Journal Template Name" := 'General';
              GenJnlLine."Journal Batch Name" := 'CPY3DC';
              GenJnlLineNo := GenJnlLineNo + 10000;
              GenJnlLine."Line No." := GenJnlLineNo;
              GenJnlLine."Posting Date" := postDate;
              GenJnlLine."Document Type" := "Gen. Journal Document Type"::" ";
              GenJnlLine.Description := postMonthName + ' Intercompany';
              GenJnlLine.Amount := GLEnt.Amount;
              GenJnlLine."External Document No." := GLEnt."External Document No.";
              GenJnlLine."Dimension Set ID" := GLEnt."Dimension Set ID";

              GenJnlLine."Account No.":='21170';

              GenJnlLine."shortcut Dimension 1 Code" := GLEnt."Global Dimension 1 Code";
              GenJnlLine."shortcut Dimension 2 Code" := GLEnt."Global Dimension 2 Code";
              GenJnlLine.Insert();


      */




















        System.Sleep(200);
        RequestHeaders := Client.DefaultRequestHeaders();
        RequestHeaders.Add('Authorization', CreateBasicAuthHeader('DYN365-ADMIN', 'kMLYu2C64oLch3JkvYqzyhvfIfLgOtpd5buBj36L6k4='));// 'SwgLmOR2pyo5E4jZ+o3stdSlWxHE1nIbRDFHpt9ZTcw='));

        //        url := StrSubstNo('https://api.businesscentral.dynamics.com/v2.0/1a9533fb-c524-4eb7-96c8-fbdc362ac6a0/Sandbox/ODataV4/Company(''%1'')/General_Journals', CompanyName);

        url := StrSubstNo('https://api.businesscentral.dynamics.com/v2.0/1a9533fb-c524-4eb7-96c8-fbdc362ac6a0/Production/ODataV4/Company(''%1'')/General_Journals?$top=1 &$select=Line_No &$filter=Journal_Template_Name eq ''GENERAL'' and Journal_Batch_Name eq ''CPY3DC'' &$orderby=Line_No desc', CompanyName);
        Client.Get(url, ResponseMessage);
        ResponseMessage.Content().ReadAs(ResponseText);

        if ResponseText.Contains('Line_No":') then begin
            LineWithQuotes := ResponseText.Split('Line_No":');
            liner := LineWithQuotes.get(2);
            LineWithQuotes := liner.split('}]}');
            liner := LineWithQuotes.Get(1);
            Evaluate(GenJnlLineNo, liner);
        end;

        GenJnlLineNo := GenJnlLineNo + 10000;

        if GenJnlLine.Get('GENERAL', 'CPY3DC', GenJnlLineNo) then begin
            url := StrSubstNo('https://api.businesscentral.dynamics.com/v2.0/1a9533fb-c524-4eb7-96c8-fbdc362ac6a0/Production/ODataV4/Company(''%1'')/General_Journals(''GENERAL'',''CPY3DC'',%2)', CompanyName, GenJnlLineNo);
            Client.Delete(url, ResponseMessage);
            //GenJnlLine.Delete();
        end;
        url := StrSubstNo('https://api.businesscentral.dynamics.com/v2.0/1a9533fb-c524-4eb7-96c8-fbdc362ac6a0/Production/ODataV4/Company(''%1'')/General_Journals', CompanyName);
        VendorRec.ChangeCompany(CompanyName);
        if Vendor.Contains('(') then begin
            result := Vendor.Split('(');
            concat := result.Get(1) + '?' + result.Get(2);
            if concat.Contains(')') then begin
                result := concat.Split(')');
                Vendor := result.get(1) + '?' + result.Get(2);
            end;
        end;
        VendorRec.SetFilter(VendorRec.Name, '%1', Vendor);
        if VendorRec.FindFirst() then begin
            Vendor := VendorRec."No.";
        end;

        Project := GLEnt."Global Dimension 1 Code";
        if Project.Contains('3DC|GENERAL') then
            Project := 'GENERAL';
        AmountTxt := Format(GLEnt.Amount);
        AmountTxt := AmountTxt.Replace(',', '');
        day := Date2DMY(postDate, 1);
        month := Date2DMY(postDate, 2);
        year := Date2DMY(postDate, 3);
        finalPostDate := StrSubstNo('%1-%2-%3', year, month, day);

        payload := StrSubstNo('{"Journal_Template_Name": "GENERAL", "Journal_Batch_Name": "CPY3DC", "Line_No": %1, "Posting_Date": "%2", "External_Document_No": "%3", "Account_Type": "G/L Account", "Account_No": "%4", "Description": "%5", "Amount": %6, "Shortcut_Dimension_1_Code": "%7", "Shortcut_Dimension_2_Code": "%8", "ShortcutDimCode3": "%9", "ShortcutDimCode4": "%10"}', GenJnlLineNo, finalpostDate, GLEnt."External Document No.", GLEnt."G/L Account No.", postMonthName + ' Intercompany', AmountTxt, Project, GLEnt."Global Dimension 2 Code", Company, Vendor);
        RequestContent.WriteFrom(payload);
        RequestContent.GetHeaders(contentHeaders);
        contentHeaders.Clear();
        contentHeaders.Add('Content-Type', 'application/json');

        Client.Post(url, RequestContent, ResponseMessage);

        ResponseMessage.Content().ReadAs(ResponseText);
        if ResponseText.Contains('error') then begin
            /*if ResponseText.Contains('Line No.=') then begin
                GenJnlLineNo := GenJnlLineNo + 20000;
                if GenJnlLine.Get('GENERAL', 'CPY3DC', GenJnlLineNo) then begin
                    Message('Found');
                    url := StrSubstNo('https://api.businesscentral.dynamics.com/v2.0/1a9533fb-c524-4eb7-96c8-fbdc362ac6a0/Production/ODataV4/Company(''%1'')/General_Journals(''GENERAL'',''CPY3DC'',%2)', CompanyName, GenJnlLineNo);
                    Client.Delete(url, ResponseMessage);
                    //GenJnlLine.Delete();
                end;

                url := StrSubstNo('https://api.businesscentral.dynamics.com/v2.0/1a9533fb-c524-4eb7-96c8-fbdc362ac6a0/Production/ODataV4/Company(''%1'')/General_Journals', CompanyName);

                payload := StrSubstNo('{"Journal_Template_Name": "GENERAL", "Journal_Batch_Name": "CPY3DC", "Line_No": %1, "Posting_Date": "%2", "External_Document_No": "%3", "Account_Type": "G/L Account", "Account_No": "%4", "Description": "%5", "Amount": %6, "Shortcut_Dimension_1_Code": "%7", "Shortcut_Dimension_2_Code": "%8", "ShortcutDimCode3": "%9", "ShortcutDimCode4": "%10"}', GenJnlLineNo, finalpostDate, GLEnt."External Document No.", GLEnt."G/L Account No.", postMonthName + ' Intercompany', AmountTxt, Project, GLEnt."Global Dimension 2 Code", Company, Vendor);
                Message('payload1-1  ' + payload);

                RequestContent.WriteFrom(payload);

                RequestContent.GetHeaders(contentHeaders);
                contentHeaders.Clear();
                contentHeaders.Add('Content-Type', 'application/json');

                Client.Post(url, RequestContent, ResponseMessage);
                if ResponseText.Contains('error') then begin
                    if ResponseText.Contains('Line No.=') then begin
                        GenJnlLineNo := GenJnlLineNo + 10000;

                        payload := StrSubstNo('{"Journal_Template_Name": "GENERAL", "Journal_Batch_Name": "CPY3DC", "Line_No": %1, "Posting_Date": "%2", "External_Document_No": "%3", "Account_Type": "G/L Account", "Account_No": "%4", "Description": "%5", "Amount": %6, "Shortcut_Dimension_1_Code": "%7", "Shortcut_Dimension_2_Code": "%8", "ShortcutDimCode3": "%9", "ShortcutDimCode4": "%10"}', GenJnlLineNo, finalpostDate, GLEnt."External Document No.", GLEnt."G/L Account No.", postMonthName + ' Intercompany', AmountTxt, Project, GLEnt."Global Dimension 2 Code", Company, Vendor);
                        Message('payload1-2  ' + payload);

                        RequestContent.WriteFrom(payload);

                        RequestContent.GetHeaders(contentHeaders);
                        contentHeaders.Clear();
                        contentHeaders.Add('Content-Type', 'application/json');

                        Client.Post(url, RequestContent, ResponseMessage);
                        if ResponseText.Contains('error') then begin
                            Message(ResponseText);
                        end else begin
                            AmountDec := GLEnt.Amount * (-1);
                            AmountTxt := Format(AmountDec);
                            AmountTxt := AmountTxt.Replace(',', '');

                            GenJnlLineNo := GenJnlLineNo + 10000;
                            payload := StrSubstNo('{"Journal_Template_Name": "GENERAL", "Journal_Batch_Name": "CPY3DC", "Line_No": %1, "Posting_Date": "%2", "External_Document_No": "%3", "Account_Type": "G/L Account", "Account_No": "%4", "Description": "%5", "Amount": %6, "Shortcut_Dimension_1_Code": "%7", "Shortcut_Dimension_2_Code": "%8", "ShortcutDimCode3": "%9", "ShortcutDimCode4": "%10"}', GenJnlLineNo, finalpostDate, GLEnt."External Document No.", '21170', postMonthName + ' Intercompany', AmountTxt, Project, GLEnt."Global Dimension 2 Code", Company, Vendor);
                            //Message('payload2: ' + payload);
                            RequestContent.WriteFrom(payload);

                            RequestContent.GetHeaders(contentHeaders);
                            contentHeaders.Clear();
                            contentHeaders.Add('Content-Type', 'application/json');

                            Client.Post(url, RequestContent, ResponseMessage);
                            //Message('Resp2: ' + ResponseText);
                            ResponseMessage.Content().ReadAs(ResponseText);
                            if ResponseText.Contains('error') then begin
                                Message(ResponseText);
                            end;
                        end;
                    end else begin
                        Message(ResponseText);
                    end;
                end else begin
                    AmountDec := GLEnt.Amount * (-1);
                    AmountTxt := Format(AmountDec);
                    AmountTxt := AmountTxt.Replace(',', '');

                    GenJnlLineNo := GenJnlLineNo + 10000;
                    payload := StrSubstNo('{"Journal_Template_Name": "GENERAL", "Journal_Batch_Name": "CPY3DC", "Line_No": %1, "Posting_Date": "%2", "External_Document_No": "%3", "Account_Type": "G/L Account", "Account_No": "%4", "Description": "%5", "Amount": %6, "Shortcut_Dimension_1_Code": "%7", "Shortcut_Dimension_2_Code": "%8", "ShortcutDimCode3": "%9", "ShortcutDimCode4": "%10"}', GenJnlLineNo, finalpostDate, GLEnt."External Document No.", '21170', postMonthName + ' Intercompany', AmountTxt, Project, GLEnt."Global Dimension 2 Code", Company, Vendor);
                    //Message('payload2: ' + payload);
                    RequestContent.WriteFrom(payload);

                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');

                    Client.Post(url, RequestContent, ResponseMessage);
                    //Message('Resp2: ' + ResponseText);
                    ResponseMessage.Content().ReadAs(ResponseText);
                    if ResponseText.Contains('error') then begin
                        Message(ResponseText);
                    end;
                end;
            end else begin
                Message(ResponseText);
            end;*/



            boolError := true;


            ExclBuff.NewRow();
            ExclBuff.AddColumn(finalpostDate, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('G/L Account', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(GLEnt."G/L Account No.", false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(postMonthName + ' Intercompany', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(AmountTxt, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(AmountTxt, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(GLEnt."External Document No.", false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(Project, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(GLEnt."Global Dimension 2 Code", false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(Company, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(Vendor, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);


            ExclBuff.NewRow();
            ExclBuff.AddColumn(finalpostDate, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('G/L Account', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(GLEnt."G/L Account No.", false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(postMonthName + ' Intercompany', false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('-' + AmountTxt, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn('-' + AmountTxt, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(GLEnt."External Document No.", false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(Project, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(GLEnt."Global Dimension 2 Code", false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(Company, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);
            ExclBuff.AddColumn(Vendor, false, '', false, false, false, '', ExclBuff."Cell Type"::Text);


            ///            Message('Failed to create entry in company %1 with values %2', CompanyName, payload);
            //            Message(ResponseText);
        end else begin
            System.Sleep(200);
            AmountDec := GLEnt.Amount * (-1);
            AmountTxt := Format(AmountDec);
            AmountTxt := AmountTxt.Replace(',', '');

            GenJnlLineNo := GenJnlLineNo + 10000;
            payload := StrSubstNo('{"Journal_Template_Name": "GENERAL", "Journal_Batch_Name": "CPY3DC", "Line_No": %1, "Posting_Date": "%2", "External_Document_No": "%3", "Account_Type": "G/L Account", "Account_No": "%4", "Description": "%5", "Amount": %6, "Shortcut_Dimension_1_Code": "%7", "Shortcut_Dimension_2_Code": "%8", "ShortcutDimCode3": "%9", "ShortcutDimCode4": "%10"}', GenJnlLineNo, finalpostDate, GLEnt."External Document No.", '21170', postMonthName + ' Intercompany', AmountTxt, Project, GLEnt."Global Dimension 2 Code", Company, Vendor);
            //Message('payload2: ' + payload);
            RequestContent.WriteFrom(payload);

            RequestContent.GetHeaders(contentHeaders);
            contentHeaders.Clear();
            contentHeaders.Add('Content-Type', 'application/json');

            Client.Post(url, RequestContent, ResponseMessage);
            //Message('Resp2: ' + ResponseText);
            ResponseMessage.Content().ReadAs(ResponseText);
            if ResponseText.Contains('error') then begin
                Message(ResponseText);
            end;
        end;
    end;
















    procedure CreateBasicAuthHeader(UserName: Text;
                Password:
                    Text):
            Text
    var
        TempBlob: Record TempBlob;
    begin
        TempBlob.WriteAsText(StrSubstNo('%1:%2', UserName, Password), TextEncoding::UTF8);
        exit(StrSubstNo('Basic %1', TempBlob.ToBase64String()));
    end;


    [IntegrationEvent(false, false)]
    local procedure OnCompanyChange(NewCompanyName: Text; var IsSetupInProgress: Boolean)
    begin
    end;





    local procedure CheckColumnLayout(Name: Text[10]; FromAccSched: Record "Acc. Schedule Name"; company: Text) isExist: Boolean
    var
        ColLayoutName: Record "Column Layout Name";

    begin

        ColLayoutName.ChangeCompany(company);
        //ColLayoutName.Name := FromAccSched."Default Column Layout";
        //ColLayoutName.SetFilter(Name, fromAccSched."Default Column Layout");
        if (ColLayoutName.Get(FromAccSched."Default Column Layout"))
            then begin
            isExist := true;
            //CreateColumnLayout()
        end else begin
            isExist := false;
        end;
    end;

    local procedure CreateColumnLayoutName(Name: Text; FromColLayout: Record "Column Layout Name"; Company: Text)
    var
        ColLayoutName: Record "Column Layout Name";
    begin
        ColLayoutName.ChangeCompany(Company);
        if ColLayoutName.Get(Name) then
            exit;
        ColLayoutName.Init();
        ColLayoutName.TransferFields(FromColLayout);
        ColLayoutName.Name := Name;
        ColLayoutName.Insert();
    end;

    local procedure CreateNewAccountScheduleName(NewName: Code[10]; FromAccScheduleName: Record "Acc. Schedule Name"; company: Text)
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.ChangeCompany(company);
        if AccScheduleName.Get(NewName) then
            exit;

        AccScheduleName.Init();
        AccScheduleName.TransferFields(FromAccScheduleName);
        AccScheduleName.Name := NewName;
        AccScheduleName.Insert();
    end;

    local procedure CreateColumnLayout(NewName: Text; FromColLayout: Record "Column Layout"; company: text)
    var
        ColLayout: Record "Column Layout";
    begin
        ColLayout.ChangeCompany(company);
        if ColLayout.Get(NewName, FromColLayout."Line No.") then
            exit;

        ColLayout.Init();
        ColLayout.TransferFields(FromColLayout);
        colLayout."Column Layout Name" := NewName;
        ColLayout.Insert();
    end;

    local procedure CreateNewAccountScheduleLine(NewName: Code[10]; FromAccScheduleLine: Record "Acc. Schedule Line"; company: Text)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.ChangeCompany(company);
        if AccScheduleLine.Get(NewName, FromAccScheduleLine."Line No.") then
            exit;

        AccScheduleLine.Init();
        AccScheduleLine.TransferFields(FromAccScheduleLine);
        AccScheduleLine."Schedule Name" := NewName;
        AccScheduleLine.Insert();
    end;
}

codeunit 50105 CreateEditDimEntry
{
    Permissions = tabledata "Dimension Set Entry" = rimd;
    trigger OnRun()
    begin

    end;

    procedure insertEntry(CompanyName: Text; dimSetID: Integer; Project: Text; Dept: Text; Company: Text; Vendor: Text)
    var
        DimSetEnt: Record "Dimension Set Entry";
        VendorList: Record Vendor;
        VendorNum: Text;
    begin

        VendorList.ChangeCompany(CompanyName);
        if Vendor <> ''
        then begin
            VendorList.SetFilter(Name, Vendor);
            if VendorList.Find() then begin
                VendorNum := VendorList."No.";
            end;
        end;
        DimSetEnt.ChangeCompany(CompanyName);
        DimSetEnt.init();
        DimSetEnt."Dimension Set ID" := dimSetID + 1;
        DimSetEnt."Dimension Code" := 'PROJECT';
        DimSetEnt."Dimension Value Code" := Project;
        DimSetEnt.Insert();
        DimSetEnt.init();
        DimSetEnt."Dimension Set ID" := dimSetID + 1;
        DimSetEnt."Dimension Code" := 'DEPARTMENT';
        DimSetEnt."Dimension Value Code" := Dept;
        DimSetEnt.Insert();
        DimSetEnt.init();
        DimSetEnt."Dimension Set ID" := dimSetID + 1;
        DimSetEnt."Dimension Code" := 'COMPANY';
        DimSetEnt."Dimension Value Code" := Company;
        DimSetEnt.Insert();
        DimSetEnt.Init();
        if VendorNum <> '' then begin
            DimSetEnt."Dimension Set ID" := dimSetID + 1;
            DimSetEnt."Dimension Code" := 'VENDOR';
            DimSetEnt."Dimension Value Code" := Vendor;
            DimSetEnt."Dimension Value Name" := VendorNum;
            DimSetEnt.Insert();
        end;

    end;

    var
        myInt: Integer;
}