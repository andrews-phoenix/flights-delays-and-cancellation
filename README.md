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
    * states.txt: Estraido manualmente
 * Transformación propia
    * airports.json: conversión del archivo airports.csv como se explica más adelante

```python
import pandas as pd
file = pd.read_csv('./data/airports.csv')
file.to_json('./data/airpots.json')
```
