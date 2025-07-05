> group_concat的默认分隔符是“,”，若要改为其他分隔符，则使用SEPARATOR来指定，

---

原始风格

```
SELECT group_concat(importantmedicalstatus) 
from tm_othermedicalhistory t where ReportId = 'ff808081674a0ed101674a2835c300d4';
```

```
,2fca39b3-4a24-49ee-a3ff-d7a975d3cef6,2fff63f8-cd1f-43cf-be07-d86a60f68148,1959911e-faf1-463a-b8a7-8681f69b223e,62b0c60f-46bf-403a-b68c-5b70b38bcf9b,df4ef22d-5113-4eac-99f6-29f6824bbbd2,02507353-32ff-46a8-a84e-17d87b1b80d5,6ba88b09-f16d-487f-b3f3-645961f35bce,,,,1959911e-faf1-463a-b8a7-8681f69b223e,6ba88b09-f16d-487f-b3f3-645961f35bce
```

---

使用新的分隔符

```
SELECT group_concat(importantmedicalstatus SEPARATOR '；') 
from tm_othermedicalhistory t where ReportId = 'ff808081674a0ed101674a2835c300d4';
```

```
;2fca39b3-4a24-49ee-a3ff-d7a975d3cef6,2fff63f8-cd1f-43cf-be07-d86a60f68148,1959911e-faf1-463a-b8a7-8681f69b223e,62b0c60f-46bf-403a-b68c-5b70b38bcf9b,df4ef22d-5113-4eac-99f6-29f6824bbbd2,02507353-32ff-46a8-a84e-17d87b1b80d5,6ba88b09-f16d-487f-b3f3-645961f35bce;;;;1959911e-faf1-463a-b8a7-8681f69b223e;6ba88b09-f16d-487f-b3f3-645961f35bce
```

---

拼接in如此

```
CONCAT('\'',group_concat(r.Safetyreportid SEPARATOR '\',\''),'\'')

CONCAT('\'',group_concat(id SEPARATOR '\',\''),'\'')
```

---

异常情况

1. 字符串长度不够（设置字段长度）

```
set group_concat_max_len=11000;

SELECT GROUP_CONCAT(tenant_id)
from (
SELECT t.tenant_id
from report_submit_task t 
where t.adr_content is not NULL
GROUP BY t.tenant_id
-- LIMIT 100
) a
```