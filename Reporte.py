import pandas as pd
import matplotlib.pyplot as plt
import pyodbc

# El nombre de servidor que les aparece al abrir SQL (reemplazar)
server = 'FRANCO'
# El nombre de la base de datos que ya diseñaron (reemplazar)
db = 'DesaparecidosBASE'
# Conexión entre python y SQL
conn = pyodbc.connect("""Driver= {{SQL Server}};Server={0};Database={1};""".format(server,db))

#Repoerte 1
query = """
SELECT departamento_hecho
FROM Desaparicion
WHERE departamento_hecho IS NOT NULL
"""

tabla_completa = pd.read_sql(query, conn)

desap_por_depto = (
    tabla_completa.groupby('departamento_hecho')
                  .size()
                  .sort_values(ascending=False)
)


plt.figure(figsize=(12, 6))
desap_por_depto.plot(kind='bar', color='mediumseagreen')

plt.title('Distribución de Desapariciones por Departamento')
plt.xlabel('Departamento')
plt.ylabel('Número de Desapariciones')
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.show()


# reporte 2 
query = '''
SELECT YEAR(fecha_hecho) AS anio, MONTH(fecha_hecho) AS mes, COUNT(*) AS total
FROM Desaparicion
GROUP BY YEAR(fecha_hecho), MONTH(fecha_hecho)
ORDER BY anio, mes;
'''
df = pd.read_sql(query, conn)
df['fecha'] = pd.to_datetime(df['anio'].astype(str) + '-' + df['mes'].astype(str) + '-01')

plt.figure(figsize=(12,6))
plt.plot(df['fecha'], df['total'], marker='o')
plt.title('Tendencia Mensual de Desapariciones')
plt.xlabel('Fecha')
plt.ylabel('Cantidad de Desapariciones')
plt.grid(True)
plt.tight_layout()
plt.show()


#Reporte 3
query = '''
SELECT tipo_denuncia, COUNT(*) AS cantidad
FROM Denuncia
GROUP BY tipo_denuncia;
'''
df = pd.read_sql(query, conn)

plt.figure(figsize=(8,6))
plt.pie(df['cantidad'], labels=df['tipo_denuncia'], autopct='%1.1f%%', startangle=140)
plt.title('Distribución por Tipo de Denuncia')
plt.axis('equal')
plt.tight_layout()
plt.show()


#Reporte 4
query = '''
SELECT g.grupo_etario, d.situacion_resolucion, COUNT(*) AS cantidad
FROM Desaparicion d
JOIN Persona p ON d.id_persona = p.id_persona
JOIN Grupo_Etario g ON p.id_grupo_etario = g.id_grupo_etario
GROUP BY g.grupo_etario, d.situacion_resolucion;
'''
df = pd.read_sql(query, conn)
pivot_df = df.pivot(index='grupo_etario', columns='situacion_resolucion', values='cantidad').fillna(0)

pivot_df.plot(kind='bar', stacked=True, figsize=(12,6))
plt.title('Casos Resueltos vs Activos por Grupo Etario')
plt.xlabel('Grupo Etario')
plt.ylabel('Cantidad de Casos')
plt.xticks(rotation=45)
plt.legend(title='Situación Resolución')
plt.tight_layout()
plt.show()

conn.close()
