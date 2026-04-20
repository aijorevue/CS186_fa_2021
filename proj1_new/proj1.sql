-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
   SELECT MAX(ERA)
   FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst,namelast,birthyear
  FROM people
  WHERE weight>300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst,namelast,birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst ASC,namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
    SELECT birthyear,AVG(height),COUNT(*)
    FROM people
    GROUP BY birthyear
    ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
    SELECT birthyear,
            AVG(height) AS avgheight,
            Count(*) AS count
    FROM people
    GROUP BY birthyear HAVING avgheight>70
    ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
    SELECT p.namefirst,p.namelast,p.playerid,h.yearid
    FROM people AS p,halloffame AS h
    WHERE p.playerid=h.playerid AND h.inducted='Y'
    ORDER BY h.yearid DESC,p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
    SELECT p.namefirst,p.namelast,p.playerid,c.schoolid,h.yearid
    FROM people AS p
    JOIN halloffame AS h ON p.playerid =c.playerid
    JOIN schools AS s ON c.schoolid=s.schoolid
    WHERE h.inducted='Y'AND s.schoolState='CA'
    ORDER BY h.yearid DESC,c.schoolid ASC,p.playerid ASC

;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
    SELECT h.playerid,p.namefirst,p.namelast,c.schoolid
    FROM halloffame AS h
    JOIN people AS p ON h.playerid=p.playerid
    LEFT JOIN collegeplaying AS c ON h.playerid=c.playerid
    WHERE h.inducted='Y'
    ORDER BY h.playerid DESC,c.schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT b.playerid,p.namefirst,p.namelast,b.yearid,
        (b.H+b.H2B+b.H3B*2+b.HR*3)*1.0/b.AB AS slg
  FROM batting AS b
  JOIN people AS p ON b.playerid=p.playerid
  WHERE b.AB>50
  ORDER BY slg DESC,b.yearid ASC,b.playerid ASC
  LIMIT 10
  
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid,p.namefirst,p.namelast,
        (SUM(b.H)+SUM(b.H2B)+2*SUM(b.H3B)+3*SUM(b.HR))*1.0/SUM(b.AB) AS lslg
  FROM people AS p
  JOIN batting AS b ON p.playerid=b.playerid
  /*WHERE b.AB>50*/
  Group BY p.playerid
  HAVING SUM(b.AB)>50
  ORDER BY lslg DESC,p.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
 SELECT p.namefirst, p.namelast,
       (SUM(b.H)+SUM(b.H2B)+2*SUM(b.H3B)+3*SUM(b.HR))*1.0/SUM(b.AB) AS lslg
FROM people AS p
JOIN batting AS b ON p.playerid = b.playerid
GROUP BY p.playerid
HAVING SUM(b.AB) > 50 
   AND lslg > (  -- 这里的 lslg 在某些 SQL 引擎中可用，若不可用需写完整公式
       SELECT (SUM(H)+SUM(H2B)+2*SUM(H3B)+3*SUM(HR))*1.0/SUM(AB)
       FROM batting
       WHERE playerid = 'mayswi01'
   )
ORDER BY lslg DESC; 
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT s.yearid,MIN(s.salary),MAX(s.salary),AVG(s.salary)
  FROM salaries AS s
  GROUP BY s.yearid
  ORDER BY s.yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
WITH
  -- 第一步：计算 2016 年薪资的基础统计量（最小值、最大值、每个桶的跨度）
  stats AS (
    SELECT 
      MIN(salary) AS min_s, 
      MAX(salary) AS max_s,
      (MAX(salary) - MIN(salary)) / 10.0 AS width
    FROM salaries 
    WHERE yearid = 2016
  ),
  
  -- 第二步：生成 10 个桶的边界（low 和 high）
  -- 这一步不看具体球员，只用数学公式画出 10 个“抽屉”
  bins AS (
    SELECT 
      binid,
      min_s + binid * width AS low,
      -- 如果是最后一个桶（binid 9），为了防止浮点数精度误差，
      -- 也可以直接让它等于 max_s，或者统一用公式
      min_s + (binid + 1) * width AS high
    FROM binids, stats
  )

-- 第三步：将生成的桶与 2016 年的实际薪资进行关联统计
SELECT 
  b.binid, 
  b.low, 
  b.high, 
  COUNT(s.salary) AS count
FROM bins b
LEFT JOIN salaries s ON s.yearid = 2016 
  AND s.salary >= b.low 
  AND (
    -- 对于 0-8 号桶，采用 [low, high) 左闭右开
    (b.binid < 9 AND s.salary < b.high) 
    OR 
    -- 对于 9 号桶，采用 [low, high] 全闭，确保最高薪的人被包含
    (b.binid = 9 AND s.salary <= b.high)
  )
GROUP BY b.binid, b.low, b.high
ORDER BY b.binid;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff) AS
  WITH yearly_stats AS (
    SELECT 
      yearid,
      MIN(salary) AS mins,
      MAX(salary) AS maxs,
      AVG(salary) AS avgs
    FROM salaries
    GROUP BY yearid
  )
  SELECT 
    curr.yearid,
    curr.mins - prev.mins AS mindiff,
    curr.maxs - prev.maxs AS maxdiff,
    curr.avgs - prev.avgs AS avgdiff
  FROM yearly_stats curr
  JOIN yearly_stats prev ON curr.yearid = prev.yearid + 1
  ORDER BY curr.yearid;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid) AS
  SELECT p.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM salaries s
  JOIN people p ON s.playerid = p.playerid
  WHERE (s.yearid = 2000 AND s.salary = (SELECT MAX(salary) FROM salaries WHERE yearid = 2000))
     OR (s.yearid = 2001 AND s.salary = (SELECT MAX(salary) FROM salaries WHERE yearid = 2001))
  ORDER BY s.yearid, p.playerid;
-- Question 4v

CREATE VIEW q4v(team, diffAvg) AS -- 这里把 teamid 改成 team
  SELECT 
    a.teamid,
    MAX(s.salary) - MIN(s.salary) AS diffAvg
  FROM allstarfull a
  JOIN salaries s ON a.playerid = s.playerid 
    AND a.yearid = s.yearid 
    AND a.teamid = s.teamid
  WHERE a.yearid = 2016
  GROUP BY a.teamid
  ORDER BY a.teamid;