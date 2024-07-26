from payment.models.transaction import Transaction
from order.models.orders import Order, OrderItems
from django.db import transaction
from payment.client import MercadoPagoService
import logging

# Configurar o logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CreatePaymentUseCase:
    def execute(self, order):
        if order.status != 'em aberto':
            raise Exception('Payment cannot be created for an order that is not in "em aberto" status.')

        # Create a payment transaction
        try:
            with transaction.atomic():
                # Create a new Transaction object
                payment = Transaction(
                    order=order,
                    status='aguardando',  # You can set the initial status as 'pago' or any desired value
                    external_id='',  # You can set an external ID if needed
                )
                payment.save()
        except Exception as e:
            raise Exception('Failed to create payment transaction: {}'.format(str(e)))

        return payment
    
class CheckoutOrderUseCase:
    def execute(self, order):
        if order.status == 'em aberto':
            logger.info(f'Starting checkout process for order ID {order.id}.')
            # Calculate total_amount
            total_amount = sum(item.product.amount * item.quantity for item in OrderItems.objects.filter(order=order))
            logger.info(f'Calculated total amount for order ID {order.id}: {total_amount}')

            try:
                # Integrate Mercado Pago QR Code generation
                mercado_pago_service = MercadoPagoService()
                response_data = mercado_pago_service.create_qr_code(order)
                qr_code = response_data.get("qr_data")
                in_store_order_id = response_data.get("in_store_order_id")
                
                logger.info(f'Successfully created QR code and in_store_order_id for order ID {order.id}: QR code={qr_code}, in_store_order_id={in_store_order_id}')

                # Save the QR code and in_store_order_id in the Payment model
                payment = Transaction.objects.create(
                    order=order, 
                    qr_code=qr_code, 
                    external_id=in_store_order_id,  # Save the in_store_order_id in the external_id field
                    amount=total_amount
                )
                logger.info(f'Payment record created with QR code and in_store_order_id for order ID {order.id}.')
                
                # Update the order status to 'processando'
                order.status = 'processando'
                order.save()

                return payment  # Return the created payment
            except Exception as e:
                logger.error(f'Error during QR code generation or payment record creation for order ID {order.id}: {str(e)}')
                raise

        else:
            logger.error(f'Cannot finalize order ID {order.id} because its status is not "em aberto".')
            raise Exception('Esse pedido não pode ser finalizado.')

        
# class CheckoutOrderUseCase:
#     def execute(self, order):
#         if order.status == 'em aberto':
#             # Call the CreatePaymentUseCase to create a payment transaction
#             create_payment_use_case = CreatePaymentUseCase()
#             create_payment_use_case.execute(order)

#             # Update the order status to 'recebido'
#             order.status = 'recebido'
#             order.save()
#         else:
#             raise Exception('Esse pedido não pode ser finalizado.')
