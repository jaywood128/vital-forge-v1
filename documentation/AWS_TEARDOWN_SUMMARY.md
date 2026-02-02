# AWS Teardown Summary

## Date: 2026-01-31

## Resources Being DESTROYED by Terraform
These are managed by Terraform and will be deleted:

### Billable Resources (will stop charges)
1. **Lightsail Container Service** (`aws_lightsail_container_service.app`)
   - Name: `vitalforge-v1-container`
   - Cost: ~$7/month

2. **Lightsail PostgreSQL Database** (`aws_lightsail_database.main`)
   - Name: `vitalforge-v1-db`
   - Cost: ~$15/month
   - Note: Data will be permanently deleted

3. **ElastiCache Redis Cluster** (`aws_elasticache_cluster.redis`)
   - Name: `vitalforge-v1-redis`
   - Cost: ~$12.41/month

4. **ElastiCache Subnet Group** (`aws_elasticache_subnet_group.main`)
   - No cost

5. **Redis Security Group** (`aws_security_group.redis`)
   - No cost

6. **ECR Repository** (`aws_ecr_repository.app`)
   - Name: `vitalforge-v1-api`
   - Cost: ~$0.10/month (storage for Docker images)

7. **ECR Repository Policy** (`aws_ecr_repository_policy.lightsail_pull`)
   - No cost

8. **ECR Lifecycle Policy** (`aws_ecr_lifecycle_policy.app`)
   - No cost

### Total Monthly Savings: ~$34.51/month

## Resources Being KEPT (not managed by Terraform)
These exist but are NOT managed by Terraform, so they won't be deleted:

1. **Route 53 Hosted Zone**
   - Referenced as data source only
   - Cost: ~$0.50/month
   - Will remain active for Railway migration

2. **Lightsail SSL Certificate** (if exists)
   - You mentioned `Certificate-1` in console
   - Should be detached first, then manually deleted if desired

## Data Sources (read-only, not destroyed)
- `data.aws_vpc.default`
- `data.aws_subnets.default`
- `data.aws_availability_zones.available`
- `data.aws_route53_zone.main`
- `data.aws_caller_identity.current`
- `data.aws_region.current`

## Pre-Destroy Checklist
- [x] Confirmed Lightsail Container Service exists
- [x] Confirmed Lightsail Database exists
- [x] Confirmed ElastiCache cluster exists
- [x] Confirmed ECR repository exists
- [x] Confirmed Route 53 is NOT managed by Terraform (safe)
- [x] Backup any critical data (not needed - starting fresh)

## Destruction Complete - 2026-01-31

✅ **All Terraform-managed resources successfully destroyed:**
- Lightsail Container Service: DELETED
- Lightsail PostgreSQL Database: DELETED
- ElastiCache Redis Cluster: DELETED
- ElastiCache Subnet Group: DELETED
- Redis Security Group: DELETED
- ECR Repository (after clearing images): DELETED
- ECR Repository Policy: DELETED
- ECR Lifecycle Policy: DELETED

**Total: 8 resources destroyed**
**Monthly savings: ~$34.51/month**

## Next Steps After Terraform Destroy
1. Check AWS Console for any leftover resources:
   - CloudWatch Log Groups
   - Lightsail SSL Certificate
   - Any manually created resources
2. Set up Railway project
3. Update Route 53 DNS records to point to Railway
