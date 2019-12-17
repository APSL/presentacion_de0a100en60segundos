# Genera un par de claves (pública y privada)
resource "tls_private_key" "aws-ed" {
  algorithm      = "RSA"
  rsa_bits       = "4096"
}

# Despliega la clave en AWS
resource "aws_key_pair" "ec2-key" {
  key_name       = "ed-key"
  public_key     = tls_private_key.aws-ed.public_key_openssh
}

# Guarda la clave privada en directorio
resource "local_file" "save_private_key" {
  content         = tls_private_key.aws-ed.private_key_pem
  filename        = "../../ec2-keys/ed-key"
  file_permission = "0400"
}

# Guarda clave pública en directorio
resource "local_file" "save_public_key" {
  content         = tls_private_key.aws-ed.public_key_openssh
  filename        = "../../ec2-keys/ed-key.pub"
  file_permission = "0640"
}

# Obtiene la AMI de Ubuntu más reciente
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Creamos Security Group y permitimos acceso por SSH y HTTP
resource "aws_security_group" "emili_darder_instance_sg" {
  name        = "Emili Darder Instance - SG"
  description = "Allow SSH and HTTP"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Crea la instancia a partir de la AMI con los valores que le demos
resource "aws_instance" "emili-darder-instance" {
  ami               = data.aws_ami.ubuntu.id    #<--- Referencia a la última AMI
  instance_type     = "m5a.2xlarge" #https://ec2instances.info/
  security_groups   = ["${aws_security_group.emili_darder_instance_sg.name}"]   #<--- Referencia al SG
  key_name          = aws_key_pair.ec2-key.key_name        #<---  Usamos la key generada
  availability_zone = "eu-west-1a"
  user_data         = templatefile("templates/user_data",{})      #<--- Script cloud init

  # Asignamos un SSD de 16GB a la instancia
  root_block_device {
    volume_type = "gp2"
    volume_size = 16
  }

  tags = {
    Name      = "Maquinon"
    QuienPaga = "Toni"
  }
}

# Solicitamos una IP elástica y la asignamos a la instancia
resource "aws_eip" "emili-darder-instance-ip" {
  instance        = aws_instance.emili-darder-instance.id
  vpc             = true
}

