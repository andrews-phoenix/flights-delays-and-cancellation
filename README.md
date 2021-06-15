# flights-delays-and-cancellation
Prueba Técnica de Ingeniero de Datos en Nequi

## Objetivo del proyecto
Identificar las posibles causas de los retrasos en los vuelos en Estados Unidos en el año 2015 además de identificar la relación de vuelos cancelados con los retrasados.

## Solución
Usar técnologías en la nube (AWS) para centrarlizar la información en un modelo de datos estructurado, además de tablas con datos previamente solicitados por BI.

## Tecnologías
***
A list of technologies used within the project:
* [AWS S3](https://aws.amazon.com/es/s3/)
* [AWS EC2](https://aws.amazon.com/es/ec2/)
* [AWS RDS](https://aws.amazon.com/rds/)
* [Apache Airflow](https://airflow.apache.org/)
* [Python](https://example.com): Version 3.9

 ## Fuente de datos 
 * [2015 Flight Delays and Cancellations](https://www.kaggle.com/usdot/flight-delays/)
    * airlines.csv: Original
    * airports.csv: Original
    * flights.csv:  Original
 * [Wikipedia](https://es.wikipedia.org/wiki/Anexo:Abreviaciones_de_los_estados_de_Estados_Unidos)
    * states.txt: Extraido manualmente
 * Transformación propia
    * airports.json: conversión del archivo airports.csv como se explica más adelante

```python
import pandas as pd
file = pd.read_csv('./data/airports.csv')
file.to_json('./data/airpots.json')
```
## Explorar y evaluar los datos (EDA)
Al importar se identifican y se corrigen los siguientes problemas al importar los datos:
### Tipo de dato en columnas y columnas innecesarias
* Algunas columnas tenían el formato HHMM para la hora, pero al importar se cambia el dtype para str, para que no se pierdan datos
* se especifican las columnas a obtener, tenieendo en cuenta que algunas columnas son calculadas, pero no son correctas, como AIR_TIME, por lo cual se omiten algunas por que no aportan o porque no son correctas.
```python
dtype_flights = {"DEPARTURE_TIME" : str, 
                 "WHEELS_OFF": str,
                 "WHEELS_ON":str,
                 "ARRIVAL_TIME":str,
                 "SCHEDULED_ARRIVAL":str,
                 "SCHEDULED_DEPARTURE": str}
                 
cols_to_use = ["YEAR", "MONTH", "DAY", "DAY_OF_WEEK", "AIRLINE", "TAIL_NUMBER", "ORIGIN_AIRPORT", "DESTINATION_AIRPORT", "SCHEDULED_DEPARTURE", "DEPARTURE_TIME", "WHEELS_OFF", "DISTANCE", "WHEELS_ON", "SCHEDULED_ARRIVAL", "ARRIVAL_TIME", "DIVERTED", "CANCELLED", "CANCELLATION_REASON", "AIR_SYSTEM_DELAY", "SECURITY_DELAY", "AIRLINE_DELAY", "LATE_AIRCRAFT_DELAY", "WEATHER_DELAY"]

flights_df = pd.read_csv(pathflights, usecols=cols_to_use, dtype=dtype_flights)
```
### Completar valores incompletos
* los vuelos cancelados no tienen valores en algunas columnas por que nunca salió, por este motivo, se calcula la media para estos valores.
