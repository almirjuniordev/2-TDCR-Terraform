provider "azurerm" {
    version = "=1.27.0"
}

resource "azurerm_resource_group" "rg" {
    name     = "AlmirResourceGroup"
    location = "${var.location}"
    tags = {
        environment = "Almir ResourceGroup"
    }
}

resource "azurerm_virtual_network" "vnet" {
    name                = "AlmirVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
    name                 = "AlmirSubnet"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.vnet.name}"
    address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "publicip" {
    name                         = "AlmirPublicIP"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.rg.name}"
    allocation_method            = "Static"
}

resource "azurerm_network_security_group" "nsg" {
    name                = "AlmirNSG"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "nic" {
    name                      = "AlmirNIC"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.rg.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "AlmirConfig"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}

resource "azurerm_virtual_machine" "vm" {
	name = "AlmirVM"
	location = "${var.location}"
	resource_group_name = "${azurerm_resource_group.rg.name}"
	network_interface_ids = ["${azurerm_network_interface.nic.id}"]
	vm_size = "Standard_DS1_v2"

	storage_os_disk {
		name = "AlmirDisk"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Premium_LRS"
	}
	
	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04.0-LTS"
		version = "latest"
	}
	
	os_profile {
		computer_name = "AlmirVM"
		admin_username = "almirjunior"
		admin_password = "P@ssword!123#"
	}
	
	os_profile_linux_config {
		disable_password_authentication = false
	}
	tags = {
		environment = "NacAlmir"
	}
}