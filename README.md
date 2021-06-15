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
## Explorar y evaluar los datos:EDA
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
* Los vuelos cancelados no tienen valores en algunas columnas por que nunca salió, por este motivo, se calcula la media para estos valores.
* La columna de tiempo en el aire del archivo, está mal calculada, por lo tanto se hace el calculo manualmente
* Por ejercicio de la prueba, las columnas calculadas, fueron omitidas al importar, pero se realiza manualmente la inserción de estas columnas con el calculo respectivo

#### Campos con formato (HHMM) str.
* Los campos con este formato, son pasados a otra columna pasandolos a minutos del día. Ejemplo, '0404' es 244.
* Los campos que fueron tomados como insumo fueron:
  * DEPARTURE_TIME
  * WHEELS_OFF
  * WHEELS_ON
  * ARRIVAL_TIME
  * SCHEDULED_ARRIVAL
  * SCHEDULED_DEPARTURE
* Al resultado se de cada campo se le agrego "_MIN" a la nueva columna.
* Se usa la siguiente función para convertir los valores

```python
def convert_str_to_min(str_time):
  '''Convierte tiemplo(str HHMM) en minutos(int)
  '''
  result = 0
  try:
    if len(str_time) == 4:
      result = (int(str_time[:2]) * 60) + int(str_time[2:])
  except:
    result = None
  return result
```
* Se aplica así:
``` python
flights_df['DEPARTURE_TIME_MIN'] = flights_df['DEPARTURE_TIME'].apply(convert_str_to_min)
flights_df['WHEELS_OFF_MIN'] = flights_df['WHEELS_OFF'].apply(convert_str_to_min)
flights_df['WHEELS_ON_MIN'] = flights_df['WHEELS_ON'].apply(convert_str_to_min)
flights_df['ARRIVAL_TIME_MIN'] = flights_df['ARRIVAL_TIME'].apply(convert_str_to_min)
flights_df['SCHEDULED_ARRIVAL_MIN'] = flights_df['SCHEDULED_ARRIVAL'].apply(convert_str_to_min)
flights_df['SCHEDULED_DEPARTURE_MIN'] = flights_df['SCHEDULED_DEPARTURE'].apply(convert_str_to_min)
```
* Los datos incompletos de estas nuevas filas se llenan con la media
``` python
new_columns_minutes = ['DEPARTURE_TIME_MIN','WHEELS_OFF_MIN','WHEELS_ON_MIN','ARRIVAL_TIME_MIN','SCHEDULED_ARRIVAL_MIN','SCHEDULED_DEPARTURE_MIN']
df_mean = flights_df[new_columns_minutes].mean().astype(int)
flights_df.fillna(df_mean,inplace=True)
# Se completa datos nulos de la matricula en desconocido
flights_df.TAIL_NUMBER.fillna('Unknown',inplace=True)
```
#### Datos booleanos incompletos
Los ultimos datos con nulos son en realidad booleanos, que por no haber por ejemplo despachado un avión (cancelado) están vacíos. por tal motivo se pasan completan los valores en 0

#### Crear columnas calculadas
``` python
# Se crean las columnas calculadas usando la respectiva diferentecia entre los valores.
flights_df['DEPARTURE_DELAY'] = flights_df.apply(lambda row: calc_diff_time(row['DEPARTURE_TIME_MIN'], row['SCHEDULED_DEPARTURE_MIN']), axis=1)
flights_df['TAXI_OUT'] = flights_df.apply(lambda row: calc_diff_time(row['WHEELS_OFF_MIN'], row['DEPARTURE_TIME_MIN']), axis=1)
flights_df['AIR_TIME'] = flights_df.apply(lambda row: calc_diff_time(row['WHEELS_ON_MIN'], row['WHEELS_OFF_MIN']), axis=1)
flights_df['TAXI_IN'] = flights_df.apply(lambda row: calc_diff_time(row['ARRIVAL_TIME_MIN'], row['WHEELS_ON_MIN']), axis=1)
flights_df['ARRIVAL_DELAY'] = flights_df.apply(lambda row: calc_diff_time(row['ARRIVAL_TIME_MIN'], row['SCHEDULED_ARRIVAL_MIN']), axis=1)
```
**Importante**: los vuelos pueden haber sido programados a las 23:55 y despachados a las 00:45, por tal motivo y como no tenemos un día de llegada, para comprobar que es otro día. A la diferencia de los datos se verifica si es superior a 23 horas, para lo cual hacemos un ajuste y aplicamos esas horas de diferencia por si es cambio de día.

``` python
def calc_diff_time(min_one, min_two):
  try:
    minutes_to_add = 0
    diff = min_one - min_two
    if(abs(diff) > (1380)): #13 horas
      minutes_to_add = 1440 #24 horas
      if diff > 0:
        diff -= minutes_to_add
      else:
        diff += minutes_to_add
    return diff
  except:
    return 0
``` 

## Analisis preliminar de los datos
Respondiendo algunas preguntas se realizan los siguientes hallazgos:

#### Promedio en minutos de demora en despacho y llegada en cada mes
``` python
df_g = flights_df.groupby('MONTH')[['DEPARTURE_DELAY','ARRIVAL_DELAY']].mean()
# df_m_m.columns['DEPARTURE_DELAY_AVG','DEPARTURE_DELAY_AVG','ARRIVAL_DELAY']
df_g.index = month
df_g.plot(kind='bar', legend=True, xlabel='Meses', ylabel='Valores',title ='Meses con retraso')
plt.legend(["Retraso al despachar", "Retraso en llegada"]);
```
## Insertar imagen

#### Top 10 de los aerolineas con salidas más demoradas
``` python
airlines = flights_df.groupby('AIRLINE')[['DEPARTURE_DELAY']].mean()
airlines.sort_values('DEPARTURE_DELAY',ascending=False).head(10)
```

#### Aeronaves con más retraso
``` python
df_t_n = flights_df.groupby('TAIL_NUMBER')[['DEPARTURE_DELAY']].mean()
df_t_n.sort_values('DEPARTURE_DELAY',ascending=False)[:10]
```

#### Motivos de cancelación
``` python
df_can_reasons = flights_df[flights_df['CANCELLATION_REASON'] != 0].groupby('CANCELLATION_REASON')[['CANCELLATION_REASON']].count()
df_can_reasons.columns = ['SUM']
fig, axes = plt.subplots(1, 2, figsize=(15,5))
df_can_reasons['SUM'].plot.pie(ax=axes[0], autopct="%.2f", title='Razones de cancelación')
df_can_reasons['SUM'].plot(ax=axes[1], kind="bar", title='Razones de cancelación')
```
#### Cantidad de vuelos cancelados por aerolinea
``` python
df_can_airline = flights_df[flights_df['CANCELLED'] == 1].groupby('AIRLINE').sum()[['CANCELLED']].sort_values(['CANCELLED'], ascending =False)
df_can_airline.head(10)
```

#### Cantidad de vuelos cancelados por aerolinea comparado con la cantidad de vuelos
``` python
df_sum_airline = flights_df.groupby('AIRLINE')[['YEAR']].sum()
df_can_sum_airline = pd.merge(df_can_airline, df_sum_airline, on='AIRLINE')
df_can_sum_airline['PERCENT'] = (df_can_sum_airline['CANCELLED'] / df_can_sum_airline['YEAR'] )*100
df_can_sum_airline.sort_values('PERCENT', ascending=False).head(10)
```

#### Acumulado de en minutos de los motivos de retraso
``` python
categories_delay = ["Sistema aéro", "Seguridad","Aerolinea","Tráfico aéreo","Clima"]
fig, axes = plt.subplots(1, 2, figsize=(15,5))
df_delay_reasons_all = flights_df[['MONTH','AIR_SYSTEM_DELAY','SECURITY_DELAY', 'AIRLINE_DELAY', 'LATE_AIRCRAFT_DELAY','WEATHER_DELAY']]
df_delay_reasons_month = df_delay_reasons_all.groupby('MONTH').sum()
df_delay_reasons_month.index = month
df_delay_reasons_month.plot(ax=axes[0], kind='bar',stacked=True, xlabel='Meses', title='Minutos acumulados por retraso por meses', figsize=(15, 6))
df_delay_reasons = df_delay_reasons_all[['AIR_SYSTEM_DELAY','SECURITY_DELAY', 'AIRLINE_DELAY', 'LATE_AIRCRAFT_DELAY','WEATHER_DELAY']].sum().to_frame()
df_delay_reasons.index = categories_delay
df_delay_reasons.plot(ax=axes[1], kind='bar',stacked=True, xlabel='Meses', legend=False,title='Minutos acumulados por retraso', figsize=(15, 6))
axes[0].legend(categories_delay)
```

## Definición del modelo de datos
***
#### Modelo de datos
Se una SQL por facilidad y garantiza la integralidad de los datos
INSERTAR IMAGEN

### Arquitectura
Insertar arquitectura

### Herramientas y Tenologías

#### [AWS S3](https://aws.amazon.com/es/s3/)
Almacenamiento a bajo costo en la nube que ofrece escalabilidad, disponibilidad de datos, seguridad y rendimiento. Se usa para almacenar las fuentes de datos

#### [AWS EC2](https://aws.amazon.com/es/ec2/)
Servicio de computación en la nube de capacidad informatica de forma segura. Entre sus ventajas es la capacidad de escalar y modificar las instancias con facilidad según sus necesidades. Se usa para hacer ejecutar la ETL.

#### [AWS RDS](https://aws.amazon.com/rds/)
Servicio web de base de datos relación de alta disponibilidad y de fácil configuración. Se usa para la base de datos en PostgreSQL

#### [Apache Airflow](https://airflow.apache.org/)
Es una erramienta de planificación y automatización de flujos de trabajo de gran conocimiento y respaldo en la industria de los datos y python. Implementación pendiente en EC2.

#### [Python](https://example.com): Version 3.9
Lenguaje de programación de fácil adopción, con muchas librerías para manipulación de datos.

### Frecuencia de actualización de datos
Teniendo en cuenta que es para analisis de identificar las razones de demora en todo el proceso del vuelo, además que los datos son del 2015, se sugiere lo siguiente:
* Ingresar los datos hasta el año anterior, para tener información más reciente y comparar los datos a lo largo de los años.
* En el año en curso, se sugiere por lo menos actualizar una vez al mes los datos de los vuelos del mes inmediatamente anterior.

## Ejecutar ETL

La ETL por facilidad se puede visualizar en el siguiente archivo jupyter con sus respectivos comentarios. De igual manera parte de esta información está en [Explorar y evaluar los datos EDA](#explorar-y-evaluar-los-datos:eda))
INSERTAR ACA
[ETL](https:link)

### Modelo de datos

La manipulación de los datos se puede consultar en el [Explorar y evaluar los datos EDA](#explorar-y-evaluar-los-datos:eda))

La integridad de los datos se manejan respetando la llaves unicas previamente almacenadas en orden en las tablas respetivas.
Así mismo las tablas que dependan de otra tabla, por seguridad se descarga los datos de la tabla dependiente, para luego hacer un merge con la nueva información a insertar

Por ese motivo los datos ingresados a la DB solo pueden ser ingresados si respetan la integridad de los datos. Es fue una de las razones para decidir por un modelo SQL.
Insertar imagen del model o olink del modelo

### Diccionario de datos
insertar diccionario de datos aca

