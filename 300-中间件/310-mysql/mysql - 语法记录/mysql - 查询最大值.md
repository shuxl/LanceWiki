要查询每门课程分数最高的学生，您可以使用以下 SQL 查询语句：
``` sql
SELECT c.course_id, c.course_name, s.student_id, s.student_name, sc.score
FROM courses c
JOIN (
    SELECT course_id, MAX(score) AS max_score
    FROM scores
    GROUP BY course_id
) max_scores ON c.course_id = max_scores.course_id
JOIN scores sc ON c.course_id = sc.course_id AND max_scores.max_score = sc.score
JOIN students s ON sc.student_id = s.student_id;

```
在这个查询中，假设您有三个表：

**courses 表：**

- course_id (课程ID)
- course_name (课程名称)

**students 表：**

- student_id (学生ID)
- student_name (学生姓名)

**scores 表：**

- student_id (学生ID)
- course_id (课程ID)
- score (分数)

此查询的步骤如下：

1. 内部子查询：首先，通过在成绩表中使用 `GROUP BY` 和 `MAX` 子句，找到每门课程的最高分数。
2. 使用这个子查询的结果（每门课程的最高分数）与课程表连接，以获取每门课程的课程ID和最高分数。
3. 然后，将这个连接的结果与成绩表连接，以获取与每门课程最高分数对应的学生ID和分数。
4. 最后，将上述连接的结果与学生表连接，以获取每门课程最高分数的学生姓名。

请注意，这个查询可能会返回多行，每一行对应每门课程的分数最高的学生。如果有多个学生具有相同的最高分数，查询将返回多个结果。