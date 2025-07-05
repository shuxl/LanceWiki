# 1 set
## 1.1 普通set
```
set @submissionId = "8ac0bf9e8b94093d018b9409fa970018";
```
## 1.2 查询set
```
-- 无查询结果
set @queryEntityId := (select id from common_query_entity where biz_entity_id = @submissionId );
-- 显示查询结果
select @relationGroupId := (select id from common_query_entity_relation_group where query_entity_id = @queryEntityId );
```

# 2 查询条件case when
查询条件动态拼接，根据输入场景

```
select *
from t_mdm_dictionary_entry
where dictionary_id = '8ac0812e8bed2a2e018bf511aa6508c4'
and 
	case 
		when (
			SELECT ssr.REVIEW_CATEGORY 
			FROM site_mdm.mdm_form_data_v2_ff8080818bf6cb7d018bf6d6_1 ssr 
			where id = '8ac080408cd78d82018cd8f009576582'
        ) = 2 then (tags like '%Expedited%' or tags like '%Administrative%')
	else 
     1=1
	end;
;
```