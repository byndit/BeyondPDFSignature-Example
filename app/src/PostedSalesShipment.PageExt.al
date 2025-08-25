pageextension 50251 "ABC Posted Sales Shipment" extends "Posted Sales Shipment"
{
    actions
    {
        addbefore("&Print_Promoted")
        {
            actionref("ABC Sign_Promoted"; "ABC Sign") { }
            actionref("ABC ShowSigned_Promoted"; "ABC ShowSigned") { }
        }

        addbefore("&Print")
        {
            action("ABC Sign")
            {
                ApplicationArea = All;
                Caption = 'Sign Document with your Customer';
                Image = Signature;
                ToolTip = 'Open the PDF signature page to sign this sales shipment document.';

                trigger OnAction()
                var
                    SalesShipmentHandler: Codeunit "ABC Sign Sales Shipment"; //your custom interface implementation
                    PDFSignaturePage: Page "BYD PDF SIG Signpad";
                    AlreadySignedMsg: Label 'This sales shipment document has already been signed. Do you want to create a new signed version?';
                    ConfirmMsg: Label 'Do you want to sign the sales shipment document %1?', Comment = '%1 = Sales Shipment No.';
                begin
                    // Check if document is already signed
                    if Rec."ABC My Signed Document".HasValue() then begin
                        if not Confirm(AlreadySignedMsg, false) then
                            exit;
                    end else
                        if not Confirm(ConfirmMsg, false, Rec."No.") then
                            exit;

                    // Initialize your custom interface with current sales shipment
                    SalesShipmentHandler.SetSalesShipmentHeader(Rec);

                    // Set handler in PDF signature page
                    PDFSignaturePage.SetPDFHandler(SalesShipmentHandler);

                    // Open PDF signature page
                    PDFSignaturePage.RunModal();
                end;
            }
            action("ABC ShowSigned")
            {
                ApplicationArea = All;
                Caption = 'Show Signed Document';
                Image = DocumentEdit;
                Enabled = IsAlreadySigned;
                ToolTip = 'Open the signed document for this sales shipment.';
                trigger OnAction()
                var
                    TenantMedia: Record "Tenant Media";
                    SignSalesShipment: Codeunit "ABC Sign Sales Shipment";
                    InS: InStream;
                    FileName: Text;
                begin
                    if TenantMedia.Get(Rec."ABC My Signed Document".MediaId()) then
                        if TenantMedia.Content.HasValue then begin
                            TenantMedia.CalcFields(Content);
                            TenantMedia.Content.CreateInStream(InS);
                            FileName := SignSalesShipment.GetSignedFileName(Rec."No.");
                            File.ViewFromStream(InS, FileName);
                        end;
                end;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        IsAlreadySigned := IsSignedAndSaved();
    end;

    local procedure IsSignedAndSaved(): Boolean
    var
        TenantMedia: Record "Tenant Media";
    begin
        if not TenantMedia.Get(Rec."ABC My Signed Document".MediaId()) then
            exit(false);
        exit(TenantMedia.Content.HasValue());
    end;

    var
        IsAlreadySigned: Boolean;
}