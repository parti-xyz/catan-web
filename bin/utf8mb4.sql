use information_schema;
SELECT concat("ALTER DATABASE `",table_schema,"` CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;") as _sql FROM `TABLES` where table_schema like "catan_web" group by table_schema;

SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name,"` ROW_FORMAT=DYNAMIC;") as _sql FROM `TABLES` where
table_schema like "catan_web" group by table_schema, table_name;

SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name,"` CONVERT TO
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;") as _sql FROM `TABLES` where
table_schema like "catan_web" group by table_schema, table_name;

SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name, "` CHANGE `",column_name,"` `",column_name,"` ",data_type,"(",character_maximum_length,") CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;") as _sql FROM `COLUMNS` where table_schema like "catan_web" and data_type in ('varchar');
SELECT concat("ALTER TABLE `",table_schema,"`.`",table_name, "` CHANGE `",column_name,"` `",column_name,"` ",data_type," CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;") as _sql FROM `COLUMNS` where table_schema like "catan_web" and data_type in ('text','tinytext','mediumtext','longtext');
