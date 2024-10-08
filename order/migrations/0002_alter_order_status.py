# Generated by Django 3.2.13 on 2024-07-26 16:50

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('order', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='order',
            name='status',
            field=models.CharField(choices=[('em aberto', 'em aberto'), ('processando', 'processando'), ('recebido', 'recebido'), ('em preparacao', 'em preparacao'), ('pronto', 'pronto'), ('finalizado', 'finalizado'), ('cancelado', 'cancelado')], default='em aberto', max_length=20, verbose_name='status'),
        ),
    ]
