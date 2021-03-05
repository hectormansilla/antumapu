# Proyecto AntuMapu
Sistema de gestión de procesos en IBM Workload Scheduler (IWS) con Tiempo Excedido.

## Comencemos 
Simplemenete clonar este repositorio

## Pre-requisitos
- Microsoft Windows 10 con PowerShell 5.1 o superior [PowerShell](https://docs.microsoft.com/en-us/powershell/)
- Tener instalado Python 3.8 u otra versión superior [Python](https://www.python.org/)
- Tener instalado PostgreSQL 10 u otra versión superior [PostgreSQL](https://www.postgresql.org/)
- Configurar y disponer de archivo .ENV

## Instalación
Instalar las dependencias mediante pip en un entorno virtual VENV

```
pip install -r requirements.txt
```

## Iniciación 
Crear el modelo de datos, ingresando al interprete de Python y en él ingresamos lo siguiente:
```
from proyecto import db
db.create_all()
```

Para ejecutar la aplicación, puedes usar el siguiente comando

```
python antu.py
```

## Construido con
- [flask](https://palletsprojects.com/p/flask/)
- [flask_sqlalchemy](https://github.com/pallets/flask-sqlalchemy)
- [pdfkit](https://github.com/JazzCore/python-pdfkit)
- [Dotenv](https://github.com/theskumar/python-dotenv)

## Autor
- Hector Mansilla 

