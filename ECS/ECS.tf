provider "alicloud" {
    access_key = ""
    secret_key = ""
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


resource "alicloud_instance" "default-instance" {

  availability_zone = "${var.zone}"
  security_groups   = "${alicloud_security_group.default-security-group.*.id}"

  instance_type              = "ecs.t5-lc2m1.nano"
  system_disk_category       = "cloud_efficiency"
  image_id                   = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name              = "riens-vm"
  vswitch_id                 = "${alicloud_vswitch.default-vsw.id}"
  internet_max_bandwidth_out = 10
}
