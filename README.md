oracle-scripts
==============

Oracle PL/SQL package extensions

## Примеры работы с пакетом MAIL_PKG

#### Быстрая отправка текстового сообщения
```SQL
  BEGIN
      MAIL_PKG.SEND( 'a.ivanov@yourcomany.ru','Test subject', 'Some message!');
  END;
```  
#### Отправка сообщения размером более 32 килобайт
```SQL
    DECLARE
      v clob:='Some text message over 32kb'||chr(10)||chr(13);
      t varchar2(255):=' The quick brown fox jumps over the lazy dog. '
                     ||' The quick brown fox jumps over the lazy dog. '
                     ||' The quick brown fox jumps over the lazy dog. '||chr(10)||chr(13);
    BEGIN
      -- Генерируем сообщение размером более 32 тыс символов
      for x in 1..300 loop
        v:=v||to_char(x)||' '||t;
      end loop;
      MAIL_PKG.SEND( 'a.ivanov@yourcompany.ru','Test subject', v);
    END ;
```
#### Отправка сообщения с файлом BLOB, выбранным из Базы данных
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
#### Расширенный пример отправки сообщения с несколькими вложениями(FILE,CLOB,BLOB)
```SQL
    DECLARE
      vBlob BLOB;
      vClob CLOB;
    BEGIN
     -- Устанавливаем почтовый сервер для отправки почты, отличный от localhost:25
     MAIL_PKG.SET_MAILSERVER ('localhost',25);
     -- Устанавливаем данные для авторизации на почтовом сервере
     MAIL_PKG.SET_AUTH ('a.nekrasov','password');

     -- Добавляем изображение, находящееся в рабочей папке сервера
     -- Список алиасов директорий можно узнать запросом SELECT * FROM DBA_DIRECTORIES
     MAIL_PKG.ADD_ATTACHMENT( 'MY_DIR_ALIAS' -- Алиас директории
                             ,'logo.jpeg'    -- Имя файла в директории (такое же будет во вложении)
                             ,'image/jpeg'   -- mime тип данных вложения
                            );

     -- Добавляем BLOB, выбранный из базы данных
     SELECT file_data INTO vBlob FROM FND_LOBS WHERE FILE_ID = 161005;
     MAIL_PKG.ADD_ATTACHMENT( vBlob
                             ,'ReportResult.htm'  -- Имя файла, которое будет во вложении
                             ,'text/html'         -- mime тип данных вложения
                            );

     -- Добавляем предварительно подготовленный CLOB
     vClob := '<HTML><TITLE>Clob Attachment Example</TITLE><BODY><b>This</b> is clob attachment example</BODY></HTML>';
     MAIL_PKG.ADD_ATTACHMENT( vClob
                             ,'ClobResult.htm'    -- Имя файла, которое будет во вложении
                             ,'text/html'         -- mime тип данных вложения
                            );
     -- Отправляем 
     -- mailto - список адресов, на которые мы отправляем почту, могут быть в любом допустимом формате
     -- subject - тема письма
     -- message - Основное сообщение письма (CLOB)
     -- mailfrom - Емайл отправителя
     -- mimetype - Тип сообщения письма, допустимы text/html и text/plain (по умолчанию)
     -- priority - Приоритет сообщения от 1 до 5, 1 - самый высокий, 3 - по умолчанию
     MAIL_PKG.SEND( mailto => 'A. Ivanov <a.ivanov@yourcomany.ru>, O.Petrov <o.petrov@yourcompany.ru>'
                  , subject => 'Test subject'
                  , message => 'Some <b>bold</b> message!'
                  , mailfrom => 'Oracle Notify <no-reply@yourcompany.ru>'
                  , mimetype => 'text/html'
                  , priority => 1
                  );
    END;
```    
#### Пример с вложением изображения, отображаемого в теле сообщения письма
```SQL
DECLARE
 -- Преобразуем для примера логотип в CLOB
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
 v_id varchar2(25); -- Идентификатор логотипа в письме
BEGIN
     -- Добавляем логотип к письму
     -- Указываем disposition = MAIL_PKG.DISPOSITION_INLINE
     -- чтобы логотип не отображался во вложениях письма
     MAIL_PKG.ADD_ATTACHMENT( vClob -- дата
                             ,'logo.gif' -- имя файла в письме
                             ,'image/gif' -- mime тип
                             , disposition => MAIL_PKG.DISPOSITION_INLINE
                            );
     -- получаем идентификатор логотипа из вложений                            
     v_id := MAIL_PKG.LAST_ATTACHMENT_ID;

     -- Отправляем письмо, указав mimetype = text/html
     -- Конструкцией <img src="cid:'|| v_id || '">
     -- ссылаемся на аттач изображения
     MAIL_PKG.SEND( mailto => 'A Ivanov <a.ivanov@yourcompany.ru>'
                  , subject => 'Письмо с логотипом'
                  , message => 'Я летаю авиакомпанией  <img src="cid:'|| v_id || '">'                  
                  , mailfrom => 'Уведомление <no-reply@yourcompany.ru>'
                  , mimetype => 'text/html'
                  );
END;
```
#### Пример получения письма с вложениями    
```SQL
    BEGIN
       -- Если у Вас возникают проблемы, можно включить режим отладки в DBMS_OUTPUT
       -- MAIL_PKG.DEBUG := TRUE;
       -- Задаем данные для авторизации на сервере
       MAIL_PKG.SET_MAILSERVER ('yourmailserver.com');
       MAIL_PKG.SET_AUTH ('a.ivanov','mypass');
       -- Устанавливаем соединение с сервером
       MAIL_PKG.MAIL_CONNECT;
       -- Если соединение прошло успешно, то сразу доступна информация о количестве писем
       DBMS_OUTPUT.PUT_LINE('Total mails count:'||mail_pkg.mailbox.count);
       -- Можно получить заголовки для всех писем
       -- они будут доступны в массиве mail_pkg.mailbox
       -- MAIL_PKG.GET_HEADERS;
       
       -- В примере получим последние 10 писем
       FOR i IN 1..LEAST(10,mail_pkg.mailbox.count) LOOP
         -- Получаем информацию о письме и заголовок письма
         -- Для этого вторым параметром указываем 0 - т.е. текст самого письма запрашивать не будем
         MAIL_PKG.GET_MAIL(i,0);
         -- Выводим информацию о размере письма, отправителе и теме письма
         DBMS_OUTPUT.PUT_LINE('MAIL:'||i || ' (' ||trunc(mail_pkg.mailbox(i).bytes/1024) || 'Kbytes) From:'||mail_pkg.mailbox(i).MailFrom
                              ||' Subject:'||mail_pkg.mailbox(i).Subject
                              );
             
         -- Bug: На данный момент пакет не справляется с обработкой писем размером более 1 Мб     
         IF mail_pkg.mailbox(i).bytes>1000000 THEN
           -- Поэтому в примере мы просто удалим все письма из этих 10-ти, у которых размер более 1 Мб
           MAIL_PKG.DELETE_MAIL(i);
         ELSE
         
         -- Еще раз запрашиваем информацию о письме и полный текст сообщения
         MAIL_PKG.GET_MAIL(i);
         -- Выводим Текст письма и количество вложений
         DBMS_OUTPUT.PUT_LINE(substr(' Text:' ||mail_pkg.mailbox(i).message,1,255) );
         DBMS_OUTPUT.PUT_LINE(' Attachments:' ||mail_pkg.mailbox(i).attachments.count);

         -- Перебираем вложения
           IF mail_pkg.mailbox(i).attachments.count>0 THEN
             FOR att IN 1..mail_pkg.mailbox(i).attachments.count LOOP
               -- Определяем вложения, помеченные в письме именно как вложения
               IF mail_pkg.mailbox(i).attachments(att).hdr.exists('Content-Disposition')
                 AND INSTR(mail_pkg.mailbox(i).attachments(att).hdr('Content-Disposition'),'attachment')>0
               THEN
                 -- Выводим в консоль имя файла и размер
                 DBMS_OUTPUT.PUT_LINE(' filename: '
                    ||mail_pkg.extract_value(mail_pkg.mailbox(i).attachments(att).hdr('Content-Disposition'),'filename')
                    ||', about '||trunc(dbms_lob.getlength(mail_pkg.mailbox(i).attachments(att).content)/1024) ||'Kbytes'
                   );
                 -- Сам контент представлен в виде CLOB
                 -- Его можно преобразовать в BLOB, сохранить в базу данных или на диск
                 -- mail_pkg.mailbox(i).attachments(att).content
               END IF;
               -- Определяем, является ли вложение текстовым файлом
               IF mail_pkg.mailbox(i).attachments(att).hdr.exists('Content-Type') THEN
                 IF INSTR(mail_pkg.mailbox(i).attachments(att).hdr('Content-Type'),'text')>0 THEN
                   -- Если да - показываем его текст в консоли
                   DBMS_OUTPUT.PUT_LINE(substr(' PreviewAttachmentText:' ||mail_pkg.mailbox(i).attachments(att).content,1,255) );
                 END IF;
               END IF;
             END LOOP;
           END IF;
         END IF;
       END LOOP;

       -- После того, как закончили работу с почтой, необходимо отключиться от сервера   
       -- В реально работающем приложении во избежание ошибок в работе с почтовым сервером
       -- рекомендуется сначала считать все необходимые данные и отключиться, а потом работать
       -- с массивом mail_pkg.mailbox
       MAIL_PKG.MAIL_DISCONNECT;

    EXCEPTION WHEN OTHERS THEN
      -- Если во время работы приложения произошла фатальная ошибка - необходимо дать почтовому 
      -- серверу команду на отключение, иначе будет повисшее соединение
      MAIL_PKG.MAIL_DISCONNECT;
    END;
```
