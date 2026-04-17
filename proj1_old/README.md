本README仅仅针对于CS186这门课的project1
所有的文件和环境搭建已经完成，接下来的操作是对于控制台命令的解释
1.  sqlite3 lahman.db
2. .tables(注意在这之后所输入的内容会不可显示但依然存在)
3. .schema people(查询people表的列名)
4. 在终端对于文件内容进行查询：例：sqlite>  SELECT playerid, namefirst, namelast FROM people;
5. 所有的表：People - Player names, date of birth (DOB), and biographical info
   Batting - batting statistics
   Pitching - pitching statistics
   Fielding - fielding statistics