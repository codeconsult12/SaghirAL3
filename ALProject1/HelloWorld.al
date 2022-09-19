// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

page 50111 AttachmentAPI
{
    PageType = Card;
    Caption = 'Document Attachemnt API';
    //   APIPublisher = 'Deerfield';
    //   APIGroup = 'app';
    //   APIVersion = 'v1.0';
    //   EntityName = 'DocumentAttachment';
    //   EntitySetName = 'DocumentAttachment';
    SourceTable = "Incoming Document Attachment";
    DelayedInsert = true;

    trigger OnInit()
    var
        incomingAttachment: Record "Incoming Document Attachment";
        file: File;
        FileOutStream: OutStream;
        FileInStream: InStream;
        filemgmt: Codeunit "File Management";
    begin
        incomingAttachment.Init();
        incomingAttachment.Content.Import('C:/Sample.jpg');
        
        //        file.Create('C:/Sample.jpg');
        //        incomingAttachment.Content.CreateOutStream(FileOutStream);
        //        CopyStream(FileOutStream,FileInStream);
        incomingAttachment.Modify(true);
        //        filemgmt.UploadFileSilent('C:/Sample.jpg');
        //      Bytes := Convert
        //    incomingAttachment.Content.CreateOutStream();
    end;


}
codeunit 50100 UploadAttachment
{
    trigger OnRun()
    var
        incomingAttachment: Record "Incoming Document Attachment";
        file: File;
        FileOutStream: OutStream;
        FileInStream: InStream;
        filemgmt: Codeunit "File Management";
    begin
        incomingAttachment.Init();
        incomingAttachment.Content.Import('C:/Sample.jpg');
        //        file.Create('C:/Sample.jpg');
        //        incomingAttachment.Content.CreateOutStream(FileOutStream);
        //        CopyStream(FileOutStream,FileInStream);
        incomingAttachment.Modify(true);
        //        filemgmt.UploadFileSilent('C:/Sample.jpg');
        //      Bytes := Convert
        //    incomingAttachment.Content.CreateOutStream();
    end;
}