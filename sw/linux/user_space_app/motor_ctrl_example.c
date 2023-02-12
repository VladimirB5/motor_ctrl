#include<stdio.h>
#include<stdlib.h>
#include<errno.h>
#include<fcntl.h>
#include<string.h>
#include<unistd.h>
#include <sys/ioctl.h>
//#include <signal.h>

/* Use '81' as magic number */
#define MOTOR_CTRL_MAGIC 81

#define MOTOR_IO_CLK_ENA    _IOW(MOTOR_CTRL_MAGIC, 1, int)
#define MOTOR_IO_RUN        _IOW(MOTOR_CTRL_MAGIC, 2, int)
#define MOTOR_IO_PWM_CTRL   _IOW(MOTOR_CTRL_MAGIC, 3, int)
#define MOTOR_IO_PWM_FREQ   _IOW(MOTOR_CTRL_MAGIC, 4, int)
#define MOTOR_IO_RED_LED    _IOW(MOTOR_CTRL_MAGIC, 5, int)
#define MOTOR_IO_GREEN_LED  _IOW(MOTOR_CTRL_MAGIC, 6, int)


int fd;

int main(){
   int ret;
   int i;
   unsigned int data_val[6];


   printf("Starting device test code example...\n");
   fd = open("/dev/motor_ctrl", O_RDWR);             // Open the device with read/write access
   if (fd < 0){
      perror("Failed to open the device...");
      return errno;
   }

   printf("IOCTL\n");
   ret = ioctl(fd, MOTOR_IO_CLK_ENA, 0x01); // enable clock
   printf("ret:%d ioctl comm 0.\n", ret);

   ret = ioctl(fd, MOTOR_IO_RUN, 0x01);
   printf("ret:%d ioctl comm 1.\n", ret);

   ret = ioctl(fd, MOTOR_IO_RED_LED, 1);
   printf("ret:%d ioctl comm 2.\n", ret);

   ret = ioctl(fd, MOTOR_IO_GREEN_LED, 1);
   printf("ret:%d ioctl comm 3.\n", ret);

   ret = read(fd, (void*) data_val, 6); // read data from register
   if (ret < 0){
      perror("Failed to read the message to the device.");
      return errno;
   }

   for (i = 0; i < 6; i++) {
     printf("data[%d]: %X\n", i, data_val[i]);
   }

   //printf("writing and probing....");
   //write(fd, led, strlen(led));

   ret = ioctl(fd, MOTOR_IO_CLK_ENA, 0x00); // disable clock
   printf("ret:%d ioctl comm 0.\n", ret);

   close(fd);

   printf("End of the program\n");
   return 0;
}

