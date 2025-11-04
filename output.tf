output "vpc_id" {
    value = aws_vpc.main.id
}

output "public_subnet_ids" {
    value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
    value = aws_subnet_private[*].id
}

output "database_subnet_ids" {
    value = aws_subnet_database[*].id  
}