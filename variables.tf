variable "nat_mode" {
  description = "IPv4 private-subnet egress for this three-AZ topology: disabled, shared, or per_az."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["disabled", "shared", "per_az"], var.nat_mode)
    error_message = "nat_mode must be disabled, shared, or per_az."
  }
}
