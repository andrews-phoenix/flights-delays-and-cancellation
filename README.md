# flights-delays-and-cancellation
Prueba Técnica de Ingeniero de Datos en Nequi

## Objetivo del proyecto
Identificar las posibles causas de los retrasos en los vuelos en Estados Unidos en el año 2015 además de identificar la relación de vuelos cancelados con los retrasados.

## Solución
Usar técnologías en la nube (AWS) para centrarlizar la información en un modelo de datos estructurado, además de tablas con datos previamente solicitados por BI.


## Fuente de datos 
* [2015 Flight Delays and Cancellations](https://www.kaggle.com/usdot/flight-delays/)
    * airlines.csv: Original
    * airports.csv: Original
    * flights.csv:  Original
 * [Wikipedia](https://es.wikipedia.org/wiki/Anexo:Abreviaciones_de_los_estados_de_Estados_Unidos)
    * states.txt: Extraido manualmente
 * Transformación propia
    * airports.json: conversión del archivo airports.csv como se explica más adelante

Puede consultar los datos compartidos en este [drive](https://drive.google.com/drive/folders/1dRNSc5XSLACIEbo6Nudxw25gtE6iMHH_?usp=sharing)

```python
import pandas as pd
file = pd.read_csv('./data/airports.csv')
file.to_json('./data/airpots.json')
```
## Explorar y evaluar los datos:EDA
Para mayor información se puede remitir al siguiente [archivo jupyter](/pythonCode/pythonCode/eda_nequi_flights.ipynb)
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
![Alt text](/img/delay-months.JPG?raw=true)
![Alt text](/img/delay-months-2.JPG?raw=true)

#### Top 10 de los aerolineas con salidas más demoradas
``` python
airlines = flights_df.groupby('AIRLINE')[['DEPARTURE_DELAY']].mean()
airlines.sort_values('DEPARTURE_DELAY',ascending=False).head(10)
```
![Alt text](/img/departure_delay_airline.JPG?raw=true)

#### Aeronaves con más retraso
``` python
df_t_n = flights_df.groupby('TAIL_NUMBER')[['DEPARTURE_DELAY']].mean()
df_t_n.sort_values('DEPARTURE_DELAY',ascending=False)[:10]
```
![Alt text](/img/departure_delay_tail_number.JPG?raw=true)

#### Motivos de cancelación
``` python
df_can_reasons = flights_df[flights_df['CANCELLATION_REASON'] != 0].groupby('CANCELLATION_REASON')[['CANCELLATION_REASON']].count()
df_can_reasons.columns = ['SUM']
fig, axes = plt.subplots(1, 2, figsize=(15,5))
df_can_reasons['SUM'].plot.pie(ax=axes[0], autopct="%.2f", title='Razones de cancelación')
df_can_reasons['SUM'].plot(ax=axes[1], kind="bar", title='Razones de cancelación')
```
![Alt text](/img/cancellation_reasons.JPG?raw=true)

#### Cantidad de vuelos cancelados por aerolinea
``` python
df_can_airline = flights_df[flights_df['CANCELLED'] == 1].groupby('AIRLINE').sum()[['CANCELLED']].sort_values(['CANCELLED'], ascending =False)
df_can_airline.head(10)
```
![Alt text](/img/cancelled_airlines.JPG?raw=true)

#### Cantidad de vuelos cancelados por aerolinea comparado con la cantidad de vuelos
``` python
df_sum_airline = flights_df.groupby('AIRLINE')[['YEAR']].sum()
df_can_sum_airline = pd.merge(df_can_airline, df_sum_airline, on='AIRLINE')
df_can_sum_airline['PERCENT'] = (df_can_sum_airline['CANCELLED'] / df_can_sum_airline['YEAR'] )*100
df_can_sum_airline.sort_values('PERCENT', ascending=False).head(10)
```
![Alt text](/img/cancelled_airlines_2.JPG?raw=true)

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
![Alt text](/img/delay_min_sum.JPG?raw=true)

## Definición del modelo de datos
***
#### Modelo de datos
Se una SQL por facilidad y garantiza la integralidad de los datos.
Así mismo las tablas que dependan de otra tabla, por seguridad se descarga los datos de la tabla dependiente, para luego hacer un merge con la nueva información a insertar
Por ese motivo los datos ingresados a la DB solo pueden ser ingresados si respetan la integridad de los datos. Es fue una de las razones para decidir por un modelo SQL.

##### MER
![Alt text](/img/nequi-flights-mer.jpg?raw=true)

##### Diccionario de datos
![Alt text](/img/data-dictionary.JPG?raw=true)

### Arquitectura
![Alt text](/img/AWS.jpg?raw=true)
![Alt text](/img/aws2.jpg?raw=true)

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

La ETL por facilidad se puede visualizar en el siguiente [archivo jupyter](/pythonCode/etl_nequi_flights.ipynb) con sus respectivos comentarios.

De igual manera parte la primera parte de importar los datos y completar columnas en [Explorar y evaluar los datos EDA](#explorar-y-evaluar-los-datoseda))

### Estados
Importamos los datos
``` python
cols = ['code','description']
states_obj = s3_s.get_object(Bucket='test-nequi-data-engineer-amga', Key='data/states.txt')
states_df = pd.read_csv(states_obj['Body'], header=None, names=cols)
```

Declaramos una función para obterner los códigos o estados aplicando expresiones regulares
``` python
def regex_to_states(text,colname):
    '''Función para obtener el código o nombre del estado
    '''
    if colname == 'code':
        regex = '\((.+?)\)'
        groupToGet = 1
    else:
        regex = '^(\w|\s)+'
        groupToGet = 0
    return re.search(regex, text).group(groupToGet).strip()
``` 
Obtenemos las columnas, las unidos y eliminamos los duplicados, para ser insertados.
``` python
# obtenemos las dos columnas
codes = states_df.apply(
    lambda row: regex_to_states(row['code'],'code'),axis=1
)
names = states_df.apply(
    lambda row: regex_to_states(row['code'],'description'),axis=1
)
 
states_df_process = pd.concat([codes, names],axis=1)
# dejamos las columnas con el mismo nombre en la db
states_df_process.columns = cols

# elimina duplicados
states_df_process.drop_duplicates(inplace=True)

# se completa el campo id
tates_ids = np.arange(1,len(states_df_process)+1)
states_df_to_insert=states_df_process.copy()
states_df_to_insert['id'] = states_ids
# Se insertan los datos
states_df_to_insert.to_sql("States", db_engine, schema="public", if_exists='append', method='multi', index=False)
``` 

### Aerolineas
Este archivo funcionan de la misma manera que el anterior, solo que con el archivo de airlines.

``` python
# lee
airlines_obj = s3_s.get_object(Bucket='test-nequi-data-engineer-amga', Key='data/airlines.csv')
airlines_df = pd.read_csv(airlines_obj['Body'])

# transforma
airlines_ids = np.arange(1,len(airlines_df)+1)
airlines_df
airlines_df_to_insert=airlines_df.copy()
airlines_df_to_insert.columns = ['iataCode','description']
airlines_df_to_insert['id'] = airlines_ids

# carga
airlines_df_to_insert.to_sql("Airlines", db_engine, schema="public", if_exists='append', method='multi', index=False)
```

### Aeropuertos y Ciudades
Estos datos son tomados del archivo de aeropuertos y se insertan en las respectivas tablas.
**Importante**: En el caso de ciudades tiene relación con la tabla de estados, por tal motivo existe una linea para leer los datos de esta tabla y cruzarla con merge.
Para leer las tablas se crea la siguiente función:
``` python
# Function to extract table to a pandas DataFrame
def extract_table_to_pandas(tablename, db_engine,columnnames='*'):
    query = 'SELECT {} FROM "{}"'.format(columnnames, tablename)
    return pd.read_sql(query, db_engine)
``` 

##### Ciudades
``` python
# lee
airports_obj = s3_s.get_object(Bucket='test-nequi-data-engineer-amga', Key='data/airports.json')
airports_df = pd.read_json(airports_obj['Body'])

#### Ciudad
# obtenemos los id de los estados.
states_sql_df = extract_table_to_pandas('States',db_engine,'*')

# transforma
cities_df_to_insert = states_sql_df.merge(cities_df, left_on='code', right_on='STATE')
cities_df_to_insert
cities_df_to_insert = cities_df_to_insert[['id','CITY']]
cities_df_to_insert.columns = ['stateId','description']
ids = np.arange(1,len(cities_df_to_insert)+1)
cities_df_to_insert['id'] = ids

# carga
cities_df_to_insert.to_sql("Cities", db_engine, schema="public", if_exists='append', method='multi', index=False)
``` 

##### Aeropuertos
``` python
# obtenemos con query personalizado los datos insertados para cruzar de las tablas cities y states
query = 'select c.id as cityId, c.description as city, S.code as state from "Cities" as c inner join "States" as S ON c."stateId" = S.id'
cities_sql_df = pd.read_sql(query, db_engine)

# transforma
airports_df_to_insert = cities_sql_df.merge(airports_df, left_on=['city','state'], right_on=['CITY','STATE'], how='right')
airports_df_to_insert.dropna(inplace=True)
airports_df_to_insert.reset_index(inplace=True, drop=True)
airports_df_to_insert.cityid = airports_df_to_insert.cityid.astype(int)
airports_df_to_insert = airports_df_to_insert[['IATA_CODE','AIRPORT','cityid','LATITUDE','LONGITUDE']]
airports_df_to_insert.columns = ['iataCode','description','cityId','latitude','longitude']
ids = np.arange(1,len(airports_df_to_insert)+1)
airports_df_to_insert['id'] = ids

# carga
airports_df_to_insert.to_sql("Airports", db_engine, schema="public", if_exists='append', method='multi', index=False)
``` 

### Vuelos
Por practicidad, la transformación de completar datos y columnas nuevas, se pueden evidenciar en [Explorar y evaluar los datos EDA](#explorar-y-evaluar-los-datoseda)).
Por lo anterior, se explica la transformación de los datos según los id de las tablas previamentes insertadas.
**Importante:** Por la cantidad de datos, se procede a leer el archivo por partes, así:

``` python
flights_obj = s3_s.get_object(Bucket='test-nequi-data-engineer-amga', Key='data/flights.csv')

for flights_df in pd.read_csv(flights_obj['Body'], chunksize=flight_chunksize, usecols=cols_to_use, dtype=dtype_flights):
    # lineas de transformación y cargue de la información
```

Hay unas constantes, que se dejan por fuera del for para evitar calculos innecesarios
``` python
flight_chunksize = 5000
dtype_flights = {"DEPARTURE_TIME" : str, "WHEELS_OFF": str, "WHEELS_ON":str, "ARRIVAL_TIME":str, "SCHEDULED_ARRIVAL":str, "SCHEDULED_DEPARTURE": str}
cols_to_use = ["YEAR", "MONTH", "DAY", "DAY_OF_WEEK", "AIRLINE", "TAIL_NUMBER", "ORIGIN_AIRPORT", "DESTINATION_AIRPORT", "SCHEDULED_DEPARTURE", "DEPARTURE_TIME", "WHEELS_OFF", "DISTANCE", "WHEELS_ON", "SCHEDULED_ARRIVAL", "ARRIVAL_TIME", "DIVERTED", "CANCELLED", "CANCELLATION_REASON", "AIR_SYSTEM_DELAY", "SECURITY_DELAY", "AIRLINE_DELAY", "LATE_AIRCRAFT_DELAY", "WEATHER_DELAY"]

# Obtenemos información almacenada previamente en la DB para cambiarlas por su respectivo id más adelante
airpots_sql_df = extract_table_to_pandas('Airports',db_engine,'"id" as airportId, "iataCode" ')
airlines_sql_df = extract_table_to_pandas('Airlines',db_engine,'"id" as airline_id, "iataCode" ')
cancel_reasons_sql_df = extract_table_to_pandas('CancellationReasons',db_engine,'"id" as cancel_id, "code" as cancel_code')

cols_to_get = ['YEAR','MONTH','DAY','DAY_OF_WEEK','AIRLINE','TAIL_NUMBER','ORIGIN_AIRPORT','DESTINATION_AIRPORT',
              'SCHEDULED_DEPARTURE','DEPARTURE_TIME','DEPARTURE_DELAY','TAXI_OUT','WHEELS_OFF','AIR_TIME','DISTANCE',
              'WHEELS_ON','TAXI_IN','SCHEDULED_ARRIVAL','ARRIVAL_TIME','ARRIVAL_DELAY','DIVERTED','CANCELLED','CANCELLATION_REASON',
              'AIR_SYSTEM_DELAY','SECURITY_DELAY','AIRLINE_DELAY','LATE_AIRCRAFT_DELAY','WEATHER_DELAY','DEPARTURE_TIME_MIN',
              'WHEELS_OFF_MIN','WHEELS_ON_MIN','ARRIVAL_TIME_MIN','SCHEDULED_ARRIVAL_MIN','SCHEDULED_DEPARTURE_MIN']

# variable que tiene el nombre de las columnas reales para trabajar en la db
cols_name_real = ['year','month','day','dayOfWeek','airlineId','tailNumber','originAirportId','destinationAirportId','scheduleDeparture','departureTime','departureDelay','taxiOut','wheelsOff','airTime','distance','wheelsOn','taxiIn','scheduledArrival','arrivalTime','arrivalDelay','diverted','cancelled','cancellationReasonId','airSystemDelay','securityDelay','airlineDelay','lateAircraftDelay','weatherDelay','departureTimeMinute','wheelsOffMinute','wheelsOnMinute','arrivalTimeMinute','scheduleArrivalMinute','scheduleDepartureMinute']
# nuevas columnas que son las hora pasadas a minutos
new_columns_minutes = ['DEPARTURE_TIME_MIN','WHEELS_OFF_MIN','WHEELS_ON_MIN','ARRIVAL_TIME_MIN','SCHEDULED_ARRIVAL_MIN','SCHEDULED_DEPARTURE_MIN']

# Creamos el diccionario para cambiar el dtype a los datos al insertar al db
# primero unos booleanos
dtypes_to_insert_flights = {"diverted": sqlalchemy.types.Boolean(), "cancelled" : sqlalchemy.types.Boolean()}
# segundo son varios en smallint, por lo tanto se hace dinamico
dtype_int_lst = ['airSystemDelay','securityDelay','airlineDelay','lateAircraftDelay','weatherDelay','departureTimeMinute','wheelsOffMinute','wheelsOnMinute','arrivalDelay','taxiIn','departureDelay','taxiOut','airTime']
dtype_int = {name: sqlalchemy.types.SmallInteger() for name in dtype_int_lst}
# se integra en un solo diccionario
dtypes_to_insert_flights.update(dtype_int)
```

Despues de obtener y completar las posibles columnas, pasamos a formar el dataframe que será insertado, seleccionando las columnas, cambiando nombres y merge con los dataframes que vienen de la DB.
``` python
# Tomamos las columnas que se requieren para insertar
  flights_df_to_insert = flights_df[cols_to_get]
  # Se cambian los nombres para igualarlos al de la DB
  flights_df_to_insert.columns = cols_name_real
  # se cambian de formato algunas columnas para hacer merge correctamente
  flights_df_to_insert['originAirportId']= flights_df_to_insert['originAirportId'].astype(str)
  flights_df_to_insert['destinationAirportId']= flights_df_to_insert['destinationAirportId'].astype(str)
  flights_df_to_insert['airlineId']= flights_df_to_insert['airlineId'].astype(str)

  # ingresa remplaza los datos de aeropuerto de origen
  flights_df_temp = flights_df_to_insert.reset_index().merge(airpots_sql_df, left_on=['originAirportId'], right_on=['iataCode']).set_index('index')
  flights_df_temp['originAirportId']=flights_df_temp['airportid']
  flights_df_temp.drop(['airportid','iataCode'], axis=1, inplace=True)

  # ingresa remplaza los datos de aeropuerto de destino
  flights_df_temp = flights_df_temp.reset_index().merge(airpots_sql_df, left_on=['destinationAirportId'], right_on=['iataCode']).set_index('index')
  flights_df_temp['destinationAirportId']=flights_df_temp['airportid']
  flights_df_temp.drop(['airportid','iataCode'], axis=1, inplace=True)

  # ingresa remplaza los datos de aerolinea
  flights_df_temp = flights_df_temp.reset_index().merge(airlines_sql_df, left_on=['airlineId'], right_on=['iataCode']).set_index('index')
  flights_df_temp['airlineId']=flights_df_temp['airline_id']
  flights_df_temp.drop(['airline_id','iataCode'], axis=1, inplace=True)

  # ingresa remplaza los datos de motivos de cancelación
  flights_df_temp.cancellationReasonId.replace({0: "N"}, inplace=True)
  flights_df_temp = flights_df_temp.reset_index().merge(cancel_reasons_sql_df, left_on=['cancellationReasonId'], right_on=['cancel_code']).set_index('index')
  flights_df_temp['cancellationReasonId']=flights_df_temp['cancel_id']
  flights_df_temp.drop(['cancel_id','cancel_code'], axis=1, inplace=True)
  flights_df_temp.sort_index(inplace=True)

  # Se calcula la columna id
  ids = np.arange(max_id + 1,len(flights_df_temp) + max_id + 1)
  flights_df_temp['id'] = ids
  max_id += len(flights_df_temp)

  # finalmente inserta la información
  flights_df_temp.to_sql("Flights", db_engine, schema="public", if_exists='append', method='multi', index=False, dtype=dtypes_to_insert_flights)
``` 


## Escenarios propuestos: 
### 1. Si los datos se incrementaran en 100x.

Migrar a servicios especializados ofrecidos por AWS
* ETL: Cambiar la ejecución en EC2 y usar GLUE, especialmente diseñado para ese proposito y olvidarnos de la infraestructura que conlleva una EC2
* DB: En caso de seguir con un modelo relacional, es recomendable migrar de PostgreSQL a Aurora. Es fácil emigrar y ofrece hasta 3 veces la velocidad que PostgreSQL.

### 2. Si las tuberías se ejecutaran diariamente en una ventana de tiempo especifica.
Se debe tener en cuenta programar la ejecución en horas previas a su neesidad de disponiblidad. Si el tiempo no es suficiente, se debe hacer los ajustes necesarios como ajustar la hora de ejecución, y eliminar cuellos de botella (optimizar ETL, clusters ,migrar a servicios más especializados y con más rendimiento)

### 3. Si la base de datos necesitara ser accedido por más de 100 usuarios funcionales.
100 usuarios funcionales para solo consulta, no se me hace dificil si las consultas están correctamente realizadas. sin embargo, se puede revisar:
* Crear replicas de la DB, con el fin de soportar la cantidad de consultas.
* Revisar capacidad de procesamiento del servidor de base de datos.
* Optimizar consultas, y por ejemplo los datos calculados pueden ser ingresados por la ETL, para solo ser consultados y no cargar innecesariamente con funciones.
* Migrar de motor a Aurora por ejemplo 

### 4. Si se requiere hacer analítica en tiempo real, ¿cuales componentes cambiaria a su arquitectura propuesta?

En el modelo se integraría [AWS KINESIS](https://aws.amazon.com/es/kinesis/) para captura, prosecamiento y analisis en tiempo real.

El motor de base de datos sebe ser migrado a REDSHIFT si se maneja de forma relacional. de lo contrario a DinamoDB.


## Muchas gracias.

Andres Godoy
