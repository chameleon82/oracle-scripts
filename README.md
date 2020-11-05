oracle-scripts
==============

Oracle PL/SQL package extensions

## How to use MAIL_PKG

#### Short example
```SQL
  BEGIN
      MAIL_PKG.SEND( 'a.ivanov@yourcomany.ru','Test subject', 'Some message!');
  END;
```  
#### Send text body more than 32kb
```SQL
    DECLARE
      v clob:='Some text message over 32kb'||chr(10)||chr(13);
      t varchar2(255):=' The quick brown fox jumps over the lazy dog. '
                     ||' The quick brown fox jumps over the lazy dog. '
                     ||' The quick brown fox jumps over the lazy dog. '||chr(10)||chr(13);
    BEGIN
      -- Make text more than 32kb symbols
      for x in 1..300 loop
        v:=v||to_char(x)||' '||t;
      end loop;
      MAIL_PKG.SEND( 'a.ivanov@yourcompany.ru','Test subject', v);
    END ;
```
#### Send email with BLOB attachment which can be selected from table
```SQL
    DECLARE
      vBlob BLOB;
      BEGIN
     SELECT file_data INTO vBlob FROM FND_LOBS WHERE FILE_ID = 161005;
     MAIL_PKG.ADD_ATTACHMENT( vBlob
                             ,'MessageOver32kb.htm'
                             ,'text/html'
                            );
      MAIL_PKG.SEND( 'a.ivanov@yourcomany.ru','Big message', NULL);
    END;
```
#### Extended example with few attachements (FILE,CLOB,BLOB)
```SQL
    DECLARE
      vBlob BLOB;
      vClob CLOB;
    BEGIN
     -- Setup connection to mail server localhost:25
     MAIL_PKG.SET_MAILSERVER ('localhost',25);
     -- Set mail authentication 
     MAIL_PKG.SET_AUTH ('a.nekrasov','password');

     -- Attach image from local server directory
     -- Directory alliases can be listed with next query SELECT * FROM DBA_DIRECTORIES
     MAIL_PKG.ADD_ATTACHMENT( 'MY_DIR_ALIAS' -- Directory alias
                             ,'logo.jpeg'    -- Directory file name (Will be the same in the attachment)
                             ,'image/jpeg'   -- Mime type of the attachment
                            );

     -- Attach BLOB selected from DataBase
     SELECT file_data INTO vBlob FROM FND_LOBS WHERE FILE_ID = 161005;
     MAIL_PKG.ADD_ATTACHMENT( vBlob
                             ,'ReportResult.htm'  -- File name in the attachment
                             ,'text/html'         -- Mime type of the attachment
                            );

     -- Attach prepared CLOB
     vClob := '<HTML><TITLE>Clob Attachment Example</TITLE><BODY><b>This</b> is clob attachment example</BODY></HTML>';
     MAIL_PKG.ADD_ATTACHMENT( vClob
                             ,'ClobResult.htm'    -- File name in the attachment
                             ,'text/html'         -- Mime type of the attachment
                            );
     -- Send email 
     -- mailto - List of recepients. Simple `a.ivanov@yourcomany.ru` and full `A. Ivanov <a.ivanov@yourcomany.ru>` formats allowed
     -- subject - Mail subject
     -- message - Text body (CLOB)
     -- mailfrom - Sender email
     -- mimetype - Text body mime type,  text/html and text/plain (by default) is allowed
     -- priority - Message priority from 1 to 5, 1 - the highest, 3 - default
     MAIL_PKG.SEND( mailto => 'A. Ivanov <a.ivanov@yourcomany.ru>, O.Petrov <o.petrov@yourcompany.ru>'
                  , subject => 'Test subject'
                  , message => 'Some <b>bold</b> message!'
                  , mailfrom => 'Oracle Notify <no-reply@yourcompany.ru>'
                  , mimetype => 'text/html'
                  , priority => 1
                  );
    END;
```    
#### Example with image printed in the text body 
```SQL
DECLARE
 -- Convert logo into CLOB
 vClob CLOB :=  UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.base64_decode(UTL_RAW.CAST_TO_RAW(
  'R0lGODlhbgAeAPQAAPFTfP7y9f3j6vBFce0oW/vV3/m4yfR/nfBTe+43Zvebs/Jih/Nwku0oWviq' 
||'vvrF0/epvf3w9PFhhvzi6e42ZfR+nPvU3vNvkfaasu9EcPm3yPWMp/aNqPrG1OwaUP///yH/C01T'
||'T0ZGSUNFOS4wGAAAAAxtc09QTVNPRkZJQ0U5LjAgJPn1cgAh/wtNU09GRklDRTkuMBgAAAAMY21Q'
||'UEpDbXAwNzEyAAAAA0gAc7wALAAAAABuAB4AAAX/4CeOY6Asiad6BKAIZCzPdG3feH4LzOr/i4Ju'
||'SCwac5yf8ncIHJ/Q6CwAWFpXA6d0y9UFBtewJ9stm2NVcZh8bm+TVgpirsrM7wjVwc1/CpQXDzIZ'
||'FTN5Hh19ikM9Kw2CMhYeEzITKwA2CgALBiQBHByJHwYcAKYAHDAiBaCqI6ypIgqgQiICoFofDgun'
||'B50fJgymCxwGAT8YIxEPzA95EMwYlB8VPrUycCqiHx0qHCJpTCJw2+PaIisJI92I4EqYX+8OPg0j'
||'Gg1XFCIR+Ct7M2AI6FnnzZ0HU2DOkYux8IMPUewSFVDR4pSDDwconkK1wAeCERLCJPuA4ceAKXrA'
||'/6gTwe7bhzQjFBRsOKKhD0zczsn0cBGNClciUqzIMMJCPyUNIoigoGTGPA8GMnpQ1dIgCRWYaJpr'
||'59AHjIgftIroyDOGkmkfIoRUUugDhCVARTQKYEBFz6ovVYyo6+GbWJsHVTDI2Q6Ogg6IOzjhe/Ca'
||'Egkx7v2YduhHuaAe1B3zMJiwyzSgDggsfI4E4FI/wWbz4VKqYCdLJCgtevSCiAdWLv/hLEIly4J5'
||'lfz7W9pbS9VLFKxLyGLikgYaSLxVYUHEBSvXRDxV8hV4GgBCO4ctXbN43w8pCPBNJDaGgtHgr8ge'
||'UUeEJSsyGilRjhfmbgJaEMdVQU+RxR55NBQwGvlZVtiGjgcNzMHUEifFIFACifG1gGdWYQQcHL+U'
||'N+B56D00Hlc2JLSTFRvQp4YH/7wiGAnpcRicCAEIREB3YxiQ2CfmubRaIuwM4CNiMNxSTFQqJLAb'
||'hBtIcAcEI0ynRnYf7KTcCI0U0J9eW3U22kOn4ThmIjm+Q9gPFzXiYCRHrYENC0DxZYAAAm3ZUYXA'
||'BLQKg5kVwFctAoW4UwJaFAAoAXsIwJwHnNiiQnQyQBBnGJctoukMGVFQwQbQYFDBhC9uuOmpNTz6'
||'4g+IouqqDPGs+gMBWL76aqyyBmrrrp64VmouvAbbQThXAJBpsMHeQqwKAxxQK7KbhgAAOw=='
)) )
;
 v_id varchar2(25); -- Logo file must have ID to locate it in the text
BEGIN
     -- Attach logo to the email
     -- disposition = MAIL_PKG.DISPOSITION_INLINE -- We don't want to have this file available as an attachment
     MAIL_PKG.ADD_ATTACHMENT( vClob -- logo byte data
                             ,'logo.gif' -- File name in the email
                             ,'image/gif' -- Mime type of the attachment
                             , disposition => MAIL_PKG.DISPOSITION_INLINE
                            );
     -- Retrieve attached file ID                     
     v_id := MAIL_PKG.LAST_ATTACHMENT_ID;

     -- Send email with mimetype = text/html
     -- and put image there <img src="cid:'|| v_id || '">
     -- should point to the attached image
     MAIL_PKG.SEND( mailto => 'A Ivanov <a.ivanov@yourcompany.ru>'
                  , subject => 'Email with Logo in the text'
                  , message => 'I fly with <img src="cid:'|| v_id || '">'                  
                  , mailfrom => 'Notification <no-reply@yourcompany.ru>'
                  , mimetype => 'text/html'
                  );
END;
```

#### Example with checking number of available emails in a mailbox

```SQL
    BEGIN
       -- Set credentials
       MAIL_PKG.SET_MAILSERVER ('yourmailserver.com');
       MAIL_PKG.SET_AUTH ('a.ivanov','mypass');
       MAIL_PKG.MAIL_CONNECT;
       -- Now it possible to call Count method
       DBMS_OUTPUT.PUT_LINE('Total mails count:'||mail_pkg.mailbox.count);
       MAIL_PKG.MAIL_DISCONNECT;       
    END;     
```

#### Example to collect emails with attachements (Experimental)
```SQL
    BEGIN
       -- Enable debug if needed DBMS_OUTPUT
       -- MAIL_PKG.DEBUG := TRUE;
       -- MAIL_PKG.DEBUG_LEVEL := MAIL_PKG.DEBUG_ALL;
       -- Set credentials
       MAIL_PKG.SET_MAILSERVER ('yourmailserver.com');
       MAIL_PKG.SET_AUTH ('a.ivanov','mypass');
       -- Connect to the server
       MAIL_PKG.MAIL_CONNECT;
       -- Count available emails
       DBMS_OUTPUT.PUT_LINE('Total mails count:'||mail_pkg.mailbox.count);
       -- All headers of all emails can collect into array under mail_pkg.mailbox
       -- MAIL_PKG.GET_HEADERS;
       
       -- Example to collect last 10 emails
       FOR i IN 1..LEAST(10,mail_pkg.mailbox.count) LOOP
         -- Get info and mail header
         -- for this second parameter should be 0 - i.e. to not collect mail boby
         MAIL_PKG.GET_MAIL(i,0);
         -- Print email size and topic info
         DBMS_OUTPUT.PUT_LINE('MAIL:'||i || ' (' ||trunc(mail_pkg.mailbox(i).bytes/1024) || 'Kbytes) From:'||mail_pkg.mailbox(i).MailFrom
                              ||' Subject:'||mail_pkg.mailbox(i).Subject
                              );
             
         -- Bug: It's not possible to collect emails with attachement size more than 1 Мб     
         IF mail_pkg.mailbox(i).bytes>1000000 THEN
           -- So in that example we just delete that kind of emails
           MAIL_PKG.DELETE_MAIL(i);
         ELSE
         
         -- Collect full email with body
         MAIL_PKG.GET_MAIL(i);
         -- Print body and number of attachements
         DBMS_OUTPUT.PUT_LINE(substr(' Text:' ||mail_pkg.mailbox(i).message,1,255) );
         DBMS_OUTPUT.PUT_LINE(' Attachments:' ||mail_pkg.mailbox(i).attachments.count);

         -- Iterate attachements
           IF mail_pkg.mailbox(i).attachments.count>0 THEN
             FOR att IN 1..mail_pkg.mailbox(i).attachments.count LOOP
               -- Check attachements marked as attachement (not interested in inline dispositions)
               IF mail_pkg.mailbox(i).attachments(att).hdr.exists('Content-Disposition')
                 AND INSTR(mail_pkg.mailbox(i).attachments(att).hdr('Content-Disposition'),'attachment')>0
               THEN
                 -- Print file name and it's size
                 DBMS_OUTPUT.PUT_LINE(' filename: '
                    ||mail_pkg.extract_value(mail_pkg.mailbox(i).attachments(att).hdr('Content-Disposition'),'filename')
                    ||', about '||trunc(dbms_lob.getlength(mail_pkg.mailbox(i).attachments(att).content)/1024) ||'Kbytes'
                   );
                 -- File context avaiable as  CLOB
                 -- It possible to convert into BLOB and save into DB or on Disk
                 -- mail_pkg.mailbox(i).attachments(att).content
               END IF;
               -- Check if attachement is a text file
               IF mail_pkg.mailbox(i).attachments(att).hdr.exists('Content-Type') THEN
                 IF INSTR(mail_pkg.mailbox(i).attachments(att).hdr('Content-Type'),'text')>0 THEN
                   -- If true - print it
                   DBMS_OUTPUT.PUT_LINE(substr(' PreviewAttachmentText:' ||mail_pkg.mailbox(i).attachments(att).content,1,255) );
                 END IF;
               END IF;
             END LOOP;
           END IF;
         END IF;
       END LOOP;

       -- Must disconnect after work with server is finished
       -- In real code it is recommended to collect emails into mail_pgk.mailbox and disconnect
       -- And then continue to work with mail_pgk.mailbox array
       MAIL_PKG.MAIL_DISCONNECT;

    EXCEPTION WHEN OTHERS THEN
      -- Must termitate connection otherwise connection will leak
      MAIL_PKG.MAIL_DISCONNECT;
    END;
```
