CREATE OR REPLACE PACKAGE TEST_DATA_GENERATOR IS
   TYPE t_list IS TABLE OF VARCHAR2(16);
   v_surnames t_list := t_list('Смирнов','Иванов','Кузнецов','Соколов','Попов','Лебедев','Козлов','Новиков',
  'Морозов','Петров','Волков','Соловьёв','Васильев','Зайцев','Павлов','Семёнов','Голубев',
  'Виноградов','Богданов','Воробьёв','Фёдоров','Михайлов','Беляев','Тарасов','Белов','Комаров','Орлов',
  'Киселёв','Макаров','Андреев','Ковалёв','Ильин','Гусев','Титов','Кузьмин','Кудрявцев','Баранов','Куликов',
  'Алексеев','Степанов','Яковлев','Сорокин','Сергеев','Романов','Захаров','Борисов','Королёв','Герасимов',
  'Пономарёв','Григорьев','Лазарев','Медведев','Ершов','Никитин','Соболев','Рябов','Поляков','Цветков',
  'Данилов','Жуков','Фролов','Журавлёв','Николаев','Крылов','Максимов','Сидоров','Осипов','Белоусов',
  'Федотов','Дорофеев','Егоров','Матвеев','Бобров','Дмитриев','Калинин','Анисимов','Петухов','Антонов',
  'Тимофеев','Никифоров','Веселов','Филиппов','Марков','Большаков','Суханов','Миронов','Ширяев','Александров',
  'Коновалов','Шестаков','Казаков','Ефимов','Денисов','Громов','Фомин','Давыдов','Мельников','Щербаков',
  'Блинов','Колесников','Карпов','Афанасьев','Власов','Маслов','Исаков','Тихонов','Аксёнов','Гаврилов',
  'Родионов','Котов','Горбунов','Кудряшов','Быков','Зуев','Третьяков','Савельев','Панов','Рыбаков',
  'Суворов','Абрамов','Воронов','Мухин','Архипов','Трофимов','Мартынов','Емельянов','Горшков','Чернов',
  'Овчинников','Селезнёв','Панфилов','Копылов','Михеев','Галкин','Назаров','Лобанов','Лукин','Беляков',
  'Потапов','Некрасов','Хохлов','Жданов','Наумов','Шилов','Воронцов','Ермаков','Дроздов','Игнатьев',
  'Савин','Логинов','Сафонов','Капустин','Кириллов','Моисеев','Елисеев','Кошелев','Костин','Горбачёв',
  'Орехов','Ефремов','Исаев','Евдокимов','Калашников','Кабанов','Носков','Юдин','Кулагин','Лапин',
  'Прохоров','Нестеров','Харитонов','Агафонов','Муравьёв','Ларионов','Федосеев','Зимин','Пахомов',
  'Шубин','Игнатов','Филатов','Крюков','Рогов','Кулаков','Терентьев','Молчанов','Владимиров','Артемьев',
  'Гурьев','Зиновьев','Гришин','Кононов','Дементьев','Ситников','Симонов','Мишин','Фадеев','Комиссаров',
  'Мамонтов','Носов','Гуляев','Шаров','Устинов','Вишняков','Евсеев','Лаврентьев','Брагин','Константинов',
  'Корнилов','Авдеев','Зыков','Бирюков','Шарапов','Никонов','Щукин','Дьячков','Одинцов','Сазонов',
  'Якушев','Красильников','Гордеев','Самойлов','Князев','Беспалов','Уваров','Шашков','Бобылёв','Доронин',
  'Белозёров','Рожков','Самсонов','Мясников','Лихачёв','Буров','Сысоев','Фомичёв','Русаков','Стрелков',
  'Гущин','Тетерин','Колобов','Субботин','Фокин','Блохин','Селиверстов','Пестов','Кондратьев','Силин',
  'Меркушев','Лыткин','Туров'
  );
  v_m_names t_list := t_list('Александр','Алексей','Дмитрий','Сергей','Андрей','Антон','Артём','Артемий','Виталий','Владимир','Денис',
 'Евгений','Иван','Игорь','Константин','Максим','Михаил','Николай','Павел','Роман','Станислав','Август',
 'Адам','Адриан','Аким','Ананий','Анатолий','Антонин','Аполлон','Аркадий','Арсений','Богдан','Болеслав',
 'Борис','Бронислав','Вадим','Валентин','Валериан','Валерий','Василий','Вениамин','Виктор','Викентий','Виль',
 'Витольд','Владислав','Владлен','Всеволод','Вячеслав','Геннадий','Георгий','Герасим','Герман','Глеб','Гордей',
 'Григорий','Давид','Дан','Даниил','Данила','Добрыня','Донат','Егор','Ефим','Захар','Игнатий','Игнат',
 'Илларион','Илья','Иннокентий','Иосиф','Ираклий','Кирилл','Клим','Кузьма','Лаврентий','Лев','Леонид',
 'Макар','Марк','Матвей','Милан','Мирослав','Назар','Никита','Никодим','Олег','Пётр','Платон','Прохор',
 'Радислав','Рафаил','Родион','Ростислав','Руслан','Савва','Сава','Святослав','Семён','Степан','Стефан',
 'Тарас','Тимофей','Тит','Фёдор','Феликс','Филипп','Юлиан','Юлий','Юрий','Яков','Ян','Ярослав');
 
  v_f_names t_list := t_list('Анастасия','Анна','Екатерина','Мария','Наталья','Ольга','Юлия','Александра','Виктория','Дарья',
'Елена','Ирина','Ксения','Светлана','Августа','Ада','Алевтина','Александрия','Алёна','Алина','Алиса',
'Алла','Альбина','Ангелина','Антонина','Анфиса','Арина','Аэлита','Валентина','Валерия','Ванда','Варвара',
'Василина','Василиса','Вера','Вероника','Веселина','Викторина','Вилена','Виталина','Виталия','Влада',
'Владилена','Владислава','Власта','Галина','Дана','Дарина','Дина','Ева','Евгения','Евдокия','Елизавета',
'Зарина','Зинаида','Злата','Зоя','Иванна','Инна','Ия','Капитолина','Катерина','Кира','Клавдия','Кристина',
'Лада','Лариса','Лидия','Лилиана','Лилия','Лия','Любава','Любовь','Людмила','Майя','Маргарита','Марианна','Марина',
'Марьяна','Мелитина','Милада','Милана','Милена','Надежда','Настасья','Ника','Нина','Нинель','Нонна','Оксана','Олеся',
'Полина','Рада','Радмила','Раиса','Регина','Римма','Руслана','Руфина','Серафима','Симона','Славяна','Снежана',
'Софья','Станислава','Сусанна','Таисия','Тамара','Тамила','Ульяна','Фаина','Христина','Эльмира','Эмилия','Юлиана',
'Яна','Янина','Ярослава');
 
  v_secnames t_list := t_list('Александров','Алексеев','Альбертов','Анатольев','Андреев','Аркадьев','Афанасьев','Богданович',
 'Борисов','Вадимов','Валентинов','Валериев','Васильев','Вениаминов','Викторов','Владимиров',
 'Вячеславов','Геннадьев','Георгиев','Григорьев','Давидов','Дмитриев','Евгеньев','Егоров',
 'Ефимов','Иванов','Игорев','Иль','Иосифов','Кириллов','Константинов','Леонидов','Львов','Максимов',
 'Матвеев','Миронов','Михайлов','Натанов','Николаев','Олегов','Павлов','Петров','Русланов','Сергеев',
 'Станиславов','Тарасов','Тимофеев','Фёдоров','Филиппов','Эдуардов','Юрьев','Яковлев','Ярославов');
  
  v_cities t_list := t_list('Москва','Санкт-Петербург','Новосибирск','Омск','Казань','Сочи','Иркутск','Красноярск',
  'Томск','Кемерово','Барнаул','Екатеринбург');

  FUNCTION GEN RETURN VARCHAR2;

END;
/

CREATE OR REPLACE PACKAGE BODY TEST_DATA_GENERATOR IS
 
 FUNCTION GEN RETURN VARCHAR2 IS
  v_sex char := case when round(dbms_random.value(0,1))=1 then 'Ж' else 'М' end;
  v_surname varchar2(16):= v_surnames(dbms_random.value(1,v_surnames.count)) || case when v_sex = 'Ж' then 'а' else '' end;
  v_secname varchar2(16) := v_secnames(dbms_random.value(1,v_secnames.count)) || case when v_sex = 'Ж' then 'на' else 'ич' end;
  v_firstname varchar2(16):= case when v_sex = 'Ж' then v_f_names(dbms_random.value(1,v_f_names.count)) else v_m_names(dbms_random.value(1,v_m_names.count)) end;
  v_age number := round(dbms_random.value(0,90)); 
  v_city varchar2(16) := v_cities(dbms_random.value(1,v_cities.count));

 BEGIN
   return v_surname || ' ' || v_firstname || ' ' || v_secname || ' ' || v_age ||' ' || v_city;     
 END;

END;
/

