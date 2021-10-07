USE [covid-19]

SELECT * FROM [covid-death]
ORDER BY 3, 4

-- SELECT * FROM dbo.[covid-vaccine]

SELECT location, date, total_cases, total_deaths, population
FROM [covid-death]
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- Shows Likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, 
(total_deaths/total_cases) * 100 AS DeathPercentage
FROM [covid-death] WHERE location like '%Bangladesh%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid 

SELECT location, date, Population, total_cases, 
(total_cases/population) * 100 AS PercentPopulationInfected
FROM [covid-death]
order by 1, 2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM [covid-death]
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [covid-death]
-- WHERE location like ''
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY TotalDeathCount desc


-- Breaking Things Down By Continent

-- The continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [covid-death]
WHERE continent IS NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount desc

	-- Continent by location
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [covid-death]
WHERE continent IS NULL
GROUP BY location 
ORDER BY TotalDeathCount desc


-- Golbal numbers per day

SELECT SUM (new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
		SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [covid-death]
WHERE continent IS NOT NULL 
-- AND total_cases IS NOT NULL
-- AND total_deaths IS NOT NULL

-- GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
-- The percentage of population that has recieved at least one covid vaccine

SELECT deathTable.continent, deathTable.location, deathTable.date, deathTable.population,
		vaccineTable.new_vaccinations, SUM(CONVERT(int, vaccineTable.new_vaccinations)) OVER (PARTITION BY deathTable.location 
			ORDER BY deathTable.date) as RollingPeopleVaccinated
FROM [covid-death] deathTable
JOIN [covid-vaccine] vaccineTable
		ON deathTable.location = vaccineTable.location
		AND deathTable.date = vaccineTable.date
WHERE deathTable.continent IS NOT NULL
ORDER BY 2, 3
	

-- Using CTE (Common Table Expression) to perform calculation on partition by in previous query

With TempDeath (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
as 
(
SELECT deathTable.continent, deathTable.location, deathTable.date, deathTable.population,
		vaccineTable.new_vaccinations, SUM(CONVERT(int, vaccineTable.new_vaccinations)) OVER (PARTITION BY deathTable.location 
			ORDER BY deathTable.date) as RollingPeopleVaccinated
FROM [covid-death] deathTable
JOIN [covid-vaccine] vaccineTable
		ON deathTable.location = vaccineTable.location
		AND deathTable.date = vaccineTable.date
WHERE deathTable.continent IS NOT NULL
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageOfVaccinated
FROM TempDeath

-- Using temp table to perform calculation on partition by previous query
-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT deathTable.continent, deathTable.location, deathTable.date, deathTable.population,
		vaccineTable.new_vaccinations, SUM(CONVERT(int, vaccineTable.new_vaccinations)) OVER (PARTITION BY deathTable.location 
			ORDER BY deathTable.date) as RollingPeopleVaccinated
FROM [covid-death] deathTable
JOIN [covid-vaccine] vaccineTable
		ON deathTable.location = vaccineTable.location
		AND deathTable.date = vaccineTable.date
WHERE deathTable.continent IS NOT NULL
-- ORDER BY 2, 3 

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageOfVaccinated
FROM #PercentPopulationVaccinated

-- The View to store data for later visualiations

CREATE VIEW PercentPopulationVaccinated AS
SELECT deathTable.continent, deathTable.location, deathTable.date, deathTable.population,
		vaccineTable.new_vaccinations, SUM(CONVERT(int, vaccineTable.new_vaccinations)) OVER (PARTITION BY deathTable.location 
			ORDER BY deathTable.date) as RollingPeopleVaccinated
FROM [covid-death] deathTable
JOIN [covid-vaccine] vaccineTable
		ON deathTable.location = vaccineTable.location
		AND deathTable.date = vaccineTable.date
WHERE deathTable.continent IS NOT NULL