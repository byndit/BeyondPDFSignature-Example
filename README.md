# Beyond PDF Signature - Custom Implementation Example

This repository demonstrates how to implement custom PDF signature functionality in Microsoft Dynamics 365 Business Central using the Beyond PDF Signature extension. The example shows how to add PDF signing capabilities to the Sales Shipment Header table, but the pattern can be applied to any table in Business Central.

## Overview

This implementation provides:
- **PDF Generation**: Automatically generates PDFs from Business Central reports
- **Digital Signature**: Allows users to digitally sign PDF documents
- **Document Storage**: Saves signed PDFs directly to the record using Media fields
- **User Interface**: Adds signing actions to existing pages with intuitive controls

## Architecture

The solution consists of three main components:

### 1. Table Extension ([`SalesShipmentHeader.TableExt.al`](app/src/SalesShipmentHeader.TableExt.al))
Extends the target table to store signed documents:

```al
tableextension 50251 "ABC Sales Shipment Header" extends "Sales Shipment Header"
{
    fields
    {
        field(50251; "ABC My Signed Document"; Media)
        {
            Caption = 'My Signed Document';
            Description = 'Holds the signed version of the sales shipment document after signing.';
        }
    }
}
```

### 2. Page Extension ([`PostedSalesShipment.PageExt.al`](app/src/PostedSalesShipment.PageExt.al))
Adds signing functionality to the user interface:

- **Sign Document**: Action to initiate the signing process
- **Show Signed Document**: Action to view previously signed documents
- **Smart Enabling**: Actions are enabled/disabled based on document state

### 3. Handler Codeunit ([`SignSalesShipment.Codeunit.al`](app/src/SignSalesShipment.Codeunit.al))
Implements the [`BYD PDF SIG IHandler`](app/src/SignSalesShipment.Codeunit.al:1) interface to handle PDF operations:

- **LoadPDF()**: Generates PDF from Business Central reports
- **SavePDF()**: Stores signed PDF back to the record
- **Initialization**: Sets up the handler with the current record

## How It Works

### Signing Process Flow

1. **User Initiates Signing**: User clicks "Sign Document with your Customer" action
2. **PDF Generation**: System generates PDF using Business Central's report selection
3. **Signature Interface**: [`BYD PDF SIG Signpad`](app/src/PostedSalesShipment.PageExt.al:23) page opens with the PDF
4. **Digital Signing**: User and customer sign the document digitally
5. **Document Storage**: Signed PDF is saved to the [`"ABC My Signed Document"`](app/src/SalesShipmentHeader.TableExt.al:5) field
6. **UI Updates**: "Show Signed Document" action becomes available

### Key Features

- **Duplicate Prevention**: Warns users if document is already signed
- **Report Integration**: Uses Business Central's standard report selection mechanism
- **Media Storage**: Leverages native Media field type for efficient storage
- **File Naming**: Generates consistent filenames for signed documents

## Implementation Guide

Follow these steps to implement PDF signature functionality for any table:

### Step 1: Create Table Extension

Create a table extension for your target table:

```al
tableextension [YourID] "[Your Prefix] [Table Name]" extends "[Target Table]"
{
    fields
    {
        field([YourFieldID]; "[Your Prefix] Signed Document"; Media)
        {
            Caption = 'Signed Document';
            Description = 'Holds the signed version of the document after signing.';
        }
    }
}
```

### Step 2: Create Handler Codeunit

Implement the [`BYD PDF SIG IHandler`](app/src/SignSalesShipment.Codeunit.al:1) interface:

```al
codeunit [YourID] "[Your Prefix] Sign [Entity]" implements "BYD PDF SIG IHandler"
{
    var
        [YourRecord]: Record "[Your Table]";
        TempBlob: Codeunit "Temp Blob";
        IsInitialized: Boolean;

    procedure LoadPDF(var PDFStream: InStream): Boolean
    begin
        // Generate PDF from your report
        // Use ReportSelection.GetPdfReportForCust() or Report.SaveAs()
        // Return true if successful
    end;

    procedure SavePDF(var PDFStream: InStream): Boolean
    begin
        // Save signed PDF to your Media field
        [YourRecord]."[Your Prefix] Signed Document".ImportStream(PDFStream, FileName, 'application/pdf');
        [YourRecord].Modify();
        exit([YourRecord]."[Your Prefix] Signed Document".HasValue());
    end;

    procedure Set[YourRecord](Rec: Record "[Your Table]")
    begin
        [YourRecord] := Rec;
        IsInitialized := true;
    end;
}
```

### Step 3: Create Page Extension

Add signing actions to your page:

```al
pageextension [YourID] "[Your Prefix] [Page Name]" extends "[Target Page]"
{
    actions
    {
        addafter([ExistingAction])
        {
            action("[Your Prefix] Sign")
            {
                ApplicationArea = All;
                Caption = 'Sign Document';
                Image = Signature;
                
                trigger OnAction()
                var
                    [YourHandler]: Codeunit "[Your Prefix] Sign [Entity]";
                    PDFSignaturePage: Page "BYD PDF SIG Signpad";
                begin
                    // Initialize handler
                    [YourHandler].Set[YourRecord](Rec);
                    
                    // Set handler in PDF signature page
                    PDFSignaturePage.SetPDFHandler([YourHandler]);
                    
                    // Open signature page
                    PDFSignaturePage.RunModal();
                end;
            }
            
            action("[Your Prefix] ShowSigned")
            {
                ApplicationArea = All;
                Caption = 'Show Signed Document';
                Image = DocumentEdit;
                Enabled = IsAlreadySigned;
                
                trigger OnAction()
                var
                    TenantMedia: Record "Tenant Media";
                    InS: InStream;
                begin
                    if TenantMedia.Get(Rec."[Your Prefix] Signed Document".MediaId()) then
                        if TenantMedia.Content.HasValue then begin
                            TenantMedia.CalcFields(Content);
                            TenantMedia.Content.CreateInStream(InS);
                            File.ViewFromStream(InS, 'SignedDocument.pdf');
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
        if not TenantMedia.Get(Rec."[Your Prefix] Signed Document".MediaId()) then
            exit(false);
        exit(TenantMedia.Content.HasValue());
    end;

    var
        IsAlreadySigned: Boolean;
}
```

## Prerequisites

1. **Beyond PDF Signature Extension**: Install the Beyond PDF Signature extension in your Business Central environment from Appsource
2. **Report Configuration**: Ensure your target table has associated reports configured in Report Selections
3. **Permissions**: Users need appropriate permissions to modify the target table and access the signing functionality

## Customization Options

### PDF Source Customization

Modify the [`LoadPDF()`](app/src/SignSalesShipment.Codeunit.al:14) method to:
- Use different reports
- Apply custom filters
- Generate PDFs from multiple sources
- Add custom headers/footers

### Storage Customization

Modify the [`SavePDF()`](app/src/SignSalesShipment.Codeunit.al:39) method to:
- Save to Document Attachments instead of Media fields
- Implement custom file naming conventions
- Add metadata or tags
- Integrate with external document management systems

### UI Customization

Modify the page extension to:
- Add custom validation before signing
- Implement approval workflows
- Add audit trail functionality
- Customize action placement and appearance

## Best Practices

1. **Error Handling**: Implement comprehensive error handling for PDF generation and storage
2. **Performance**: Use temporary blobs for large PDF operations
3. **Security**: Validate user permissions before allowing signing operations
4. **Naming Conventions**: Use consistent prefixes to avoid conflicts
5. **Testing**: Test with various document sizes and user scenarios

## Troubleshooting

### Common Issues

- **PDF Generation Fails**: Check report selection configuration and permissions
- **Signing Page Doesn't Open**: Verify Beyond PDF Signature extension is installed and configured
- **Signed Document Not Saved**: Check table permissions and Media field configuration

### Debug Tips

- Use the debugger to step through the [`LoadPDF()`](app/src/SignSalesShipment.Codeunit.al:14) and [`SavePDF()`](app/src/SignSalesShipment.Codeunit.al:39) methods
- Check the Event Log for any system errors
- Verify the TempBlob has content before attempting to save

## Support

For issues related to the Beyond PDF Signature extension itself, contact the extension provider. For implementation questions, refer to the Microsoft Dynamics 365 Business Central documentation.

## License

This example implementation is provided as-is for educational purposes. Ensure compliance with your organization's licensing requirements when implementing in production environments.
