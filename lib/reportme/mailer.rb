module Reportme
  class Mailer < ActionMailer::Base
    def message (from, recipients, subject, body, attachments=[])
      from        'jan.zimmek@toptarif.de'
      recipients  'jan.zimmek@toptarif.de'
      subject     subject
      body        body
  
      attachments.each do |att|
        content_type = att[:content_type] 

        attachment content_type do |a|
          a.filename = att[:filename]
          
          a.body = File.read(att[:filepath])  if att[:filepath]
          a.body = att[:text]                 if att[:text]
          
          a.transfer_encoding = 'quoted-printable' if content_type =~ /^text\//
        end
      end

      # # Include all the pdf files in the PDF subdirectory as attachments.
      # FileList['PDF/*.pdf'].each do |path|
      #   file = File.basename(path)
      #   mime_type = MIME::Types.of(file).first
      #   content_type = mime_type ? mime_type.content_type : 'application/binary'
      #   attachment (content_type) do |a|
      #     a.body = File.read(path)
      #     a.filename = file
      #     a.transfer_encoding = 'quoted-printable' if content_type =~ /^text\//
      #   end
      # end
    end
  end
end