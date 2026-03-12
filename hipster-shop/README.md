# Hipster Shop — F5 Distributed Cloud (XC)

Variante del manifiesto de Hipster Shop con el servicio `frontend` expuesto a través de **F5 Distributed Cloud** como proxy HTTP. El frontend no tiene acceso público directo — todo el tráfico entra por F5 XC.

## Diferencia con `hipster-shop-internet/`

|                                | `hipster-shop/` | `hipster-shop-internet/` |
| ------------------------------ | --------------- | ------------------------ |
| Tipo de servicio `frontend`    | `ClusterIP`     | `LoadBalancer`           |
| Acceso público                 | Vía F5 XC       | Directo (ELB de AWS)     |
| Annotation `ves.io/proxy-type` | `HTTP_PROXY`    | No                       |

## Arquitectura

```
Internet → F5 XC → EKS (frontend ClusterIP) → microservicios
```

## Microservicios incluidos

| Servicio                | Descripción            | Puerto |
| ----------------------- | ---------------------- | ------ |
| `frontend`              | UI web principal       | 8080   |
| `checkoutservice`       | Proceso de compra      | 5050   |
| `cartservice`           | Carrito (usa Redis)    | 7070   |
| `productcatalogservice` | Catálogo de productos  | 3550   |
| `recommendationservice` | Recomendaciones        | 8080   |
| `emailservice`          | Envío de emails        | 5000   |
| `paymentservice`        | Procesamiento de pagos | 50051  |
| `shippingservice`       | Cálculo de envíos      | 50051  |
| `currencyservice`       | Conversión de divisas  | 7000   |
| `redis-cart`            | Base de datos Redis    | 6379   |
| `loadgenerator`         | Generador de carga     | —      |

## Workflows

| Workflow                         | Descripción                        |
| -------------------------------- | ---------------------------------- |
| `Hipster Shop - Deploy (F5 XC)`  | Despliega la app en el cluster EKS |
| `Hipster Shop - Destroy (F5 XC)` | Elimina la app del cluster         |

## Prerequisitos

1. Cluster EKS desplegado → workflow **EKS Cluster - Deploy**
2. Site F5 XC configurado → workflow **F5 XC – Deploy AWS VPC Site**

## Despliegue

1. Ejecutar **EKS Cluster - Deploy** (si el cluster no existe aún)
2. Ejecutar **F5 XC – Deploy AWS VPC Site** (si el site no existe aún)
3. Ejecutar **Hipster Shop - Deploy (F5 XC)**

## Destrucción

Seguir este orden para evitar dependencias rotas:

1. Ejecutar **Hipster Shop - Destroy (F5 XC)**
2. Ejecutar **F5 XC – Destroy AWS VPC Site** (si aplica)
3. Ejecutar **EKS Cluster - Destroy**

## Variables y secrets requeridos

| Nombre                  | Tipo     | Descripción                     |
| ----------------------- | -------- | ------------------------------- |
| `AWS_ACCESS_KEY_ID`     | Secret   | IAM Access Key                  |
| `AWS_SECRET_ACCESS_KEY` | Secret   | IAM Secret Key                  |
| `TFC_TOKEN`             | Secret   | Token de API de Terraform Cloud |
| `TFC_ORG`               | Secret   | Organización de Terraform Cloud |
| `AWS_REGION`            | Variable | Región de AWS (ej. `us-east-1`) |
