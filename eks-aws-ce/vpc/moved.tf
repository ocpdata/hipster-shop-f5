# Migraciones de recursos renombrados en la refactorización de subnets.
#
# Sin estos bloques Terraform intentaría crear aws_subnet.ce_outside (índice 10)
# antes de destruir aws_subnet.outside[0] (mismo CIDR), causando conflicto en AWS.
#
# Con 'moved', Terraform actualiza el state en lugar de destroy+create:
# - aws_subnet.ce_outside se "convierte" en el antiguo outside[0] → 0 cambios en AWS
# - aws_route_table.nat_public se "convierte" en el antiguo outside → 0 cambios en AWS
#
# Lo que sí se destruye/crea (cambios reales en AWS):
# - aws_subnet.outside[1]              → destruido (no tiene equivalente nuevo)
# - aws_route_table_association.outside → destruidas (la asociación cambia de subnet)
# - aws_subnet.nat_public              → creado nuevo (índice 0)
# - aws_subnet.ce_inside               → creado nuevo (índice 5)
# - aws_route_table_association.nat_public → creada nueva
# - aws_nat_gateway.this               → recreado (cambia de outside[0] a nat_public)

moved {
  from = aws_subnet.outside[0]
  to   = aws_subnet.ce_outside
}

moved {
  from = aws_route_table.outside
  to   = aws_route_table.nat_public
}
