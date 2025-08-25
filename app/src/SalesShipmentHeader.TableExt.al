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