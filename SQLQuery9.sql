
use [Covid_Data]

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 * FROM [Covid_deaths] order by 3,4

SELECT TOP 1000 * FROM [Covid_vaccinations] order by 3,4

-- selecting required columns

SELECT [location],[date],[total_cases],[new_cases],[total_deaths],[new_deaths],[population] FROM [Covid_deaths] order by 1,2

/****** showing  percentage of total_deaths for total_cases registered******/

SELECT [location],[date],[population],[total_cases]
		,cast([total_deaths] as int) as total_deaths
		,round(([total_deaths]/[total_cases])*100, 3) as perc_death_per_case 
FROM [Covid_deaths] 
where --location like 'India' and
		[continent] is not null and          -- To remove combined data on continents  
		date in (SELECT MAX(date) FROM [Covid_deaths])
order by total_deaths desc,perc_death_per_case desc


/****** showing percentage of total deaths per population and total cases per population ******/

SELECT [location],[date],[population],total_cases
		,cast([total_deaths] as int) as total_deaths
		,round(([total_cases]/[population])*100, 3) as cases_per_population 
		,round(([total_deaths]/[population])*100, 3) as death_per_population 
FROM [Covid_deaths] 
where --location like 'India' and
		[continent] is not null and  
		date in (SELECT MAX(date) FROM [Covid_deaths])  --To select latest date or group by location
order by total_deaths desc,death_per_population desc


/****** global cases and deaths on each day ******/

SELECT date, sum([new_cases]) as cases_per_day,sum(cast([new_deaths] as int)) as deaths_per_day FROM [Covid_deaths]
where --location like 'India' and
[continent] is not null 
group by [date]
having sum([new_cases]) is not null
order by 1 


/******  population vs vaccinations and find rolling sum of vaccinations******/

SELECT  d.[continent],d.[location],cast(d.date as date) as date_Cast, d.[population], d.[total_cases], v.[new_vaccinations],
		sum(convert(int,v.[new_vaccinations])) over( partition by d.location order by d.location, cast(d.date as date)) as rolln_sum_vacc
FROM [Covid_deaths] d 
	 join [dbo].[Covid_vaccinations] v
     on d.location = v.location
	    and d.date = v.date
where d.[continent] is not null 
	  --and d.location like 'India' 


/****** Using CTE to perform Calculation on rolling sum of vaccinations in previous query ******/

with cte ([continent],[location],date,[population],[total_cases],[new_vaccinations],people_fully_vaccinated,rolln_sum_vacc) as 
(
SELECT  d.[continent],d.[location],cast(d.date as date) as date_Cast, d.[population], d.[total_cases], v.[new_vaccinations],
		cast(v.[people_fully_vaccinated] as int) as people_fully_vaccinated,
		sum(convert(int,v.[new_vaccinations])) over( partition by d.location order by d.location, cast(d.date as date)) as rolln_sum_vacc
FROM [Covid_deaths] d 
	 join [dbo].[Covid_vaccinations] v
     on d.location = v.location
	    and d.date = v.date
where d.[continent] is not null 
	  --and d.location like 'India' 
)

-- Percentage of people fully vaccinated per population 

select location,population, max(cast(date as date)) as date_latest ,
		max(people_fully_vaccinated) as full_vacc  ,
		max((people_fully_vaccinated/population)*100) as perc_full_vac, 
		max((rolln_sum_vacc/population)*100) as percent_vaccinations 
from cte 
where   rolln_sum_vacc is not null 
	    --and population > 1000000
group by location,population
order by perc_full_vac desc , percent_vaccinations  desc


/****** Using temporary table to perform Calculation on Partition By in previous query ******/

drop table #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
( 
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
total_cases numeric,
New_vaccinations numeric,
people_fully_vaccinated numeric,
rolln_sum_vacc numeric
);

insert into #PercentPopulationVaccinated 
	SELECT  d.[continent],d.[location],cast(d.date as date) as date_Cast, d.[population], d.[total_cases], v.[new_vaccinations],
				cast(v.[people_fully_vaccinated] as int) as people_fully_vaccinated,
				sum(convert(int,v.[new_vaccinations])) over( partition by d.location order by d.location, cast(d.date as date)) as rolln_sum_vacc
	FROM [Covid_deaths] d 
		join [dbo].[Covid_vaccinations] v
		on d.location = v.location
			and d.date = v.date
	where d.[continent] is not null 
		 --and d.location like 'India' ;

-- Percentage of people fully vaccinated per population 

select location,population, max(cast(date as date)) as date_latest ,
		max(people_fully_vaccinated) as full_vacc  ,
		max((people_fully_vaccinated/population)*100) as perc_full_vac, 
		max((rolln_sum_vacc/population)*100) as percent_vaccinations 
from #PercentPopulationVaccinated
where   rolln_sum_vacc is not null 
       --and population > 1000000
group by location,population
order by percent_vaccinations  desc


-- Creating View

drop view PercentPopulationVaccinated

create view PercentPopulationVaccinated as

with cte ([continent],[location],date,[population],[total_cases],[new_vaccinations],people_fully_vaccinated,rolln_sum_vacc) as 
(
SELECT  d.[continent],d.[location],cast(d.date as date) as date_Cast, d.[population], d.[total_cases], v.[new_vaccinations],
		cast(v.[people_fully_vaccinated] as int) as people_fully_vaccinated,
		sum(convert(int,v.[new_vaccinations])) over( partition by d.location order by d.location, cast(d.date as date)) as rolln_sum_vacc
FROM [Covid_deaths] d 
	 join [dbo].[Covid_vaccinations] v
     on d.location = v.location
	    and d.date = v.date
where d.[continent] is not null 
	  --and d.location like 'India' 
)
select location,population, max(cast(date as date)) as date_latest ,
		max(people_fully_vaccinated) as full_vacc  ,
		max((people_fully_vaccinated/population)*100) as perc_full_vac, 
		max((rolln_sum_vacc/population)*100) as percent_vaccinations 
from cte 
where   rolln_sum_vacc is not null
group by location,population





