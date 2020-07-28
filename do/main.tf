data "terraform_remote_state" "aws_demo" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

provider "bigip" {

 # address = "${var.url}"
  address = data.terraform_remote_state.aws_demo.outputs.f5_ui
  # username = "${var.username}"
  username = data.terraform_remote_state.aws_demo.outputs.f5-user
  # password = "${var.password}"
  password =  data.terraform_remote_state.aws_demo.outputs.f5_password
}
resource "bigip_do"  "do-example" {
     do_json = "${file("example.json")}"
     timeout = 15
 }