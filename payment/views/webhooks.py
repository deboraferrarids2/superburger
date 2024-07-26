from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from payment.use_cases.webhooks import ProcessWebhookUseCase
import logging


# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from payment.use_cases.webhooks import ProcessWebhookUseCase
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TransactionWebhookView(APIView):
    permission_classes = [AllowAny] 
    
    def post(self, request):
        # Log the incoming request
        logger.info('Received webhook POST request')
        
        # Use request.data which is already parsed by DRF
        data = request.data
        logger.info(f'Request data parsed: {data}')
        
        # Extract action from data
        action = data.get('action')
        logger.info(f'Extracted action: {action}')
        
        # Extract resource_id from nested data
        resource_id = data.get('data', {}).get('id')
        logger.info(f'Extracted resource_id: {resource_id}')

        if not action or not resource_id:
            logger.warning('Invalid request: Missing action or resource_id')
            return Response({'message': 'Invalid request'}, status=status.HTTP_400_BAD_REQUEST)

        # Create an instance of the ProcessWebhookUseCase
        use_case = ProcessWebhookUseCase()

        try:
            # Call the use case to process the webhook payload
            success = use_case.execute(action, resource_id)

            if success:
                # Respond with a success message and HTTP 200 status code
                logger.info(f'Webhook processed successfully for action: {action} and resource_id: {resource_id}')
                return Response({'message': 'Webhook processed successfully'}, status=status.HTTP_200_OK)
            else:
                # Respond with an error message and HTTP 400 status code
                logger.info(f'Webhook processing failed for action: {action} and resource_id: {resource_id}')
                return Response({'message': 'Webhook processing failed'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            # Log the exception
            logger.info(f'Exception occurred during webhook processing: {e}')
            return Response({'message': 'Webhook processing failed'}, status=status.HTTP_400_BAD_REQUEST)
