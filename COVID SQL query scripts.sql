
--Select data that is going to be used

SELECT location, date, population, total_cases, new_cases, total_deaths, continent, new_cases
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Total Cases vs Total Deaths
--Shows likelihood of dying if contracted covid in SG

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
ORDER BY 1,2

--Total Cases vs Population
--Shows percentage of population infected with covid

Select location, date, population, total_cases, (total_cases/population)*100 AS PopulationInfectedPercent
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Singapore'
ORDER BY 1,2

--Countries with highest infection rate compared to population

Select location, population, MAX(total_cases) AS LatestInfectionCount, (MAX(total_cases/population))*100 AS PopulationInfectedPercent
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PopulationInfectedPercent DESC

--Countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Total Deaths VS Population
--Countries with the highest death percentage per population
SELECT location, population, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount, (MAX(CAST(total_deaths AS INT))/population)*100 AS PopulationDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PopulationDeathPercentage DESC


--BREAKING THINGS DOWN BY CONTINENT

--Showing continents with the highest death count per population

Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
order by TotalDeathCount desc

--GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Using CTE to perform calculation to find out percentage of people vaccinated per country population from previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, TotalPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3
)
SELECT *, (TotalPeopleVaccinated/Population) AS PercentageVaccinated
From PopvsVac

--Using Temp Table to find out percentage of people vaccinated per continent

DROP TABLE IF EXISTS #PercentContinentVaccinated
Create Table #PercentContinentVaccinated
(
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
PeopleVaccinatedInContinent numeric
)

INSERT INTO #PercentContinentVaccinated
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinatedInContinent
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NULL
ORDER BY 1

SELECT *, (PeopleVaccinatedInContinent/Population)*100 AS PercentageVacInContinent
FROM #PercentContinentVaccinated
--WHERE New_Vaccinations IS NOT NULL



--Creating View to store data for later visualisations

CREATE VIEW VaccinatedStatsByContinent AS
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinatedInContinent
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NULL

CREATE VIEW VaccinatedStatsByCountry AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL