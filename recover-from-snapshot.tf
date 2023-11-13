# resource "aws_ebs_snapshot" "snapshot" {
#   volume_id = var.volume_id
# }
#
#
# resource "aws_ami" "myami" {
#   name = "my-custom-ami"
#
#   virtualization_type = "hvm"
#   root_device_name    = "/dev/xvda"
#
#   ebs_block_device {
#     device_name = "/dev/xvda"
#     snapshot_id = aws_ebs_snapshot.snapshot.id
#     volume_type = "gp2"
#   }
# }
