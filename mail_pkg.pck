CREATE OR REPLACE PACKAGE MAIL_PKG IS
-- --------------------------------------------------------------------------
-- Name         : MAIL_PKG
-- Author       : Nekrasov Alexander
-- Description  : Mail package, send email with attachments
-- Url          : http://www.sql.ru/forum/actualthread.aspx?tid=729238
-- Ammedments   :
--   When         Who         What
--   ===========  ==========  =================================================
--   22-JAN-2010  Nekrasov A.  Initial Creation
--   11-OCT-2010  Nekrasov A.  Add Blob attachments
--   17-SEP-2012  Nekrasov A.  Add Receive Emails
-- --------------------------------------------------------------------------

/* EXAMPLE:

 1) Short text email
    BEGIN
      MAIL_PKG.SEND( 'a.ivanov@yourcomany.ru','Test subject', 'Some message!');
  END;

 2) Send mail with text message over 32kbytes formed with CLOB 
    DECLARE 
      v clob:='Some text message over 32kb'||chr(10)||chr(13);
      t varchar2(255):=' The quick brown fox jumps over the lazy dog. '
                     ||' The quick brown fox jumps over the lazy dog. '
                     ||' The quick brown fox jumps over the lazy dog. '||chr(10)||chr(13);
    BEGIN
      for x in 1..300 loop
        v:=v||to_char(x)||' '||t;
      end loop;
      MAIL_PKG.SEND( 'a.ivanov@yourcompany.ru','Test subject', v);
    END ;  

 3) Send mail with message over 32kbytes formed with BLOB
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
	
 4) Extension Email with attacments
    DECLARE
      vBlob BLOB;
    BEGIN
	 MAIL_PKG.SET_MAILSERVER ('localhost',25);
	 MAIL_PKG.SET_AUTH ('a.nekrasov','password');

	 -- Add attachment from file 
	 MAIL_PKG.ADD_ATTACHMENT( 'ODPDIR'
							 ,'girl3d.jpeg'
							 ,'image/jpeg'
							);

	 -- Add attachment from BLOB	
	 SELECT file_data INTO vBlob FROM FND_LOBS WHERE FILE_ID = 161005;						
	 MAIL_PKG.ADD_ATTACHMENT( vBlob
							 ,'ReportResult.htm'
							 ,'text/html'
							);							

	 MAIL_PKG.SEND( mailto => 'A. Ivanov <a.ivanov@yourcomany.ru>, O.Petrov <o.petrov@yourcompany.ru>'
	              , subject => 'Test subject'
				  , message => 'Some <b>bold</b> message!'
				  , mailfrom => 'Oracle Notify <no-reply@yourcompany.ru>'
                  , mimetype => 'text/html'
				  , priority => 1
	              );
	END;
    
 5) Receive emails example:
 
    BEGIN
       MAIL_PKG.DEBUG := TRUE;
       MAIL_PKG.SET_MAILSERVER ('yourmailserver.com');
       MAIL_PKG.SET_AUTH ('a.ivanov','mypass');
       MAIL_PKG.MAIL_CONNECT;
       DBMS_OUTPUT.PUT_LINE('Total mails count:'||mail_pkg.mailbox.count);
       --  MAIL_PKG.GET_HEADERS; -- Get headers for all mails
       
       FOR i IN 1..LEAST(10,mail_pkg.mailbox.count) LOOP -- GET FIRST 10 mails
         MAIL_PKG.GET_MAIL(i,0); -- GET MAIL HEADER
         DBMS_OUTPUT.PUT_LINE('MAIL:'||i || ' (' ||trunc(mail_pkg.mailbox(i).bytes/1024) || 'Kbytes) From:'||mail_pkg.mailbox(i).MailFrom
                              ||' Subject:'||mail_pkg.mailbox(i).Subject
                              );
             
         IF mail_pkg.mailbox(i).bytes>1000000 THEN
           -- Delete mails over 1Mb
           MAIL_PKG.DELETE_MAIL(i);
         ELSE
           MAIL_PKG.GET_MAIL(i);
           DBMS_OUTPUT.PUT_LINE(substr('    Text:' ||mail_pkg.mailbox(i).message,1,255) );         
           DBMS_OUTPUT.PUT_LINE('    Attachments:' ||mail_pkg.mailbox(i).attachments.count);

           IF mail_pkg.mailbox(i).attachments.count>0 THEN
             FOR att IN 1..mail_pkg.mailbox(i).attachments.count LOOP
               -- Real Attachments 
               IF mail_pkg.mailbox(i).attachments(att).hdr.exists('Content-Disposition') 
                 AND INSTR(mail_pkg.mailbox(i).attachments(att).hdr('Content-Disposition'),'attachment')>0               
               THEN
                 DBMS_OUTPUT.PUT_LINE('    filename: '
                    ||mail_pkg.extract_value(mail_pkg.mailbox(i).attachments(att).hdr('Content-Disposition'),'filename')
                    ||', about '||trunc(dbms_lob.getlength(mail_pkg.mailbox(i).attachments(att).content)/1024) ||'Kbytes'                 
                   );
                 -- You can convert this CLOB into BLOB ans save it into database or as file  
                 -- mail_pkg.mailbox(i).attachments(att).content                   
                                    
               END IF; 
               -- Preview includes and text-attachments 
               IF  mail_pkg.mailbox(i).attachments(att).hdr.exists('Content-Type') THEN
                 IF  INSTR(mail_pkg.mailbox(i).attachments(att).hdr('Content-Type'),'text')>0 THEN
                   DBMS_OUTPUT.PUT_LINE(substr('    PreviewAttachmentText:' ||mail_pkg.mailbox(i).attachments(att).content,1,255) );             
                 END IF;
               END IF;  
             END LOOP;
           END IF;                           
         END IF;     
       END LOOP;
   
       MAIL_PKG.MAIL_DISCONNECT;
    EXCEPTION WHEN OTHERS THEN
      -- ANYCASE YOU MUST CLOSE CONNECTION
      MAIL_PKG.MAIL_DISCONNECT;
    END;       
*/

 POP3 CONSTANT VARCHAR2(4):='POP3';
 SMTP CONSTANT VARCHAR2(4):='SMTP';
 IMAP CONSTANT VARCHAR2(4):='IMAP';

 DEBUG_ALL CONSTANT INT := 0;
 DEBUG_MESSAGES CONSTANT INT := 1;
 DEBUG_WARNINGS CONSTANT INT := 2;
 DEBUG_ERRORS CONSTANT INT := 3; 

 DEBUG BOOLEAN := FALSE;
 DEBUG_LEVEL NUMBER := DEBUG_WARNINGS;

 -- SET_MAILSERVER:
 --  Set up mail server for send emails. Default Localhost
 -- IN
 -- MAILSERVER is ip or url of mail server
 -- MAILPORT is port for mail server. Default 25
 PROCEDURE SET_MAILSERVER ( mailserver varchar2
                          , mailport number default 25
                          );

 -- SET_AUTH
 --  Set authorization on smtp server
 -- IN
 -- AUTH_USER is authorization user
 -- AUTH_PASS is password for AUTH_USER
 --
 -- Execute SET_AUTH(); -- for disable authorization
 PROCEDURE SET_AUTH (  auth_user varchar2 default null
                     , auth_pass varchar2 default null
                          );

 -- ENCODE:
 --  Encodes string to email compatible view
 -- IN
 -- STR is string to convert
 -- TP is type of convert:
 --    B - is base64 encoding
 FUNCTION ENCODE( str IN VARCHAR2
                , tp IN VARCHAR2 DEFAULT 'Q') RETURN VARCHAR2;

 -- PREPARE
 --  Prepare configs for email.
 PROCEDURE PREPARE;

 -- ADD_RCPT
 --  Add recipient to recipients list exploded by  ','
 -- STR is variable with recipients
 -- RCPTMAIL is recipient mail added to STR
 -- RCPTNAME is recipient name added to STR
 -- Example: str='user1@domain.ru' rcptmail='user2@domain.ru'
 --  after => str='user1@domain.ru, user2@domain.ru'
 PROCEDURE ADD_RCPT( str IN OUT VARCHAR2
                   , rcptmail IN VARCHAR2
				   , rcptname IN VARCHAR2 DEFAULT NULL);

 -- ADD_ATTACHMENT
 --  Add file-attachment to attachments list to email
 -- IN
 -- DIRNAME is logical link to access physical directories of server. See DBA_DIRECTORIES table
 -- FILENAME is name of file to attach
 -- MIMETYPE is mime-type for sended file
 -- NAME is name for attached file for email. Default eq FILENAME
 PROCEDURE ADD_ATTACHMENT ( dirname IN varchar2
                          , filename IN varchar2
						  , mimetype IN varchar2 DEFAULT 'text/plain'
                          , name IN varchar2 DEFAULT NULL
                           );
 -- ADD_ATTACHMENT
 --  Add blob-attachment to attachments list to email
 -- IN
 -- BLOBLOC - Blob locator for attached blob
 -- FILENAME is name of file to attach
 -- MIMETYPE is mime-type for sended file
 PROCEDURE ADD_ATTACHMENT ( blobloc IN blob
                          , filename IN varchar2
						  , mimetype IN varchar2 DEFAULT 'text/html'
                           );
						   
 -- SEND
 --  Send email with attachments to recipient
 -- IN
 -- MAILTO is name and email addresses of recipients ( ex. "user@domain.com"
 --       , "User Name <user@domain.com>", "User1 <user1@domain>, User2 <user2@domain>")
 -- SUBJECT is subject of email
 -- MESSAGE is message of email
 -- MAILFROM is name and email of sender. (ex. "no-reply@domain", "Notify system <no-reply@domain>")
 -- MIMETYPE is mime-type of message. Available values is 'text/plain' and 'text/html'
 -- PRIORITY is priority of mail (1 - High, 2 - Highest, 3 - Normal, 4 - Lowest, 5 - Low)
 PROCEDURE SEND ( mailto IN VARCHAR2
				, subject IN VARCHAR2
				, message IN CLOB
                , mailfrom IN VARCHAR2 DEFAULT NULL
				, mimetype IN VARCHAR2 DEFAULT 'text/plain'
				, priority IN NUMBER DEFAULT NULL
                );

 FUNCTION DECODE_CHARSET (str IN VARCHAR2, charset varchar2) RETURN VARCHAR2;
 
 FUNCTION MIME_DECODE(str IN VARCHAR2) RETURN VARCHAR2;

 FUNCTION extract_value(str IN VARCHAR2,entity IN VARCHAR2) RETURN VARCHAR2;

 TYPE T_HDR IS TABLE OF VARCHAR2(32717) INDEX BY VARCHAR2(2555);				
 
 TYPE T_ATTACHMENT IS RECORD ( boundary varchar2(255)
                          , ContentTransferEncoding varchar2(25)
                          , charset varchar2(25)
                          , hdr t_hdr
                          , content clob
                           );
 
 TYPE T_ATTACHMENTS IS TABLE OF T_ATTACHMENT;

 TYPE MESSAGE IS RECORD( hdr              t_hdr
                        ,MailFrom         varchar2(32717)
                        ,MailTo           varchar2(32717)
                        ,ReturnPath       varchar2(32717)
                        ,Subject          varchar2(32717)
                        ,MailDate         DATE
                        ,message          CLOB
                        ,bytes            number
                        ,ContentTransferEncoding varchar2(25)
                        ,charset          varchar2(25)
                        ,attachments         t_attachments := t_attachments()                                                                         
                       );			
					   
 TYPE MAILBOXT IS TABLE OF MESSAGE INDEX BY PLS_INTEGER;				
 MAILBOX MAILBOXT;			
 	
 FUNCTION PARSE_LINE (line varchar2, ContentTransferEncoding varchar2, charset varchar2 default null) RETURN varchar2; 
  
 PROCEDURE MAIL_CONNECT;
 
 PROCEDURE MAIL_DISCONNECT;
 			
 PROCEDURE GET_HEADERS;		

 PROCEDURE GET_MAIL(mail_id number,lines number default null);	
 
 PROCEDURE DELETE_MAIL(mail_id number);	
 
END MAIL_PKG;
/

CREATE OR REPLACE PACKAGE BODY MAIL_PKG
IS

 mailserver VARCHAR2(30):='localhost';
 mailport INTEGER:=25;
 auth_user VARCHAR2(50);
 auth_pass VARCHAR2(50);
 crlf         VARCHAR2(2)  := utl_tcp.CRLF; -- chr(13)||chr(10);

 c  utl_tcp.connection;  -- TCP/IP connection to the Web server (for pop3)

 type attach_row is record ( dirname varchar2(30)
                           , filename  varchar2(30)
                           , name  varchar2(30)
						   , mimetype varchar2(30)
						   , blobloc blob
						   , attachtype varchar2(30)
                           );
 type attach_list is table of attach_row;
 attachments attach_list;

 type rcpt_row is record ( rcptname varchar2(100)
                     , rcptmail varchar2(50)
					 );
 type rcpt_list is table of rcpt_row;

 PROCEDURE SET_MAILSERVER ( mailserver varchar2
                          , mailport number default 25
                          ) IS
 BEGIN
  MAIL_PKG.mailserver := mailserver;
  MAIL_PKG.mailport := mailport;
 END;

 PROCEDURE SET_AUTH (  auth_user varchar2 default null
                     , auth_pass varchar2 default null
                          ) IS
 BEGIN
   MAIL_PKG.auth_user := auth_user;
   MAIL_PKG.auth_pass := auth_pass;
 END;

 FUNCTION ENCODE(str IN VARCHAR2, tp IN VARCHAR2 DEFAULT 'Q') RETURN VARCHAR2 IS
 BEGIN
   -- ToDo: UTL_ENCODE.QUOTED_PRINTABLE | UTL_ENCODE.BASE64
   IF tp='B' THEN
     RETURN '=?utf-8?b?'|| UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw (CONVERT (SUBSTR(str,1,24), 'UTF8'))))|| '?='
	     || CASE WHEN SUBSTR(str,25) IS NOT NULL THEN crlf || ' '|| ENCODE(SUBSTR(str,25),tp) END;
   ELSIF tp='Q' THEN
     RETURN '=?utf-8?q?' || UTL_RAW.cast_to_varchar2(utl_encode.QUOTED_PRINTABLE_ENCODE(utl_raw.cast_to_raw(CONVERT (SUBSTR(str,1,8), 'UTF8') ))) || '?='
	     || CASE WHEN SUBSTR(str,9) IS NOT NULL THEN crlf || ' '|| ENCODE(SUBSTR(str,9),tp) END;
   ELSE
     RETURN str;
   END IF;
 END;
 
 FUNCTION DECODE_CHARSET (str IN VARCHAR2, charset varchar2) RETURN VARCHAR2 IS
 BEGIN
   return CONVERT(str,SUBSTR(USERENV ('language'),INSTR(USERENV ('language'),'.')+1)
                   , CASE lower(charset) WHEN 'koi8-r' THEN 'CL8KOI8R'
                                  WHEN 'utf-8' THEN 'UTF8'
                     ELSE SUBSTR(USERENV ('language'),INSTR(USERENV ('language'),'.')+1)
                     END
                   );
 END;
 
 FUNCTION MIME_DECODE(str IN VARCHAR2) RETURN VARCHAR2 IS
   strout VARCHAR2(32717);
  buff varchar2(32717);
 text varchar2(32717);
 encode_method varchar2(1);
 charset varchar2(25);
BEGIN
  strout := str;
  LOOP
    IF instr(strout,'=?')>0 and instr(strout,'?=')>0 and instr(strout,'?=') > instr(strout,'=?') then
      buff := substr(substr(strout,instr(strout,'=?')),1,1+instr(substr(strout,instr(strout,'=?')),'?=',instr(substr(strout,instr(strout,'=?')),'?',1,3)+1 ));      
      charset := lower(substr(buff,3, instr(substr(buff,3),'?')-1));
      encode_method := substr(buff, 4+length(charset),1);
      text := substr(buff,instr(buff,'?',1,3)+1, instr(buff,'?',1,4)-instr(buff,'?',1,3)-1);
      IF  encode_method = 'B' THEN
       text := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(text)));
      ELSE
       text := UTL_RAW.cast_to_varchar2(utl_encode.quoted_printable_decode(UTL_RAW.cast_to_raw(replace(text,'_',' '))));   
      END IF;
      text := DECODE_CHARSET(text,charset); 
      strout:=REPLACE(strout,buff,text);                   
    ELSE
       EXIT;                
    END IF;
  END LOOP;      
    RETURN strout;
 END;

 PROCEDURE extract_value(val IN OUT varchar2, str IN VARCHAR2,entity IN VARCHAR2) 
 IS
  buff varchar2(255);
  returnval varchar2(255);
 BEGIN
    if instr(str,entity)=0 
    then
     return;
    else
     val := replace(substr(str,length(entity)+1+instr(str,entity||'='), instr(substr(str||';',length(entity)+1+instr(str,entity||'=')),';')-1),'"','');
    end if;
 END;

 FUNCTION extract_value(str IN VARCHAR2,entity IN VARCHAR2) RETURN VARCHAR2 IS
  p_val varchar2(32717):='';
 BEGIN
   mail_pkg.extract_value(p_val ,str ,entity );
   return p_val; 
 END;


 PROCEDURE PREPARE
 IS
 BEGIN
   MAIL_PKG.attachments:=MAIL_PKG.attach_list();
 END;

 PROCEDURE ADD_RCPT( str IN OUT VARCHAR2
                   , rcptmail IN VARCHAR2
				   , rcptname IN VARCHAR2 DEFAULT NULL) IS
  rcpt varchar2(255);
 BEGIN
  rcpt:=CASE WHEN rcptname is null THEN
          ' <'|| rcptmail ||'>' --rcptmail
		ELSE
		  trim(replace(replace(rcptname,',',' '),';',' '))||' <'|| rcptmail ||'>'
		END;
  IF trim(str) is NULL THEN
     str :=  trim(rcpt);
  ELSE
     str := str||', '||trim(rcpt);
  END IF;
 END;

 PROCEDURE ADD_ATTACHMENT ( dirname IN varchar2
                          , filename IN varchar2
						  , mimetype IN varchar2 DEFAULT 'text/plain'
                          , name IN varchar2 DEFAULT NULL
                           )
 IS
  v_fl BFILE :=BFILENAME(dirname,filename);
 BEGIN
   IF DBMS_LOB.FILEEXISTS (v_fl)=1 THEN
      MAIL_PKG.attachments.extend;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).dirname:=dirname;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).filename:=filename;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).name:=nvl(name,filename);
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).mimetype:=mimetype;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).attachtype:='FILE';	  
   ELSE
      RAISE_APPLICATION_ERROR(-20001, 'File is not exists');
   END IF;
 END;
 
 PROCEDURE ADD_ATTACHMENT ( blobloc IN blob
                          , filename IN varchar2
						  , mimetype IN varchar2 DEFAULT 'text/html'
                           )
 IS 
 BEGIN
      MAIL_PKG.attachments.extend;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).name:=filename;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).mimetype:=mimetype;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).blobloc:=blobloc;	  
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).attachtype:='BLOB';	  
 END; 						   
 

 FUNCTION CREATE_RCPT_LIST(mailto IN VARCHAR2) RETURN MAIL_PKG.rcpt_list IS
  v_mailto VARCHAR2(4096) := replace(mailto,';',',')||',';
  pntr INTEGER;
  buf VARCHAR2(255);
  rcptmail VARCHAR2(255);
  rcptlist MAIL_PKG.rcpt_list:=MAIL_PKG.rcpt_list();
 BEGIN
  FOR maxrcptnts IN 1..50
  LOOP
     pntr:=INSTR(v_mailto,','); buf := substr(v_mailto,1,pntr-1);
     IF pntr>0 THEN
	   IF INSTR(buf,'<')>0 AND INSTR(buf,'>')>0 THEN
	     rcptmail:= SUBSTR(buf,INSTR(buf,'<')+1,INSTR(SUBSTR(buf,INSTR(buf,'<')+1),'>')-1);
		 IF rcptmail IS NOT NULL THEN
	        rcptlist.extend;
		    rcptlist(rcptlist.count).rcptmail := TRIM(rcptmail);
		    rcptlist(rcptlist.count).rcptname := TRIM(SUBSTR(buf,1,INSTR(buf,'<')-1));
	     END IF;
       ELSE
	     rcptmail := TRIM(buf);
		 IF rcptmail IS NOT NULL THEN
           rcptlist.extend;
		   rcptlist(rcptlist.count).rcptmail:= TRIM(rcptmail);
		 END IF;
	   END IF;
	 ELSE
	   EXIT;
	 END IF;
	 v_mailto := substr(v_mailto,pntr+1);
   END LOOP;
   RETURN rcptlist;
 END;

 PROCEDURE SEND ( mailto IN VARCHAR2
				, subject IN VARCHAR2
				, message IN CLOB
                , mailfrom IN VARCHAR2 DEFAULT NULL
				, mimetype IN VARCHAR2 DEFAULT 'text/plain'
				, priority IN NUMBER DEFAULT NULL
                )
 IS
   v_Mail_Conn  utl_smtp.Connection;
   boundary VARCHAR2(50) := '-----7D81B75CCC90DFRW4F7A1CBD';
   vFile BFILE;
   vRAW RAW(32767);
   amt CONSTANT BINARY_INTEGER := 10368; -- 48bytes binary convert to 128bytes of base64. (32767/2 max for raw convert)
   v_amt BINARY_INTEGER;
   ps BINARY_INTEGER := 1;
   message_part varchar2(32767);
   v_mime VARCHAR2(30);
   reply UTL_SMTP.REPLY;
   replies UTL_SMTP.REPLIES;
   rcptlist MAIL_PKG.rcpt_list;
   sndr MAIL_PKG.rcpt_row;
 BEGIN
    rcptlist:=create_rcpt_list(mailto);
	IF rcptlist.count=0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Recipients requered');
	END IF;
    IF mimetype<>'text/html' and mimetype<>'text/plain' THEN
      RAISE_APPLICATION_ERROR(-20001, 'MimeType must be "text/html" or "text/plain"');
    ELSE
      v_mime:=mimetype;
    END IF;
    v_Mail_Conn := utl_smtp.Open_Connection(MAIL_PKG.mailserver, MAIL_PKG.mailport);
    replies:=utl_smtp.Ehlo(v_Mail_Conn,MAIL_PKG.mailserver);
	if create_rcpt_list(mailfrom).count>0 then
	  sndr := create_rcpt_list(mailfrom)(1);
	else
	  sndr := create_rcpt_list( 'mail@' || UTL_INADDR.GET_HOST_NAME )(1); -- host from oracle-server
	  -- sndr := create_rcpt_list( 'mail@' || substr(replies(1).text,1,instr(replies(1).text,' ')-1))(1); -- Addr from ehlo answer
    end if;

    if mail_pkg.auth_user is not null then
       for x IN 1 .. replies.count loop
 	     IF INSTR(replies(x).text,'AUTH')>0 then -- If server supply authorization
            utl_smtp.command(v_Mail_Conn, 'AUTH LOGIN');
            utl_smtp.command(v_Mail_Conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(auth_user))));
            utl_smtp.command(v_Mail_Conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(auth_pass))));
			exit;
		 END IF;
	   end loop;
    end if;

    utl_smtp.Mail(v_Mail_Conn, sndr.rcptmail);
    FOR rcpts IN 1 .. rcptlist.count
	LOOP
	  utl_smtp.Rcpt(v_Mail_Conn, rcptlist(rcpts).rcptmail);
	END LOOP;

    utl_smtp.open_data(v_Mail_Conn); -- open data sheet
    utl_smtp.write_data(v_Mail_Conn, 'Date: ' || TO_CHAR(SYSTIMESTAMP,'Dy, DD Mon YYYY HH24:MI:SS TZHTZM','NLS_DATE_LANGUAGE = ''american''') || crlf);
    utl_smtp.write_data(v_Mail_Conn, 'From: ');
	if sndr.rcptname is not null then
        utl_smtp.write_data(v_Mail_Conn, MAIL_PKG.ENCODE(sndr.rcptname) ||' <'|| sndr.rcptmail || '>');
	else
        utl_smtp.write_data(v_Mail_Conn, sndr.rcptmail);
	end if;
    utl_smtp.write_data(v_Mail_Conn, crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Subject: '|| MAIL_PKG.ENCODE(subject) || crlf );
    utl_smtp.write_data(v_Mail_Conn, 'To: ');
    FOR rcpts IN 1 .. rcptlist.count
	LOOP
	  if rcpts>1 then
       utl_smtp.write_data(v_Mail_Conn, ',');
	  end if;
	  if rcptlist(rcpts).rcptname is not null then
        utl_smtp.write_data(v_Mail_Conn, MAIL_PKG.ENCODE(rcptlist(rcpts).rcptname) ||' <'|| rcptlist(rcpts).rcptmail || '>');
	  else
        utl_smtp.write_data(v_Mail_Conn, rcptlist(rcpts).rcptmail);
	  end if;
	END LOOP;
    utl_smtp.write_data(v_Mail_Conn, crlf );

	IF priority IS NOT NULL and priority BETWEEN 1 AND 5 THEN
      utl_smtp.write_data(v_Mail_Conn, 'X-Priority: ' || priority || crlf );
	END IF;
    utl_smtp.write_data(v_Mail_Conn, 'MIME-version: 1.0' || crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Content-Type: multipart/mixed;'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, ' boundary="'||boundary||'"'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, crlf );
 
    --Message
	IF message IS NOT NULL THEN	
    utl_smtp.write_data(v_Mail_Conn, '--'|| boundary || crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Content-Type: '||v_mime||'; charset="utf-8"'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Content-Transfer-Encoding: 8bit'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, crlf );
    -- utl_smtp.write_raw_data(v_Mail_Conn, utl_raw.cast_to_raw(CONVERT(message,'UTF8')));
    ps:=1; v_amt:=amt;
    LOOP
      BEGIN
        dbms_lob.read(message, v_amt, ps, message_part);
        ps := ps + v_amt;
        utl_smtp.write_raw_data(v_Mail_Conn, utl_raw.cast_to_raw(CONVERT(message_part,'UTF8')));                 
      EXCEPTION
        WHEN no_data_found THEN
             EXIT;
      END;            
    END LOOP; 
    utl_smtp.write_data(v_Mail_Conn, crlf );
    utl_smtp.write_data(v_Mail_Conn, crlf );
    END IF;
	
	--Attachments
	IF MAIL_PKG.attachments.count>0 THEN
	  FOR x IN 1 .. MAIL_PKG.attachments.count LOOP
          utl_smtp.write_data(v_Mail_Conn, '--'|| boundary || crlf );
		  -- HOTFIX
		  IF message IS NOT NULL OR x!=1 THEN
            utl_smtp.write_data(v_Mail_Conn, 'Content-Type: '||MAIL_PKG.attachments(x).mimetype||';'|| crlf );
            utl_smtp.write_data(v_Mail_Conn, ' name="');
	        utl_smtp.write_raw_data(v_Mail_Conn,utl_raw.cast_to_raw(MAIL_PKG.attachments(x).name));
            utl_smtp.write_data(v_Mail_Conn, '"' || crlf);
            utl_smtp.write_data(v_Mail_Conn, 'Content-Transfer-Encoding: base64'|| crlf );
            utl_smtp.write_data(v_Mail_Conn, 'Content-Disposition: attachment;'|| crlf );
            utl_smtp.write_data(v_Mail_Conn, ' filename="' || MAIL_PKG.ENCODE(MAIL_PKG.attachments(x).name) || '"' || crlf);
		  ELSE
           utl_smtp.write_data(v_Mail_Conn, 'Content-Type: '||MAIL_PKG.attachments(x).mimetype||'; charset="utf-8"'|| crlf );
           utl_smtp.write_data(v_Mail_Conn, 'Content-Transfer-Encoding: base64'|| crlf );
          END IF;			
          utl_smtp.write_data(v_Mail_Conn, crlf );
		  IF MAIL_PKG.attachments(x).attachtype = 'FILE' THEN 
             vFile := BFILENAME(MAIL_PKG.attachments(x).dirname,MAIL_PKG.attachments(x).filename);
		     dbms_lob.fileopen(vFile, dbms_lob.file_readonly);
             ps:=1; v_amt:=amt;
		     LOOP
		       BEGIN
		         dbms_lob.read (vFile, v_amt, ps, vRAW);
			     ps := ps + v_amt;
                 utl_smtp.write_raw_data(v_Mail_Conn, UTL_ENCODE.base64_encode(vRAW));
		       EXCEPTION
                 WHEN no_data_found THEN
			       EXIT;
			   END;			
		     END LOOP;
		     dbms_lob.fileclose(vFile);
		  ELSIF MAIL_PKG.attachments(x).attachtype = 'BLOB' THEN
		  	 dbms_lob.open(MAIL_PKG.attachments(x).blobloc, dbms_lob.file_readonly);
             ps:=1; v_amt:=amt;
		     LOOP
		       BEGIN
		         dbms_lob.read (MAIL_PKG.attachments(x).blobloc, v_amt, ps, vRAW);
			     ps := ps + v_amt;
                 utl_smtp.write_raw_data(v_Mail_Conn, UTL_ENCODE.base64_encode(vRAW));
		       EXCEPTION
                 WHEN no_data_found THEN
			       EXIT;
			   END;			
		     END LOOP;
		     dbms_lob.close(MAIL_PKG.attachments(x).blobloc);					  	 
		  END IF;		 		  

          utl_smtp.write_data(v_Mail_Conn, crlf );
          utl_smtp.write_data(v_Mail_Conn, crlf );
	  END LOOP;
	END IF;

    -- Final Boundary
    utl_smtp.write_data(v_Mail_Conn, '--' || boundary || '--');

    utl_smtp.close_data(v_Mail_Conn);
    utl_smtp.quit(v_Mail_Conn);

	-- Clear attachments
    MAIL_PKG.attachments:=MAIL_PKG.attach_list();

 EXCEPTION
    WHEN OTHERS THEN
       BEGIN
         MAIL_PKG.attachments:=MAIL_PKG.attach_list();
		 utl_smtp.rset(v_Mail_Conn);
	     utl_smtp.quit(v_Mail_Conn);
	   EXCEPTION WHEN OTHERS THEN NULL;
	   END;
	RAISE;
 END;

 PROCEDURE PDEBUG(mess IN varchar2, plevel IN NUMBER DEFAULT 0) IS
 BEGIN
   IF MAIL_PKG.DEBUG AND plevel>=MAIL_PKG.DEBUG_LEVEL THEN
     dbms_output.put_line(substr(mess,1,255));
   END IF;
 END;

 PROCEDURE CMD(c in out utl_tcp.connection, command in varchar2,status out varchar2, answer out varchar2) is
   ret_val pls_integer; 
--   pc 
   answr varchar2(32767); 
 begin
   ret_val := utl_tcp.write_line(c,command);
   answr := utl_tcp.get_line(c, TRUE);
   status := trim(substr(answr,1,instr(answr,' ')));
   answer := substr(answr,instr(answr,' ')+1);
   if mail_pkg.debug then
    PDEBUG('DEBUG:'||status||' '||answer,mail_pkg.debug_messages);
   end if;
   if status = '-ERR' then
     raise_application_error (-20000,answr);
   end if;
 end;
 
 FUNCTION PARSE_LINE (line varchar2, ContentTransferEncoding varchar2, charset varchar2 default null) RETURN varchar2 IS
  decoding_line varchar2(255);
 BEGIN
   decoding_line := line;
   IF decoding_line is null then return null; END IF;
   IF ContentTransferEncoding = 'base64' then
      decoding_line := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(decoding_line)));
   ELSIF ContentTransferEncoding = 'quoted-printable' then
      decoding_line := UTL_RAW.cast_to_varchar2(UTL_ENCODE.quoted_printable_decode(UTL_RAW.cast_to_raw(decoding_line)));   
   END IF;   
   decoding_line := DECODE_CHARSET(decoding_line,charset);
   
   RETURN decoding_line;
 EXCEPTION WHEN OTHERS THEN
   PDEBUG('ERR: PARSE:' || ContentTransferEncoding || ' ' || charset || ',' || line || ' > '||decoding_line, mail_pkg.debug_errors);
   RETURN NULL;   
 END;
 
 
 PROCEDURE MAIL_CONNECT IS
  p_ip varchar2(25);
  answer varchar2(32767);
  status varchar2(25);
  cnt number;
  bytes number;         
 BEGIN
  p_ip := UTL_INADDR.GET_HOST_ADDRESS(mailserver);
  c := utl_tcp.open_connection(remote_host => p_ip,
                               remote_port =>  110,
                               charset     => 'US7ASCII',
                               tx_timeout => 10);  -- open connection
  answer := utl_tcp.get_line(c, TRUE); 
  PDEBUG(answer,mail_pkg.debug_messages);  -- read result
  CMD(c,'USER '||MAIL_PKG.auth_user,status,answer);  
  CMD(c,'PASS '||MAIL_PKG.auth_pass,status,answer);
 BEGIN
  CMD(c,'STAT',status,answer);
  cnt := to_number(trim(substr(answer,1,instr(answer,' '))));
  bytes := to_number(trim(substr(answer,instr(answer,' ')))); 
  -- INIT ARRAY
  MAILBOX.DELETE;
  FOR mail_id IN 1 .. cnt  
  LOOP
       MAILBOX(mail_id).bytes := 0;        
  END LOOP;
 END;
    
 END;
 
 PROCEDURE MAIL_DISCONNECT IS
  answer varchar2(32767); 
  status varchar2(25); 
 BEGIN
   CMD(c,'QUIT',status,answer);  
   utl_tcp.close_connection(c);
 EXCEPTION WHEN OTHERS THEN
  BEGIN   
    utl_tcp.close_connection(c);
  EXCEPTION WHEN OTHERS THEN NULL;
  END;    
  RAISE;
 END;

 PROCEDURE GET_HEADERS IS 
  answer varchar2(32767);
  status varchar2(25);  
  cnt number;
  bytes number;     
 BEGIN
  CMD(c,'STAT',status,answer);
  cnt := to_number(trim(substr(answer,1,instr(answer,' '))));
  bytes := to_number(trim(substr(answer,instr(answer,' ')))); 
  -- GET MESSAGE SUBJECTS
  FOR mail_id IN 1 .. cnt -- cnt --1 ..  cnt 
  LOOP
       GET_MAIL(mail_id,0);   -- ,0 !!!!!        
  END LOOP;
 END;

 
 PROCEDURE GET_MAIL(mail_id number,lines number default null) IS
  answer varchar2(32767);
  cnt number;
  bytes number;
  status varchar2(25);
  message_body clob;
  hdr_flag boolean;
  hdr_entity varchar2(255);
  hdr_entity_value varchar2(32717);  
  boundary varchar2(128);
  part_header_flag boolean:=false;
  any_boundary_found boolean:=false;
  any_boundary_found_close boolean:=false;
 BEGIN     
 
       CMD(c,'LIST '||mail_id,status,answer); -- get message size
       MAILBOX(mail_id).bytes:=to_number(trim(substr(answer,instr(answer,' '))));

       IF  MAILBOX(mail_id).bytes >= 1048576 THEN             
           PDEBUG('BUG: Message '|| mail_id ||' over 1Mb, ' ||  MAILBOX(mail_id).bytes || ' bytes' ,mail_pkg.debug_errors);
       END IF;
       
       CMD(c,CASE WHEN lines is NULL THEN 'RETR '||mail_id ELSE 'TOP '||mail_id||' 10' END,status,answer); -- read message headers
       BEGIN
         hdr_entity:='';hdr_entity_value:=''; 
         hdr_flag := true;
         if lines<>0 or lines is null then
            MAILBOX(mail_id).message:='';
            MAILBOX(mail_id).attachments := t_attachments();            
         end if;
         dbms_lob.createtemporary(lob_loc => MAILBOX(mail_id).message, cache => true, dur => dbms_lob.call);                                  
         LOOP
             answer :=utl_tcp.get_line(c, TRUE);  -- read result
             EXIT WHEN answer = '.';             
             IF answer IS NULL THEN hdr_flag := false; END IF;
             IF hdr_flag THEN
                 IF ascii(substr(answer,0,1)) NOT IN (9,32) THEN
                   hdr_entity := substr(answer,1,instr(answer,':')-1);
                   MAILBOX(mail_id).HDR(hdr_entity):='';                                    
                   hdr_entity_value := substr(answer,instr(answer,':')+2);
                 ELSE 
                   hdr_entity_value := answer;  
                 END IF;

                 PDEBUG('HDR:'|| answer);              
                 MAILBOX(mail_id).HDR(hdr_entity):= MAILBOX(mail_id).HDR(hdr_entity)
                                                 || MIME_DECODE(hdr_entity_value);  
                 IF hdr_entity = 'Content-Type' THEN
                   if instr(answer,'boundary="')>0 then
                      extract_value(boundary,answer,'boundary');                   
                   end if;                 
                 END IF;                                                                                                              
             ELSE   
                 any_boundary_found := false;
                 any_boundary_found_close := false;                 
                 IF MAILBOX(mail_id).attachments.count>0 THEN
                 FOR incls IN MAILBOX(mail_id).attachments.first .. MAILBOX(mail_id).attachments.last
                 LOOP 
                   if answer = '--' || MAILBOX(mail_id).attachments(incls).boundary then
                     any_boundary_found := true;
                   end if;
                   if answer = '--' || MAILBOX(mail_id).attachments(incls).boundary || '--' then
                     any_boundary_found_close := true;
                   end if;                   
                 END LOOP;
                 END IF;
                 
                 if boundary is not null and 
                    ( answer = '--' || boundary 
                      or
                      any_boundary_found
                    )
                     then
                    part_header_flag:=true;
                    MAILBOX(mail_id).attachments.extend();
                    dbms_lob.createtemporary(lob_loc => MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).content, cache => true, dur => dbms_lob.call);  
                 elsif boundary is not null and 
                   (  answer = '--' || boundary || '--'
                     or 
                     any_boundary_found_close
                   )
                     then
                       null;                   
                 elsif part_header_flag and answer is null then
                    part_header_flag:=false;
                 else
                    IF part_header_flag THEN
                       IF ascii(substr(answer,0,1)) NOT IN (9,32) THEN
                          hdr_entity := substr(answer,1,instr(answer,':')-1);
                          MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).HDR(hdr_entity):='';                                    
                          hdr_entity_value := substr(answer,instr(answer,':')+2);
                       ELSE 
                          hdr_entity_value := answer;  
                       END IF;
                       MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).HDR(hdr_entity):= 
                              MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).HDR(hdr_entity)
                           || MIME_DECODE(hdr_entity_value);
                       
                       IF hdr_entity = 'Content-Type' THEN
                          extract_value(MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).boundary,answer,'boundary');                       
                          extract_value(MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).charset,answer,'charset');
--                            PDEBUG(MAILBOX(mail_id).includes(MAILBOX(mail_id).includes.last).charset,mail_pkg.debug_messages);                                           
                       ELSIF hdr_entity = 'Content-Transfer-Encoding' THEN
                            MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).ContentTransferEncoding := hdr_entity_value;                         
                       END IF;                                                                                                              
                                                                             
                    ELSE 
                    
                       -- BUG: BIG messages is very slow and prc can get "[SYS/PERM] Fatal error: Lost connection to input stream"
                       IF MAILBOX(mail_id).bytes < 1048576 THEN 
                         IF MAILBOX(mail_id).attachments.count>0 THEN
                            IF length(answer)>0 THEN
                              DBMS_LOB.APPEND ( MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).content 
                              , PARSE_LINE( answer
                                           ,MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).ContentTransferEncoding
                                           ,MAILBOX(mail_id).attachments(MAILBOX(mail_id).attachments.last).charset)  
                              );
                            END IF;                         
                         ELSE 
                            IF length(answer)>0 THEN
                              DBMS_LOB.APPEND ( MAILBOX(mail_id).message  
                              , --PARSE_LINE( 
                                            answer
                                  --         ,ContentTransferEncoding
                                    --       ,charset)                                
                              );
                            END IF;                         
                         END IF;
                       END IF;
                                  
                    END IF;                  
                    PDEBUG(CASE part_header_flag WHEN TRUE THEN 'H' ELSE 'B' END || '-BODY:'||answer);                                   
                 end if;   
             END IF;
                        
         END LOOP;
       EXCEPTION
         WHEN OTHERS THEN 
         PDEBUG('ERR: GET MESSAGE ' ||mail_id || ' ERROR ',mail_pkg.debug_errors);         
         RAISE;
       END;
       IF MAILBOX(mail_id).HDR.EXISTS('From') THEN
          MAILBOX(mail_id).MailFrom := MAILBOX(mail_id).HDR('From');
       END IF;   
       IF MAILBOX(mail_id).HDR.EXISTS('MailTo') THEN
          MAILBOX(mail_id).MailTo := MAILBOX(mail_id).HDR('To');
       END IF;   
       IF MAILBOX(mail_id).HDR.EXISTS('Return-Path') THEN
          MAILBOX(mail_id).ReturnPath := MAILBOX(mail_id).HDR('Return-Path');
       END IF;
       IF MAILBOX(mail_id).HDR.EXISTS('Subject') THEN
          MAILBOX(mail_id).Subject := MAILBOX(mail_id).HDR('Subject');
       END IF;   
       IF MAILBOX(mail_id).HDR.EXISTS('Date') THEN
          BEGIN
            MAILBOX(mail_id).MailDate := TO_TIMESTAMP_TZ(MAILBOX(mail_id).HDR('Date'),'Dy, DD Mon YYYY HH24:MI:SS TZHTZM','NLS_DATE_LANGUAGE = ''american''');
          EXCEPTION WHEN OTHERS THEN NULL; END;   
       END IF;     
 END;
 
 PROCEDURE DELETE_MAIL(mail_id number) IS
  answer varchar2(32767);
  status varchar2(25);  
 BEGIN
   CMD(c,'DELE '||mail_id,status,answer); 
 END;  
    
BEGIN
  MAIL_PKG.attachments:=MAIL_PKG.attach_list();
END;
/
