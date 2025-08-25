codeunit 50251 "ABC Sign Sales Shipment" implements "BYD PDF SIG IHandler"
// Your custom interface implementation
// Handles loading PDFs from Sales Shipment reports and saving signed PDFs to Document Attachment
{
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        TempBlob: Codeunit "Temp Blob";
        IsInitialized: Boolean;
        HandlerNotInitializedErr: Label 'Sales Shipment Handler is not initialized. Please set the Sales Shipment Header record first.';
        HeaderNotExistErr: Label 'Sales Shipment Header %1 does not exist.', Comment = '%1 = Sales Shipment No.';
        PDFGenerateErr: Label 'Failed to generate PDF from Sales Shipment report for shipment %1. Error: %2', Comment = '%1 = Sales Shipment No., %2 = Error Text';
        SignedFilenameTxt: Label 'Sales_Shipment_%1_Signed.pdf', Comment = '%1 = Sales Shipment No.';

    procedure LoadPDF(var PDFStream: InStream): Boolean
    var
        ReportSelection: Record "Report Selections";
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        if not IsInitialized then
            Error(HandlerNotInitializedErr);

        if not SalesShipmentHeader.Get(SalesShipmentHeader."No.") then
            Error(HeaderNotExistErr, SalesShipmentHeader."No.");

        SalesShipmentHeader.SetRecFilter();

        // Create temporary blob to store the PDF
        TempBlob.CreateInStream(PDFStream, TextEncoding::Windows);
        TempBlob.CreateOutStream(OutStream, TextEncoding::Windows);

        ReportSelection.GetPdfReportForCust(TempBlob, Enum::"Report Selection Usage"::"S.Shipment", SalesShipmentHeader, SalesShipmentHeader."Sell-to Customer No.");
        if not TempBlob.HasValue() then
            Error(PDFGenerateErr, SalesShipmentHeader."No.", GetLastErrorText());

        exit(true);
    end;

    procedure SavePDF(var PDFStream: InStream): Boolean
    var
        FileName: Text;
    begin
        if not IsInitialized then
            Error(HandlerNotInitializedErr);
        if PDFStream.Length = 0 then
            exit(false);
        // Generate filename
        FileName := StrSubstNo(SignedFilenameTxt, SalesShipmentHeader."No.");

        // Save to Document Attachment table
        SalesShipmentHeader.Get(SalesShipmentHeader.RecordId());
        SalesShipmentHeader."ABC My Signed Document".ImportStream(PDFStream, FileName, 'application/pdf');
        SalesShipmentHeader.Modify();
        exit(SalesShipmentHeader."ABC My Signed Document".HasValue());
    end;

    procedure SetSalesShipmentHeader(Rec: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader := Rec;
        IsInitialized := true;
    end;

    procedure GetSignedFileName(SalesShipmentNo: Code[20]): Text
    var
        StringConversionManagement: Codeunit StringConversionManagement;
    begin
        exit(StrSubstNo(SignedFilenameTxt, StringConversionManagement.RemoveNonAlphaNumericCharacters(SalesShipmentNo)));
    end;
}