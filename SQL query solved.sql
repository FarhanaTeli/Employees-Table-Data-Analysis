/* Steps
1. Python
2. Create env
3. Jupyter notebook or any IDE of your choice.
4. Point the env to the IDE.


1. Setup DB
2. Create DB.
3. \i path_to_sql_file (Run schema creation file 1st, then the dump file)
4. You will get the tables and the values in it.

*/

/* 2. Which department has the highest average salary of active employees ? Give some plots to show the avg salary department-wise.*/
select tab2.dept_name, avg(tab2.amount) from (select d.dept_name, s.amount from employees.employee e 
											  join employees.salary s on e.id = s.employee_id 
								 			  join employees.department_employee de on e.id=de.employee_id
											  join employees.department d on de.department_id = d.id
											  where s.to_date = '9999-01-01' and de.to_date = '9999-01-01') tab2
					 						  group by tab2.dept_name

/* 3. Which title has the highest avg salary? Give some plots to show the avg salary title-wise.*/
select tab1.title, avg(tab1.amount) from (select s.amount, t.title from employees.employee e
										 left join employees.title t on t.employee_id=e.id
										 left join employees.salary s on s.employee_id=e.id
										 where date_part('year', s.to_date) = 9999
										 and date_part('year',t.to_date) = 9999) tab1 group by tab1.title

/* 4. Distribution of salary across titles.*/
select ti.title, s.amount from employees.title ti
left join employees.salary s on ti.employee_id = s.employee_id 
where date_part('year', ti.to_date) = 9999 and date_part('year', s.to_date) = 9999
group by ti.title, s.amount

/* 5. Distribution of salary across departments.*/
select d.dept_name, s.amount from employees.salary s
left join employees.department_employee de on s.employee_id = de.employee_id
left join employees.department d on d.id = de.department_id
where date_part('year', de.to_date) = 9999 and date_part('year', s.to_date) = 9999

/* 6. How many active managers in each department. Is there any department with no manager? */
select d.dept_name, count(dm.employee_id) as manager_counts from employees.department d
left join employees.department_manager dm on d.id = dm.department_id
left join employees.employee e on dm.employee_id = e.id
where date_part('year', dm.to_date) = 9999
group by d.dept_name


select d.dept_name from employees.department d
left join employees.department_manager dm on d.id = dm.department_id
where dm.employee_id isnull

/*7. Composition of titles department-wise. Appropriate plots.
8. Composition of departments title-wise. Appropriate plots.
*/
select d.dept_name, ti.title, count(*) as title_counts from employees.department_employee de
join employees.department d on de.department_id = d.id
join employees.employee e on de.employee_id = e.id
join employees.title ti on e.id = ti.employee_id
group by d.dept_name, ti.title
order by d.dept_name, title_counts desc

/* 9. Salaries of active department managers. Which department's manager who is active earns the most?*/
select d.dept_name, s.amount from employees.department_manager dm
inner join employees.salary s on dm.employee_id = s.employee_id
inner join employees.department d on d.id = dm.department_id
where dm.to_date = '9999-01-01' and s.to_date = '9999-01-01' 

/* 10. What are the titles of active department managers? Are they managers only?*/
select d.dept_name, tit.title from employees.department_manager dm
join employees.title tit on dm.employee_id = tit.employee_id
join employees.department d on d.id = dm.Department_id
where date_part('year', dm.to_date) = 9999 and date_part('year', tit.to_date) = 9999

/* 11. Past history of salaries of managers across department (yearly)*/
select dm.employee_id as manager_id, d.dept_name, s.amount as salary, s.from_date, s.to_date 
from employees.department_manager dm join employees.salary s on dm.employee_id = s.employee_id
join employees.department d on dm.department_id = d.id
where s.from_date >= dm.from_date and s.to_date <= dm.to_date

/*12. Distribution of salaries of active employees working for more than 10 years vs 4 years vs 1 year.*/
with active_employee as (
	select e.id, s.amount as salary, date_part('year', de.to_date) - date_part('year', e.hire_date) as year_of_experience
	from employees.employee e join employees.department_employee de on e.id = de.employee_id
	join employees.salary s on e.id = s.employee_id
	where s.to_date = '9999-01-01' and date_part('year', de.to_date) - date_part('year', e.hire_date) <= 60
)
select 
	 case
		when year_of_experience > 10 then 'More than 10 years'
    	when year_of_experience > 4 then '4 to 10 years'
    	when year_of_experience >= 1 then ' 1 to 4 years'
        else 'Less than 1 year experience'
      end as service_category,
	  salary
from active_employee 

/*13. Average number of years employees work in the company before leaving (title wise).*/
select ti.title,  avg(date_part('year',ti.to_date) - date_part('year',e.hire_date) + 1) AS avg_years_before_leaving
from employees.employee e join employees.title ti
on e.id = ti.employee_id
where date_part('year', ti.to_date) != 9999
group by ti.title

/*select * from employees.title*/

/*14. Average number of years employees work in the company before leaving (Dept wise).*/
select d.dept_name, avg(date_part('year',de.to_date) - date_part('year',e.hire_date) ) as average_years_before_leaving
from employees.employee e join employees.department_employee de
on e.id = de.employee_id
join employees.department d on de.department_id = d.id
where date_part('year', de.to_date) !=9999
group by d.dept_name

/*15. Median annual salary increment department wise.*/
with salary_increment as 
(select d.dept_name, date_part('year', s.from_date) as start, 
date_part('year', s.to_date) as end, max(s.amount) - min(s.amount) as annual_increment
from employees.department d join employees.department_employee de 
on d.id = de.department_id
join employees.salary s on de.employee_id =s.employee_id
group by d.dept_name, date_part('year', s.from_date), date_part('year', s.to_date))
select dept_name, percentile_cont(0.5) WITHIN GROUP (ORDER BY annual_increment) as median_annual_increment
from salary_increment 
group by dept_name
order by median_annual_increment

/* 16. Retrieve employees who are also managers.*/
select d.dept_name as department, de.employee_id as employee_id, e.first_name as employee_name
from employees.employee e join employees.department_employee de
on e.id = de.employee_id
join employees.department d on d.id = de.department_id
where de.employee_id in (select distinct dm.employee_id from employees.department_manager dm)

/* 17. Find employees who earn more than their department's average salary*/
select d.dept_name as department, avg(s.amount) as average_salary
from employees.department d left join employees.department_employee de 
on d.id = de.department_id
left join employees.salary s on de.employee_id = s.employee_id
where de.to_date = '9999-01-01' and s.to_date = '9999-01-01' 
group by d.dept_name"""

select e.first_name as employee_name, s.amount as salary, d.dept_name as department_name
from employees.employee e
join employees.department_employee de ON e.id = de.employee_id
join employees.department d ON de.department_id = d.id
join employees.salary s on de.employee_id = s.employee_id
where s.to_date = '9999-01-01' and de.to_date = '9999-01-01'
group by e.first_name, s.amount, d.dept_name
having s.amount > avg(s.amount)

select e.first_name as employee_name, s.amount as salary, d.dept_name as department_name, avg(s.amount) as department_average_salary
from employees.employee e join employees.department_employee de on e.id = de.employee_id
left join employees.department d on de.department_id = d.id
left join employees.salary s on de.employee_id = s.employee_id
group by e.first_name, s.amount, d.dept_name
having s.amount > avg(s.amount)

select d.dept_name, avg(s.amount), de.employee_id from employees.department d
left join employees.department_employee de on d.id = de.department_id
left join employees.salary s on de.employee_id = s.employee_id
where de.to_date = '9999-01-01'
group by d.dept_name,de.employee_id, s.amount
having s.amount > avg(s.amount)

SELECT e.first_name as employee_name, s.amount as salary, d.dept_name as department_name
FROM employees.employee e
JOIN employees.department_employee de ON e.id = de.employee_id
JOIN employees.department d ON de.department_id = d.id
join employees.salary on de.employee_id = s.employee_id
WHERE s.amount > (
    SELECT AVG(s.amount)
    FROM employees.employee e
    JOIN employees.department_employee dee ON e.id = dee.employee_id
	join employees.salary s on dee.employee_id = s.employee_id
    WHERE dee.department_id = de.department_id
);

/*select distinct e.id from employees.employee e
where e.id not in (select distinct de.employee_id from employees.department_employee de)
*/

/* 18. Find the employee(s) with the highest salary in each department:*/
select department, employee_id, employee_name, salary
from (
	select d.dept_name as department, e.id as employee_id, e.first_name as employee_name, s.amount as salary, row_number() over (partition by d.dept_name order by s.amount desc) as ranking
	from employees.employee e join employees.department_employee de 
	on e.id = de.employee_id join employees.salary s
	on de.employee_id = s.employee_id
	join employees.department d on de.department_id = d.id
) ranked_employees
where ranking = 1

/*Find counts of each and every table.*/
select count(*), 'department' as table_name from employees.department union all
select count(*), 'department_employee' as table_name from employees.department_employee union all
select count(*), 'department_manager' as table_name from employees.department_manager union all
select count(*), 'employee' as table_name from employees.employee union all
select count(*), 'salary' as table_name from employees.salary union all
select count(*), 'title' as table_name from employees.title
