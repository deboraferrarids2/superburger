from django.db import models
from django.utils.translation import gettext_lazy as _
from order.models.orders import Order
from django.utils import timezone

class Transaction(models.Model):

    STATUS_CHOICES = [
        ('aguardando', 'Aguardando'),
        ('pago', 'Pago'),
        ('falha', 'Falha'),
    ]
    
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    external_id = models.CharField(max_length=100, blank=True, null=True)
    status = models.CharField(max_length=255, choices=STATUS_CHOICES, default='aguardando')
    qr_code = models.CharField(max_length=600, blank=True, null=True)
    amount = models.IntegerField(verbose_name="valor_transacao",help_text="em centavos",default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        verbose_name = _('Transacao')
        verbose_name_plural = _('Transacoes')

    def __str__(self):
        return f"{self.id}-{self.order}-{self.status}"
