variable "random_string_length" {
  type = number
  default = 8
}

variable "random_string_special" {
  type = bool
  default = false
}

variable "lambda_function_runtime" {
  type = string
  default = "python3.8"
}

variable "email" {
  type = string
  default = "shay79il@gmail.com"
}

variable "s3_bucket_acl" {
  type = string
  default = "private"
}

variable "filter_suffix" {
  type = string
  default = ".jpg" 
}

variable "elasticache_cluster_id" {
  type = string
  default = "temp-cluster" 
}

variable "elasticache_cluster_engine" {
  type = string
  default = "redis" 
}

variable "elasticache_cluster_node_type" {
  type = string
  default = "cache.t2.micro" 
}

variable "elasticache_cluster_num_cache_nodes" {
  type = number
  default = 1
}

variable "elasticache_cluster_group_name" {
  type = string
  default = "default.redis3.2"
}

variable "elasticache_cluster_engine_version" {
  type = string
  default = "3.2.10" 
}

variable "elasticache_cluster_port" {
  type = number
  default = 6379
}

variable "cloudwatch_event_rule_rate" {
  type = number
  default = 15
}