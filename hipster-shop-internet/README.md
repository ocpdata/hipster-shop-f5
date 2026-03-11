# Hipster Shop — Internet (LoadBalancer)

Variante del manifiesto de Hipster Shop con el servicio `frontend` expuesto directamente a internet mediante un **AWS Elastic Load Balancer**.

## Diferencia con `hipster-shop/`

| | `hipster-shop/` | `hipster-shop-internet/` |
|---|---|---|
| Tipo de servicio `frontend` | `ClusterIP` | `LoadBalancer` |
| Acceso público | No (requiere F5 XC) | Sí (ELB de AWS) |
| Annotation `ves.io/proxy-type` | Sí | No |

## Workflows relacionados

| Workflow | Descripción |
|---|---|
| `Hipster Shop - Deploy Internet` | Despliega la app y muestra la URL pública del ELB |
| `Hipster Shop - Destroy Internet` | Elimina la app y el ELB de AWS |

## Prerequisitos

El cluster EKS debe estar desplegado antes de ejecutar cualquier workflow de esta variante. Usa primero el workflow **EKS Cluster - Deploy**.

## Despliegue

1. Ejecutar **EKS Cluster - Deploy** (si el cluster no existe aún)
2. Ejecutar **Hipster Shop - Deploy Internet**
3. Al finalizar el workflow, la URL pública aparece en el log:
   ```
   ✅ Hipster Shop disponible en: http://<elb-hostname>.elb.amazonaws.com
   ```

## Destrucción

Seguir este orden para evitar que Terraform falle al intentar eliminar la VPC con recursos activos:

1. Ejecutar **Hipster Shop - Destroy Internet** → elimina los pods y el ELB
2. Ejecutar **EKS Cluster - Destroy** → destruye la infraestructura

> ⚠️ Si se destruye el cluster sin eliminar primero el ELB, la destrucción de la VPC fallará porque AWS no permite eliminar una VPC con Load Balancers activos en sus subnets.

## Variables y secrets requeridos

Los mismos que usa el workflow `EKS Cluster - Deploy`:

| Nombre | Tipo | Descripción |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Secret | IAM Access Key |
| `AWS_SECRET_ACCESS_KEY` | Secret | IAM Secret Key |
| `TFC_TOKEN` | Secret | Token de API de Terraform Cloud |
| `TFC_ORG` | Secret | Organización de Terraform Cloud |
| `AWS_REGION` | Variable | Región de AWS (ej. `us-east-1`) |
