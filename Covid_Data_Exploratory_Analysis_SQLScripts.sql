select * from CovidAnalysis1..CovidDeaths 
order by 3,4

--select * from CovidAnalysis1..CovidVaccinations
--order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
from CovidAnalysis1..CovidDeaths
where continent is not null
order by 1,2

--Looking at total cases VS total Deaths
--Shows likelihood of dying if anyone contracts covid in United Arab Emirates
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percentage
from CovidAnalysis1..CovidDeaths
where location like '%United Arab Emirates%'
where continent is not null
order by 1,2

-- Looking at total cases VS population
-- Shows what % of popuation got covid
Select Location, date, total_cases, population, (total_cases/population)*100 as covid_percentage
from CovidAnalysis1..CovidDeaths
--where location like '%United Arab Emirates%'
where continent is not null
order by 1,2

--Looking at countries with hightest infection rate compared to population
Select Location, population, MAX(total_cases) as HighestInfectionCount, population, 
MAX((total_cases/population))*100 as percentagePopulationInfected
from CovidAnalysis1..CovidDeaths
--where location like '%United Arab Emirates%'
where continent is not null
Group by Location, Population 
order by percentagePopulationInfected desc

--  Showing contries with highest Death count per population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidAnalysis1..CovidDeaths
--where location like '%United Arab Emirates%'
where continent is not null
Group by Location
order by TotalDeathCount desc


-- Let's break things down by Continents
Select continent,  MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidAnalysis1..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

-- Let's break things down by location 
Select location,  MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidAnalysis1..CovidDeaths
where continent is null
Group by location
order by TotalDeathCount desc

--Showing continents with highest death count per population
Select continent,  MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidAnalysis1..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

--Global numbers
Select date, SUM(new_cases) as new_total_cases ,  SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths  as int))/SUM(new_cases)*100 as DeathPercentage
from CovidAnalysis1..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Total cases and death percentage across the world
Select SUM(new_cases) as new_total_cases ,  SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths  as int))/SUM(new_cases)*100 as DeathPercentage
from CovidAnalysis1..CovidDeaths
where continent is not null
--Group by date
order by 1,2


--Looking at popultion and vaccination 
select *
from CovidAnalysis1..CovidDeaths dea
join CovidAnalysis1..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

--Looking at total population VS Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From  CovidAnalysis1..CovidDeaths dea
join CovidAnalysis1..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

--Looking at total population VS Vaccinations partitioning by location
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (partition by dea.Location order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From  CovidAnalysis1..CovidDeaths dea
join CovidAnalysis1..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Use CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (partition by dea.Location order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From  CovidAnalysis1..CovidDeaths dea
join CovidAnalysis1..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *,(RollingPeopleVaccinated/population)*100
from PopvsVac

--Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (partition by dea.Location order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From  CovidAnalysis1..CovidDeaths dea
join CovidAnalysis1..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated 

--Creating View to store data for later visualization
create view PercentPopulationVaccinated AS
Select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (partition by dea.Location order by dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
From  CovidAnalysis1..CovidDeaths dea
join CovidAnalysis1..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
--order by 2,3
