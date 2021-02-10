import os
from storages.backends.azure_storage import AzureStorage

class StaticFileStorage(AzureStorage):
    account_name = os.environ['AZURE_STORAGE_ACCOUNT_NAME']
    account_key = os.environ['AZURE_STORAGE_ACCOUNT_KEY']
    azure_container = 'static'
    expiration_secs = None

class MediaFileStorage(AzureStorage):
    account_name = os.environ['AZURE_STORAGE_ACCOUNT_NAME']
    account_key = os.environ['AZURE_STORAGE_ACCOUNT_KEY']
    azure_container = 'media'
    expiration_secs = None