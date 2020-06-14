provider "alicloud" {
    access_key = "your_access_key"
    secret_key = "your_secret_key"
    region = "ap-southeast-1"
}

variable "prefix" {
  default = "terra"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "zone" {
  default = "ap-southeast-1b"
}

resource "alicloud_vpc" "default-vpc" {
  name       = "${var.prefix}-vpc"
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "default-vsw" {
  vpc_id            = "${alicloud_vpc.default-vpc.id}"
  cidr_block        = "172.16.0.0/21"
  availability_zone = "${var.zone}"
}

resource "alicloud_security_group" "default-security-group" {
  name = "${var.prefix}-secgroup"
  vpc_id = "${alicloud_vpc.default-vpc.id}"
}

resource "alicloud_security_group_rule" "allow_all" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = "${alicloud_security_group.default-security-group.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_slb" "default-slb" {
  name       = "${var.prefix}-slb"
  vswitch_id = "${alicloud_vswitch.default-vsw.id}"
  address_type = "internet"
}

resource "alicloud_slb_listener" "default-http" {
  load_balancer_id = "${alicloud_slb.default-slb.id}"
  backend_port = 8888
  frontend_port = 8888
  bandwidth = 10
  protocol = "http"
  sticky_session = "on"
  sticky_session_type = "insert"
  cookie = "testslblistenercookie"
  cookie_timeout = 86400
  health_check = "on"
  health_check_type = "http"
  health_check_connect_port = 8888
}

resource "alicloud_ess_scaling_group" "default-scaling-group" {
  depends_on = [alicloud_slb_listener.default-http]
  min_size = 2
  max_size = 10
  scaling_group_name = "${var.prefix}-scg"
  vswitch_ids= ["${alicloud_vswitch.default-vsw.id}"]
  loadbalancer_ids = ["${alicloud_slb.default-slb.id}"]
  removal_policies = ["OldestInstance", "NewestInstance"]  
}

resource "alicloud_ess_scaling_configuration" "default-scaling-config" {
  scaling_group_id = "${alicloud_ess_scaling_group.default-scaling-group.id}"
  image_id = "centos_8_1_x64_20G_alibase_20200519.vhd"
  instance_type = "ecs.t5-lc2m1.nano"
  security_group_id = "${alicloud_security_group.default-security-group.id}"
  active = true
  enable = true
  user_data = "${file("dockerscript.sh")}" 
  internet_max_bandwidth_in=10
  internet_max_bandwidth_out= 10
  internet_charge_type = "PayByTraffic"
  force_delete = true
}

resource "alicloud_ess_scaling_rule" "rule" {  
  scaling_group_id = "${alicloud_ess_scaling_group.default-scaling-group.id}"  
  adjustment_type  = "TotalCapacity"  
  adjustment_value = 2  
  cooldown = 60
}
