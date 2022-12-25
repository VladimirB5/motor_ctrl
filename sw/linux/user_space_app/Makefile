motor_ctrl_example: motor_ctrl_example.o
	arm-linux-gcc -o motor_ctrl_example motor_ctrl_example.o

motor_ctrl_example.o: motor_ctrl_example.c
	arm-linux-gcc -c motor_ctrl_example.c

clean:
	rm -f motor_ctrl_example
	rm -f motor_ctrl_example.o
