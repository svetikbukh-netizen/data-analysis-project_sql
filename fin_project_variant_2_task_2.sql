--Вариант 2
/* 2.1.2 Задача
Необходимо написать оптимальный запрос, который даст информацию о количестве очень усердных студентов.NB!
Под усердным студентом мы понимаем студента, который правильно решил 20 задач за текущий месяц.*/

WITH  
count_true AS(
SELECT st_id, subject,  COUNT(correct) AS c_correct
FROM peas
WHERE correct = True AND EXTRACT(MONTH FROM timest) = 10
  AND EXTRACT(YEAR FROM timest) = 2021 
GROUP BY st_id, subject
)
, sum_correct AS(
SELECT   st_id, subject, SUM(c_correct)
FROM count_true
GROUP BY subject, st_id -- группируем по уроку, потому что в каждом уроке нужно решить 20 задач
HAVING SUM(c_correct) >= 20
)

SELECT COUNT(DISTINCT st_id) AS count_students
FROM sum_correct;


/* 2.2.2 Задача
Необходимо в одном запросе выгрузить следующую информацию о группах пользователей:
ARPU 
ARPAU 
CR в покупку 
СR активного пользователя в покупку 
CR пользователя из активности по математике (subject = ’math’) в покупку курса по математике

ARPU считается относительно всех пользователей, попавших в группы.
Активным считается пользователь, за все время решивший больше 10 задач правильно в любых дисциплинах.
Активным по математике считается пользователь, за все время решивший 2 или больше задач правильно по математике.*/

WITH 
stud_activity AS( -- студенты решившие правильно задачи
SELECT st_id
,COUNT(CASE WHEN correct = TRUE THEN 1  END) AS total_correct_peas 
,COUNT(CASE WHEN correct = TRUE AND subject = 'Math' THEN 1 END) AS math_correct_peas
FROM peas 
GROUP BY st_id
)
,stud_check AS ( -- студенты, купившие курс
SELECT st_id
,SUM(money) AS total_money_course
,MAX(CASE WHEN subject = 'Math' THEN 1 ELSE 0 END) AS check_math_course -- отметка покупки курса по математике
FROM final_project_check
GROUP BY st_id
)

,full_data_grp AS ( -- данные для каждой группы
SELECT s.test_grp 
,s.st_id
--,COALESCE(a.total_correct_peas, 0) AS total_correct_peas
--,COALESCE(a.math_correct_peas, 0) AS math_correct_peas
,COALESCE(c.total_money_course, 0) AS total_money_course
,COALESCE(c.check_math_course, 0) AS check_math_course
--студенты, решившие более 10 задач успешно
,CASE WHEN COALESCE(a.total_correct_peas, 0) > 10 THEN 1 ELSE 0 END AS active_stud
--студенты решившие 2 и более задач по матетматике
,CASE WHEN COALESCE(a.math_correct_peas, 0) >= 2 THEN 1 ELSE 0 END AS active_math_stud
-- студенты купившие курс
,CASE WHEN c.st_id IS NOT NULL THEN 1 ELSE 0 END AS made_purchase
FROM studs AS s
LEFT JOIN stud_activity AS a ON s.st_id = a.st_id
LEFT JOIN stud_check AS c ON s.st_id = c.st_id
) 

SELECT
test_grp
-- ARPU (Average Revenue Per User) = Общий доход от курса/ все студенты
,SUM(total_money_course) /COUNT(DISTINCT st_id) AS ARPU
-- ARPAU (Average Revenue Per Active User) = Общий доход от активного студента/ все активные студенты
,SUM(CASE WHEN active_stud = 1 THEN total_money_course ELSE 0 END) /SUM(active_stud) AS ARPAU
-- CR в покупку (Conversion Rate в покупку) = Студенты купившие курс/ все студенты * 100%
,SUM(made_purchase) * 100 / COUNT(DISTINCT st_id)  AS CR_to_purchas
--CR активного пользователя в покупку = Aктивные студенты купившие курс/ все активные студенты * 100%
,SUM(CASE WHEN active_stud = 1 AND made_purchase = 1 THEN 1 ELSE 0 END) * 100 /SUM(active_stud) AS CR_active_to_purchase
-- CR пользователя из активности по математике в покупку курса по математике = 
-- Aктивные студенты купившие курс по математике/ все активные студенты по математике *100%
,SUM(CASE WHEN active_math_stud = 1 AND check_math_course = 1 THEN 1 ELSE 0 END) *100 /SUM(active_math_stud) AS CR_math_active_to_math_purchase
FROM full_data_grp
GROUP BY
    test_grp
ORDER BY
    test_grp;
