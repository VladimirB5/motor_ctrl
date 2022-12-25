ARCH := arm
obj-m := motor_ctrl.o
PWD := $(shell pwd)
export
default:
	$(MAKE) -C $(KERNEL) M=$(PWD) modules
clean:
	$(MAKE) -C $(KERNEL) M=$(PWD) clean
