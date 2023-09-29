variable "name" {
  default = "udacity-crozier"
}

variable "azs" {
  type = list(string)
  default = [ "us-east-2a" ] 
}

variable "public_subnet_tags" {
  default = { "kubernetes.io/role/elb" = 1 }
}

variable "private_subnet_tags" {
  default = { "kubernetes.io/role/internal-elb" = 1 }
}
