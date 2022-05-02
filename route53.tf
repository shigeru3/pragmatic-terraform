data "aws_route53_zone" "shigeru3" {
  name = "shigeru3.net."
}

resource "aws_route53_record" "shigeru3" {
  name    = data.aws_route53_zone.shigeru3.name
  type    = "A"
  zone_id = data.aws_route53_zone.shigeru3.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
  }
}

output "domain_name" {
  value = aws_route53_record.shigeru3.name
}

resource "aws_acm_certificate" "shigeru3" {
  domain_name = aws_route53_record.shigeru3.name
  subject_alternative_names = []
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "shigeru3_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.shigeru3.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.shigeru3.id
  records = [each.value.record]
  ttl = 60
}

resource "aws_acm_certificate_validation" "shigeru3" {
  certificate_arn = aws_acm_certificate.shigeru3.arn
  validation_record_fqdns = [for record in aws_route53_record.shigeru3_certificate : record.fqdn]
}
