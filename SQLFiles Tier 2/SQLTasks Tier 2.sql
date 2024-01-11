/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name 
FROM `Facilities` 
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(*) 
FROM `Facilities` 
WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance 
FROM `Facilities` 
WHERE membercost > 0 AND membercost < .2*monthlymaintenance;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT * 
FROM `Facilities` 
WHERE facid in (1,5); 

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance,
    CASE
        WHEN monthlymaintenance > 100 THEN 'expensive'
        ELSE 'cheap' 
    END AS label
FROM `Facilities`
ORDER BY label


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT 
firstname, surname, MAX(joindate) 
FROM 
	(
        SELECT firstname, surname, joindate 
        	FROM Members WHERE firstname != "Guest"
    ) AS subquery

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT DISTINCT CONCAT(M.firstname, " ", M.surname) AS 'Member Name', F.name AS 'Facility Name' 
FROM Bookings as B  
INNER JOIN Facilities as F  
ON B.facid = F.facid 
INNER JOIN Members as M 
ON B.memid = M.memid 
WHERE B.facid in (0,1) AND M.firstname <> "GUEST"  

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT F.name AS 'Facility_Name', CONCAT(M.firstname, " ", M.surname) AS 'Member_Name',
    CASE
        WHEN B.memid = 0 THEN F.guestcost * B.slots
        ELSE F.membercost * B.slots
    END AS Total_Cost    
FROM Bookings as B
INNER JOIN Facilities as F
on B.facid = F.facid
INNER JOIN Members as M
on B.memid = M.memid
WHERE B.starttime LIKE '%2012-09-14%' AND (CASE
        WHEN B.memid = 0 THEN F.guestcost * B.slots
        ELSE F.membercost * B.slots
    END ) > 30
ORDER BY Total_Cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT F.name AS 'Facility_Name', CONCAT(M.firstname, " ", M.surname) AS 'Member_Name',
    CASE
        WHEN B.memid = 0 THEN F.guestcost * B.slots
        ELSE F.membercost * B.slots
    END AS Total_Cost    
FROM (SELECT 
      memid, slots, facid
      FROM Bookings
      WHERE starttime LIKE '%2012-09-14%'
) AS B
INNER JOIN Facilities as F on B.facid = F.facid
INNER JOIN Members    as M on B.memid = M.memid
WHERE (CASE
        WHEN B.memid = 0 THEN F.guestcost * B.slots
        ELSE F.membercost * B.slots
    END ) > 30
ORDER BY Total_Cost DESC
/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT *
FROM (SELECT F.name as 'Facility_Name', SUM(CASE 
        WHEN B.memid = 0 THEN F.guestcost * B.slots
        ELSE F.membercost * B.slots
    END) AS 'Total_Revenue'    
FROM Bookings AS B
INNER JOIN Facilities as F on B.facid = F.facid
GROUP BY F.name) AS FAB
WHERE FAB.Total_Revenue < 1000

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT FINAL.Member_NAME, 
CASE WHEN FINAL.Recommender_NAME = "GUEST,GUEST" THEN "No Recommender"
ELSE FINAL.Recommender_NAME
END AS Recommended_BY
FROM (SELECT CONCAT(M1.surname, ",", M1.firstname) as Member_NAME,
CONCAT(M2.surname, ",", M2.firstname) as Recommender_NAME
FROM Members as M1
INNER JOIN Members as M2 
on M1.recommendedby = M2.memid 
WHERE M1.memid <> 0
ORDER BY Member_NAME ASC) AS FINAL
ORDER BY Recommended_BY 

/* Q12: Find the facilities with their usage by member, but not guests */
SELECT F.name as Facility,
       CONCAT(M.firstname, " ", M.surname) AS 'Member_Name',
       COUNT(B.bookid) as Booking
FROM Bookings as B
INNER JOIN 
Facilities as F on B.facid = F.facid
INNER JOIN
Members as M on B.memid = M.memid 
WHERE M.memid <> 0
GROUP BY Facility, Member_Name
ORDER BY Facility

/* Q13: Find the facilities usage by month, but not guests */
SELECT 
	DISTINCT
    MU.Facility as Facility_Name,
    MU.MONTH AS Month_Number, 
    COUNT(MU.MONTH) OVER (PARTITION BY MU.Facility, MU.MONTH) AS Monthly_Usage 
FROM (
    SELECT 
    	F.name as Facility, 
    	MONTH(CAST(starttime AS datetime)) AS MONTH 
    FROM Bookings as B 
    INNER JOIN Facilities as F on B.facid = F.facid 
    INNER JOIN Members as M on B.memid = M.memid 
    WHERE M.memid <> 0
) AS MU;
