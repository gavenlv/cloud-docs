az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --image UbuntuLTS \
    --size Standard_B2s \
    --admin-username azureuser \
    --ssh-key-value ~/.ssh/id_rsa.pub