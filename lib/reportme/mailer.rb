module Reportme
  class Mailer < ActionMailer::Base
    def message (_from, _recipients, _subject, _body, attachments=[])
      
      subject(_subject)
      from(_from)
      recipients(_recipients)
      body(_body)
  
      unless attachments.blank?
        attachments.each do |att|
          content_type = att[:content_type] 

          attachment content_type do |a|
            a.filename = att[:filename]
          
            a.body = File.read(att[:filepath])  if att[:filepath]
            a.body = att[:text]                 if att[:text]
          
            a.transfer_encoding = 'quoted-printable' if content_type =~ /^text\//
          end
        end
      end

    end
  end
end