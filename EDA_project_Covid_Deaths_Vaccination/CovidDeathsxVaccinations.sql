select * 
from coviddeths 
order by 3, 4;

-- select * 
-- from covidvaccinations 
-- order by 3, 4;


select 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
 population
from coviddeths
order by 1, 2;

-- Looking at Total Cases vs Total Deaths

select 
	location,
	date,
	total_cases,
	total_deaths,
	round((1.0 * total_deaths / total_cases)*100, 5) as DeathsPercentage
from coviddeths
where location like 'Israel'
order by 1, 2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

select 
	location,
	date,
	population,
	total_cases,
	round((1.0 * total_cases / population)*100, 5) as CasestoPopulation
from coviddeths
--where location like 'Israel'
order by 1, 2;


-- Looking for Countries with the Highest Infection Rate to Population

select 
	location,
	population,
	max(total_cases) as HighestInfectionCount,
	max(round((1.0 * total_cases / population)*100, 5)) as CasestoPopulation
from coviddeths
--where location like 'Israel'
group by 1, 2
order by 4 desc;


-- Showing Countries with Highest Deaths Count per Population

select 
	location,
	max(total_deaths) as TotalDeathsCount
from coviddeths
--where location like 'Israel'
where continent is not NULL
group by 1
order by TotalDeathsCount desc;


-- Showitn continent with the highest deaths count per population

select 
	continent,
	max(total_deaths) as TotalDeathsCount
from coviddeths
--where location like 'Israel'
where continent is not NULL
group by 1
order by TotalDeathsCount desc;



-- GLOBAL NUMBERS

select 
	date,
	sum(new_cases) as total_cases,
	sum(new_deaths) as total_deaths,
	1.0 * sum(new_deaths) / sum(new_cases) * 100 as DeathsPercentage
from coviddeths
where continent is not NULL
group by 1
order by 1, 2;

 

-- Looking at Total Population vs Vaccinaitons

select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3;



-- USE CTE

with PopvsVac as (
	select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeths dea
join covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3;
)
select 
	*,
	RollingPeopleVaccinated / population * 100.0
from PopvsVac;


-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as 
 select 
 	dea.continent,
 	dea.location,
 	dea.date,
 	dea.population,
 	vac.new_vaccinations,
 	sum(new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
 from coviddeths dea
 join covidvaccinations vac
 	on dea.location = vac.location
 	and dea.date = vac.date
 where dea.continent is not null;
 --order by 2, 3;







































































































