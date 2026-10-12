terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    # Provider comunitario que embebe la librería de kind v0.31; ver ADR-0002.
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11.0"
    }
  }
}
