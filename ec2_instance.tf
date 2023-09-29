variable "aws_ami" {
}

resource "aws_key_pair" "udacity" {
  key_name = "udacity"
  public_key = file("~/.ssh/udacity.pub")
}

resource "aws_instance" "ec2" {
  depends_on = [ aws_key_pair.udacity ]
  count = length(aws_subnet.private)

  ami = var.aws_ami
  instance_type = "t3.micro"
  key_name = aws_key_pair.udacity.key_name
  subnet_id     = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags = {
    Name = "ubuntu"
  }
}