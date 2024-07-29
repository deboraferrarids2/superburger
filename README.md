# Desenho da arquitetura

Considerando as necessidades da empresa de criar um sistema de gestão de pedido que atenda a alguns requisitos de negócio mínimos, como a criação de usuários, início de criação de pedido com e sem login pelo usuário, adição/exclusao/edição de itens nos pedidos, checkout para pagamento e acompanhamento/atualização de status de pedidos, foi desenhada essa solução utilizando Docker para orquestração de containers e Kubernetes para escalabilidade conforme fluxo de acesso/demanda, contendo:
- um container para banco de dados relacional Postgresql, de forma que é fácil a tabulação, relação e análise de dados históricos de compras e clientes;
- um container com aplicação rodando em Python utilizando django framework

A arquitetura de dados foi desenhada de forma que utilize a linguagem ubíqua adotada no projeto, performe bem as alterações dentro de um pedido separando as informações em itens do pedido. CPF foi definido como objeto de valor por ser aplicável em diferentes contextos. A base de dados é estruturada, assim como a aplicação em três principais domínios: user_auth (contendo dados de cadastro e usuário), orders (contendo dados de pedidos, itens, produtos) e payment (contendo dados de transações)  

Para atender à necessidade de negócios, as requisições podem ser feitas com Bearer ho authorization header para usuários logados ou a nível de sessão utilizando 'session' como query parameter nas urls. Quando um pedido é iniciado sem Bearer, ele será amarrado à session e só é possível interagir com ele utilizando essa session. Em caso de pedidos iniciados com Bearer válido, o pedido fica vinculado ao usuário logado e ainteração com ele só poderá ser feita pelo usuário logado. 

Ao rodar o projeto é criado um super user admin@superburger.com senha:admin . Com esse usuário é possível ver a lista completa de pedidos que possuam status 'pronto', 'em preparação' e 'recebido', ordenados do mais antigo para o mais recente.

Link para acesso ao swagger (insomnia json) https://drive.google.com/file/d/1CNN9pYREDl0m1tV4T4-ThIqfEEJs-Wck/view?usp=sharing

Link do vídeo da entrega fase 2: https://drive.google.com/file/d/1njQoZLknU222sHxNQZtK7fOI51lAKBau/view?usp=sharing

Sobre arquitetura hexagonal: No contexto django as views são ports, as serializers são os adapters e as models definem sim alguns padroes de como salvar os dados no banco, mas são questoes, por exemplo, como limpar caracteres speciais de um cpf, nao regras de negocios. Como nas serializers (adapters)são feitas as adaptacoes de formato das dependencias, doi adotada a sugestao das aulas e utilizados use_cases para detalhar casos de uso. Apesar de nomenclaturas distintas e uso de framework, tudo que fiz ali de estrutura de pedidos, produtos, checkout, foi tudo escrito do zero e dentro dos padores, apenas utilizando outros nomes.

# challenge

This is a Django REST Framework project that runs in Docker.

## Superburger operation

A functional backend service for customers and store staff can create and manage orders 

## Prerequisites

Before running the project, make sure you have the following installed on your machine:

- Docker (so you can run the project)
- Postgres/Dbeaver/PGAdmin (so you can manage local database if needed (optional))

## Getting Started

To build and run the project locally, follow these steps:

1. Run docker in your local enviroment

2. In your terminal, run the following command:
    ~sudo docker-compose up --build


## for running using kubernets read the K8s README
