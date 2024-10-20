import json
import requests

# URL de la solicitud GET
url = 'https://devchuz-llm-image.hf.space/check'

# Encabezados
headers = {
    'accept': 'application/json'
}

def lambda_handler(event, context):
    try:
        # Hacer la solicitud GET a la API externa
        response = requests.get(url, headers=headers)

        # Verificar si la solicitud fue exitosa
        if response.status_code == 200:
            # Devolver la respuesta de la API
            return {
                'statusCode': 200,
                'body': json.dumps(response.json())  # Convertir la respuesta a JSON
            }
        else:
            # Manejar errores en la solicitud
            return {
                'statusCode': response.status_code,
                'body': json.dumps(f"Error en la solicitud: {response.text}")
            }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error interno: {str(e)}")
        }
