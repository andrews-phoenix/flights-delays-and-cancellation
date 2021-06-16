--
-- PostgreSQL database dump
--

-- Dumped from database version 12.5
-- Dumped by pg_dump version 13.3

-- Started on 2021-06-14 19:54:05

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 202 (class 1259 OID 16402)
-- Name: Airlines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Airlines" (
    id smallint NOT NULL,
    "iataCode" character varying(5) NOT NULL,
    description character varying(50) NOT NULL,
    "departureDelayMean" integer,
    "departureWheelsOffMean" integer
);


ALTER TABLE public."Airlines" OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16444)
-- Name: Airports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Airports" (
    id smallint NOT NULL,
    "iataCode" character varying(5) NOT NULL,
    description character varying(100) NOT NULL,
    "cityId" smallint,
    latitude numeric(10,5),
    longitude numeric(10,5)
);


ALTER TABLE public."Airports" OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16464)
-- Name: CancellationReasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CancellationReasons" (
    id smallint NOT NULL,
    code character(1) NOT NULL,
    description character varying(50)
);


ALTER TABLE public."CancellationReasons" OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 16412)
-- Name: Cities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Cities" (
    id integer NOT NULL,
    description character varying(100) NOT NULL,
    "stateId" smallint NOT NULL
);


ALTER TABLE public."Cities" OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16434)
-- Name: Flights; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Flights" (
    id integer NOT NULL,
    year smallint,
    month smallint,
    day smallint,
    "dayOfWeek" smallint,
    "airlineId" smallint,
    "tailNumber" character varying(10),
    "originAirportId" smallint,
    "destinationAirportId" smallint,
    "scheduleDeparture" time without time zone,
    "departureTime" time without time zone,
    "departureDelay" smallint,
    "taxiOut" smallint,
    "wheelsOff" time without time zone,
    "airTime" smallint,
    distance integer,
    "wheelsOn" time without time zone,
    "taxiIn" smallint,
    "scheduledArrival" time without time zone,
    "arrivalTime" time without time zone,
    "arrivalDelay" smallint,
    diverted boolean NOT NULL,
    cancelled boolean NOT NULL,
    "cancellationReasonId" smallint,
    "airSystemDelay" smallint,
    "securityDelay" smallint,
    "airlineDelay" smallint,
    "lateAircraftDelay" smallint,
    "weatherDelay" smallint,
    "departureTimeMinute" smallint,
    "wheelsOffMinute" smallint,
    "wheelsOnMinute" smallint,
    "arrivalTimeMinute" smallint,
    "scheduleArrivalMinute" smallint,
    "scheduleDepartureMinute" smallint
);


ALTER TABLE public."Flights" OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 16407)
-- Name: States; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."States" (
    id smallint NOT NULL,
    code character varying(5) NOT NULL,
    description character varying(50) NOT NULL
);


ALTER TABLE public."States" OWNER TO postgres;

--
-- TOC entry 3710 (class 2606 OID 16448)
-- Name: Airports Airports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Airports"
    ADD CONSTRAINT "Airports_pkey" PRIMARY KEY (id);


--
-- TOC entry 3712 (class 2606 OID 16468)
-- Name: CancellationReasons CancellationReasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CancellationReasons"
    ADD CONSTRAINT "CancellationReasons_pkey" PRIMARY KEY (id);


--
-- TOC entry 3706 (class 2606 OID 16416)
-- Name: Cities Cities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Cities"
    ADD CONSTRAINT "Cities_pkey" PRIMARY KEY (id);


--
-- TOC entry 3708 (class 2606 OID 16438)
-- Name: Flights Flights_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Flights"
    ADD CONSTRAINT "Flights_pkey" PRIMARY KEY (id);


--
-- TOC entry 3704 (class 2606 OID 16418)
-- Name: States States_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."States"
    ADD CONSTRAINT "States_pkey" PRIMARY KEY (id);


--
-- TOC entry 3702 (class 2606 OID 16424)
-- Name: Airlines airlines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Airlines"
    ADD CONSTRAINT airlines_pkey PRIMARY KEY (id);


--
-- TOC entry 3718 (class 2606 OID 16474)
-- Name: Airports Airports_cityId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Airports"
    ADD CONSTRAINT "Airports_cityId_fkey" FOREIGN KEY ("cityId") REFERENCES public."Cities"(id) ON UPDATE RESTRICT ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 3713 (class 2606 OID 16479)
-- Name: Cities Cities_statesId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Cities"
    ADD CONSTRAINT "Cities_statesId_fkey" FOREIGN KEY ("stateId") REFERENCES public."States"(id) ON UPDATE RESTRICT ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 3714 (class 2606 OID 16484)
-- Name: Flights Flights_airlineId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Flights"
    ADD CONSTRAINT "Flights_airlineId_fkey" FOREIGN KEY ("airlineId") REFERENCES public."Airlines"(id) ON UPDATE RESTRICT ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 3717 (class 2606 OID 16499)
-- Name: Flights Flights_cancellationReasonId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Flights"
    ADD CONSTRAINT "Flights_cancellationReasonId_fkey" FOREIGN KEY ("cancellationReasonId") REFERENCES public."CancellationReasons"(id) ON UPDATE RESTRICT ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 3716 (class 2606 OID 16494)
-- Name: Flights Flights_destinationAirportId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Flights"
    ADD CONSTRAINT "Flights_destinationAirportId_fkey" FOREIGN KEY ("destinationAirportId") REFERENCES public."Airports"(id) ON UPDATE RESTRICT ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 3715 (class 2606 OID 16489)
-- Name: Flights Flights_originAirportId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Flights"
    ADD CONSTRAINT "Flights_originAirportId_fkey" FOREIGN KEY ("originAirportId") REFERENCES public."Airports"(id) ON UPDATE RESTRICT ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 3850 (class 0 OID 0)
-- Dependencies: 3
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM rdsadmin;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2021-06-14 19:54:15

--
-- PostgreSQL database dump complete
--

