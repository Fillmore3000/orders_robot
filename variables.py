from RPA.Robocorp.Vault import Vault

secret = Vault().get_secret("credentials")
URL = secret["url"]