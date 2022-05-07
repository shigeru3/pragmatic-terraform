resource "aws_elasticache_parameter_group" "example" {
  family = "redis5.0"
  name   = "example"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "example" {
  name       = "example"
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]
}

resource "aws_elasticache_replication_group" "example" {
  replication_group_description = "Cluster Disabled"
  replication_group_id          = "example"
  engine = "redis"
  engine_version = "5.0.4"
  number_cache_clusters = 3
  node_type = "cache.m4.large"
  snapshot_window = "09:10-10:10"
  snapshot_retention_limit = 7
  maintenance_window = "mon:10:40-mon:11:40"
  automatic_failover_enabled = true
  port = 6379
  apply_immediately = false
  security_group_ids = [module.redis_sg.security_group_id]
  parameter_group_name = aws_elasticache_parameter_group.example.name
  subnet_group_name = aws_elasticache_subnet_group.example.name
}

module "redis_sg" {
  source = "./security_group"
  name = "redis-sg"
  vpc_id = aws_vpc.example.id
  port = 6379
  cidr_blocks = [aws_vpc.example.cidr_block]
}
