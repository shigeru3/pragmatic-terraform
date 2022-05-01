data "aws_route53_zone" "shigeru3" {
  name = "shigeru3.net"
}

resource "aws_route53_record" "shigeru3" {
  name    = data.aws_route53_zone.shigeru3.zone_id
  type    = "A"
  zone_id = data.aws_route53_zone.shigeru3.name

  alias {
    evaluate_target_health = true
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
  }
}

output "domain_name" {
  value = aws_route53_record.shigeru3.name
}
