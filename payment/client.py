import http.client
import json
import logging
from django.conf import settings
from order.models import OrderItems

# Configurar o logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MercadoPagoService:
    def __init__(self):
        self.access_token = settings.MERCADO_PAGO_ACCESS_TOKEN
        logger.info('MercadoPagoService initialized with access token.')

    def create_qr_code(self, order):
        logger.info(f'Starting QR code creation for order ID: {order.id}')
        connection = http.client.HTTPSConnection("api.mercadopago.com")
        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }

        # Construir a lista de itens para o payload
        items = []
        for order_item in OrderItems.objects.filter(order=order):
            product = order_item.product
            items.append({
                "sku_number": str(product.id),
                "category": product.category,
                "title": product.name,
                "description": product.description,
                "unit_price": product.amount,
                "quantity": order_item.quantity,
                "unit_measure": "unit",
                "total_amount": product.amount * order_item.quantity,
            })
        
        logger.debug(f'Constructed items list: {items}')
        
        # Calcular o total_amount
        total_amount = sum(item['total_amount'] for item in items)
        logger.info(f'Calculated total amount: {total_amount}')
        
        # Construir o payload
        data = {
            "cash_out": {"amount": 0},
            "description": "Purchase description.",
            "external_reference": str(order.id),
            "items": items,
            "notification_url": "http://example.com/webhook/",
            #"sponsor": {"id": 407707350},
            "title": "Product order",
            "total_amount": total_amount,
        }

        json_data = json.dumps(data)
        url = f'/instore/orders/qr/seller/collectors/407707350/pos/SUC001POS001/qrs'
        logger.info(f'Sending POST request to URL: {url}')
        logger.info(f'Sending POST request with data: {json_data}')
        try:
            connection.request("POST", url, body=json_data, headers=headers)
            response = connection.getresponse()
            response_data = response.read().decode()
            
            logger.info(f'Response status: {response.status}')
            logger.debug(f'Response data: {response_data}')
            
            if response.status == 201:
                response_json = json.loads(response_data)
                logger.info(f'Successfully created QR code response: {response_json}')
                return response_json
            else:
                logger.error(f'Error creating QR code: {response_data}')
                raise Exception(f'Error creating QR code: {response_data}')
        except Exception as e:
            logger.error(f'Exception occurred: {e}')
            raise
