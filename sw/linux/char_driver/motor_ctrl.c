// insipired by article writing a linux kernel module by Derek Molloy (derekmolloy.ie)
// and linux device drivers 3rd edition

#include <linux/init.h>           // Macros used to mark up functions e.g. __init __exit
#include <linux/module.h>         // Core header for loading LKMs into the kernel
#include <linux/device.h>         // Header to support the kernel Driver Model
#include <linux/kernel.h>         // Contains types, macros, functions for the kernel
#include <linux/fs.h>             // Header for the Linux file system support
#include <linux/uaccess.h>          // Required for the copy to user function
#include <linux/ioport.h>
#include <asm/io.h>
#include <asm/current.h>
#include <linux/interrupt.h>            // Required for the IRQ code
#include <linux/delay.h>
#include <linux/platform_device.h>
#include <linux/of_device.h>
#include <linux/sched.h>
#include <asm/siginfo.h>
#include <linux/pid_namespace.h>
#include <linux/pid.h>


#define  DEVICE_NAME "motor_ctrl"  //< The device will appear at /dev/motor_ctr using this value
#define  CLASS_NAME  "motor"       //< The device class -- this is a character device driver
#define  C_ADDR_DEV 0x60000000     // device base address
#define  C_ADDR_CLK_ENA 0x00            // enable clock for block
#define  C_ADDR_RUN 0x04                // run PWM modulation
#define  C_ADDR_PWM_CTRL 0x08              // motor control register
#define  C_ADDR_LED 0x0C                // led control
#define  C_ADDR_TEST 0x10               // RO test register
#define  C_NUM_REG 5               // number of readable registers

/* Use '81' as magic number */
#define MOTOR_CTRL_MAGIC 81

#define MOTOR_IO_CLK_ENA    _IOW(MOTOR_CTRL_MAGIC, 1, int)
#define MOTOR_IO_RUN        _IOW(MOTOR_CTRL_MAGIC, 2, int)
#define MOTOR_IO_PWM_CTRL   _IOW(MOTOR_CTRL_MAGIC, 3, int)
#define MOTOR_IO_RED_LED    _IOW(MOTOR_CTRL_MAGIC, 4, int)
#define MOTOR_IO_GREEN_LED  _IOW(MOTOR_CTRL_MAGIC, 5, int)

MODULE_LICENSE("GPL");            ///< The license type -- this affects available functionality
MODULE_AUTHOR("Vladimir Beran");    ///< The author -- visible when you use modinfo
MODULE_DESCRIPTION("Minized motor ctrl char driver");  ///< The description -- see modinfo
MODULE_VERSION("0.1");            ///< A version number to inform users

static int    majorNumber;                  ///< Stores the device number -- determined automatically
static int    numberOpens = 0;              ///< Counts the number of times the device is opened
static int    data[9] = {0};               ///< Memory for the data passed to user space
static int    rc = 0;
static struct class*  motor_ctrClass  = NULL; ///< The device-driver class struct pointer
static struct device* motor_ctrDevice = NULL; ///< The device-driver device struct pointer
void * virt;
static struct task_struct *task = NULL; // 
struct resource *res;

// The prototype functions for the character driver -- must come before the struct definition
int send_sig_info(int sig, struct kernel_siginfo *info, struct task_struct *p);
static int     dev_open(struct inode *, struct file *);
static int     dev_release(struct inode *, struct file *);
static ssize_t dev_read(struct file *, char *, size_t, loff_t *);
static ssize_t dev_write(struct file *, const char *, size_t, loff_t *);
static long    dev_ioctl(struct file *, unsigned int, unsigned long);

/** @brief Devices are represented as file structure in the kernel. The file_operations structure from
 *  /linux/fs.h lists the callback functions that you wish to associated with your file operations
 *  using a C99 syntax structure. char devices usually implement open, read, write and release calls
 */
static struct file_operations fops =
{
   .open = dev_open,
   .read = dev_read,
   .write = dev_write,
   .unlocked_ioctl = dev_ioctl,
   .release = dev_release,
};

// struct mydriver_dm
// {
//    void __iomem *    membase; // ioremapped kernel virtual address
//    dev_t             dev_num; // dynamically allocated device number
//    struct cdev       c_dev;   // character device
//    struct class *    class;   // sysfs class for this device
//    struct device *   pdev;    // device
//    int               irq; // the IRQ number ( note: this will NOT be the value from the DTS entry )
// };
// 
// static struct mydriver_dm dm;

static int mydriver_of_probe(struct platform_device *ofdev)
{
   int result;

    printk(KERN_INFO "MOTOR_CTRL: Interrutp is not used");

   return 0;
}

static int mydriver_of_remove(struct platform_device *of_dev)
{
    //free_irq(res->start, NULL);
    return 0;
}

static const struct of_device_id mydriver_of_match[] = {
   { .compatible = "xlnx,motor_ctrl", },
   { /* end of list */ },
};
MODULE_DEVICE_TABLE(of, mydriver_of_match);

static struct platform_driver mydrive_of_driver = {
   .probe      = mydriver_of_probe,
   .remove     = mydriver_of_remove,
   .driver = {
      .name = "motor_ctrl",
      .owner = THIS_MODULE,
      .of_match_table = mydriver_of_match,
   },
};

/** @brief The LKM initialization function
 *  The static keyword restricts the visibility of the function to within this C file. The __init
 *  macro means that for a built-in driver (not a LKM) the function is only used at initialization
 *  time and that it can be discarded and its memory freed up after that point.
 *  @return returns 0 if successful
 */
static int __init motor_ctrl_init(void){
   printk(KERN_INFO "Motor_ctrl : Initializing motor ctrl Char LKM\n");

   // Try to dynamically allocate a major number for the device -- more difficult but worth it
   majorNumber = register_chrdev(0, DEVICE_NAME, &fops);
   if (majorNumber<0){
      printk(KERN_ALERT "Motor_ctrl failed to register a major number\n");
      return majorNumber;
   }
   printk(KERN_INFO "Motor_ctrl: registered correctly with major number %d\n", majorNumber);

   // Register the device class
   motor_ctrClass = class_create(THIS_MODULE, CLASS_NAME);
   if (IS_ERR(motor_ctrClass)){                // Check for error and clean up if there is
      unregister_chrdev(majorNumber, DEVICE_NAME);
      printk(KERN_ALERT "Failed to register device class\n");
      return PTR_ERR(motor_ctrClass);          // Correct way to return an error on a pointer
   }
   printk(KERN_INFO "Motor_ctrl: device class registered correctly\n");

   // Register the device driver
   motor_ctrDevice = device_create(motor_ctrClass, NULL, MKDEV(majorNumber, 0), NULL, DEVICE_NAME);
   if (IS_ERR(motor_ctrClass)){               // Clean up if there is an error
      class_destroy(motor_ctrClass);           // Repeated code but the alternative is goto statements
      unregister_chrdev(majorNumber, DEVICE_NAME);
      printk(KERN_ALERT "Failed to create the device\n");
      return PTR_ERR(motor_ctrDevice);
   }
   
   // request for acces to IO
   virt=ioremap(C_ADDR_DEV, 4096);
   
   platform_driver_register(&mydrive_of_driver);
   
   
   printk(KERN_INFO "Motor_ctrl: device class created correctly\n"); // Made it! device was initialized
   return 0;
}

/** @brief The LKM cleanup function
 *  Similar to the initialization function, it is static. The __exit macro notifies that if this
 *  code is used for a built-in driver (not a LKM) that this function is not required.
 */
static void __exit motor_ctrl_exit(void){
   iounmap(virt);                                          // free memory 
   platform_driver_unregister(&mydrive_of_driver);
   device_destroy(motor_ctrClass, MKDEV(majorNumber, 0));     // remove the device
   class_unregister(motor_ctrClass);                          // unregister the device class
   class_destroy(motor_ctrClass);                             // remove the device class
   unregister_chrdev(majorNumber, DEVICE_NAME);            // unregister the major number
   printk(KERN_INFO "Motor_ctrl: destroyed\n");
}

/** @brief The device open function that is called each time the device is opened
 *  This will only increment the numberOpens counter in this case.
 *  @param inodep A pointer to an inode object (defined in linux/fs.h)
 *  @param filep A pointer to a file object (defined in linux/fs.h)
 */
static int dev_open(struct inode *inodep, struct file *filep){
   numberOpens++;
   return 0;
}

/** @brief This function is called whenever device is being read from user space i.e. data is
 *  being sent from the device to the user. In this case is uses the copy_to_user() function to
 *  send the buffer string to the user and captures any errors.
 *  @param filep A pointer to a file object (defined in linux/fs.h)
 *  @param buffer The pointer to the buffer to which this function writes the data
 *  @param len The length of the b
 *  @param offset The offset if required
 */
static ssize_t dev_read(struct file *filep, char *buffer, size_t len, loff_t *offset){
   int error_count = 0;  
   if (len == C_NUM_REG){ // read all
     data[0] = readl(virt+C_ADDR_CLK_ENA);
     data[1] = readl(virt+C_ADDR_RUN);
     data[2] = readl(virt+C_ADDR_PWM_CTRL);
     data[3] = readl(virt+C_ADDR_LED);
     data[4] = readl(virt+C_ADDR_TEST);
     error_count = copy_to_user(buffer, data, len*4);
     return 1;
   } else { // read nothing
     printk(KERN_INFO "Motor_ctrl: read bad lenght of buffer\n");
     return 0;
   }
   if (error_count != 0) {
     printk(KERN_INFO "Motor_ctrl: read fail\n");
     return 0;
   }
}

/** @brief This function is called whenever the device is being written to from user space i.e.
 *  data is sent to the device from the user. The data is copied to the message[] array in this
 *  LKM using the sprintf() function along with the length of the string.
 *  @param filep A pointer to a file object
 *  @param buffer The buffer to that contains the string to write to the device
 *  @param len The length of the array of data that is being passed in the const char buffer
 *  @param offset The offset if required
 */
static ssize_t dev_write(struct file *filep, const char *buffer, size_t len, loff_t *offset){ 
   int error_count = 0; 
   //unsigned long irqs;
   //int irq;
   //int i;
   //int result;
   if (len == 1) {
     error_count = copy_from_user(data, buffer ,len); 
     writeb(data[0], virt);
   }
   if (error_count != 0) {
     printk(KERN_INFO "Motor_ctrl: write fail\n");
   }

   return 1;
}

static long dev_ioctl(struct file *filep, unsigned int _cmd, unsigned long _arg) {
    unsigned int data;
    switch (_cmd)
    {
        case MOTOR_IO_CLK_ENA: // enable clock
        {
          writel(_arg ,virt + C_ADDR_CLK_ENA);
          wmb();            
          return 0;
        }
        case MOTOR_IO_RUN: // run controler
        {    
          writel(_arg ,virt + C_ADDR_RUN);
          wmb();
          return 0;
        }
        case MOTOR_IO_PWM_CTRL: // PWM ctrl
        {
          writel(_arg ,virt + C_ADDR_PWM_CTRL);
          wmb();                
          return 0;
        }
        case MOTOR_IO_RED_LED: // red LED ena
        {       
          data = readl(virt+C_ADDR_LED);
          if (_arg > 0)
            data = data | 0x01;  // set test ena
          else
            data = data & 0x02; // clear test ena
          writel(data ,virt + C_ADDR_LED);
          wmb();
          return 0;
        } 
        case MOTOR_IO_GREEN_LED: // green LED ena
        {    
          data = readl(virt+C_ADDR_LED);
          if (_arg > 0)
            data = data | 0x02;  // set test ena
          else
            data = data & 0x01; // clear test ena
          writel(data ,virt + C_ADDR_LED);
          wmb();
          return 0;
        }  
        default:
        {    
           printk(KERN_INFO "Motor_ctrl: undefined ioctl\n");
           return 1;
        }            
    }    
}

/** @brief The device release function that is called whenever the device is closed/released by
 *  the userspace program
 *  @param inodep A pointer to an inode object (defined in linux/fs.h)
 *  @param filep A pointer to a file object (defined in linux/fs.h)
 */
static int dev_release(struct inode *inodep, struct file *filep){
   return 0;
}

/** @brief A module must use the module_init() module_exit() macros from linux/init.h, which
 *  identify the initialization function at insertion time and the cleanup function (as
 *  listed above)
 */
module_init(motor_ctrl_init);
module_exit(motor_ctrl_exit);
