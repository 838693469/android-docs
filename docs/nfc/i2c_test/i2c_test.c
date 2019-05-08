/*
* Android.mk //TODO:Here is makefile reference
* LOCAL_PATH:= $(call my-dir)

* include $(CLEAR_VARS)
* LOCAL_SRC_FILES:= pn547_iic_test_app.c

* LOCAL_MODULE:= pn547_app

* include $(BUILD_EXECUTABLE)
*/

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/pn544.h>

#define SEND_CMD_NUM 2

int main(int argc, char *argv[]) {

	int ret = 0;
	int i = 0;
	int num;
	int fp = 0;

	//NCI cmd
	unsigned char send_test_cmd[SEND_CMD_NUM][60] = { 
		{0x20, 0x00, 0x01, 0x01},/*CORE_RESET_CMD*/
		{0x20, 0x01, 0x00}, /*CORE_INIT_CMD*/
		//{0x20, 0x02, 0x2B, 0x0D, 0x28, 0x01, 0x01, 0x21, 0x01, 0x00, 0x30, 0x01, 0x08, 0x31, 0x01,  /*CORE_SET_CONFIG_CMD */
		// 0x03, 0x33, 0x04, 0x01, 0x02, 0x03, 0x04, 0x54, 0x01, 0x06, 0x50, 0x01, 0x02, 0x5B, 0x01, 
		// 0x02, 0x60, 0x01, 0x07, 0x80, 0x01, 0x01, 0x81, 0x01, 0x01, 0x82, 0x01, 0x0E, 0x18, 0x01, 0x80},
		//{0x2F, 0x02, 0x00},/*NXP_ACT_PROP_EXTN*/
		//{0x2F, 0x00, 0x01, 0x00	}/*NXP_CORE_STANDBY*/
		//{0x20, 0x02, 0x09, 0x02, 0xA0, 0x02, 0x01, 0x01, 0xA0, 0x03, 0x01, 0x13}/*CLOCK_REQUEST_CFG, CLOCK_SEL_CFG*/
	};
	unsigned char recv_resp[100] = {0};

		
	printf("pn544 iic driver testing...");
	if ((ret = (fp = open("/dev/pn544", O_RDWR))) < 0) {
		printf("pn544 open error retcode = %d, errno = %d\n", ret, errno);
		exit(0);
	}

	//hardware reset
	ioctl(fp, PN544_SET_PWR, 1);
	ioctl(fp, PN544_SET_PWR, 0);
	ioctl(fp, PN544_SET_PWR, 1);


	for (num=0; num<SEND_CMD_NUM; num++)
	{
		
		printf("\nDH->NFCC: ");
		for (i=0; i<(send_test_cmd[num][2]+3); i++){
			printf("%.2X ", send_test_cmd[num][i]);
		}

		//Send cmd
		ret = write(fp, send_test_cmd[num], send_test_cmd[num][2]+3);
		if (ret < 0){
			printf("\npn544 write error, maybe in standby mode,  retcode = %d, errno = %d, retry...", ret, errno);
			//wait 50ms
			usleep(50000);
			ret = write(fp, send_test_cmd[num], send_test_cmd[num][2]+3);
			if (ret < 0){
				printf("\npn544 write error retcode = %d, errno = %d", ret, errno);
				close(fp);	
				return errno;
			}
		}
		
		//Read pn547 responses, Read XX XX XX 00 ..., if 4th byte is 00, it means STATUS_OK.
		memset(recv_resp, 0, sizeof(recv_resp));
		ret = read(fp, &recv_resp[0], 3);
		if (ret < 0) {
			printf("\npn544 read error! retcode = %d, errno = %d", ret, errno);
			close(fp);	
			return errno;
		}
		else if (recv_resp[0] == 0x51) {
			printf("\nRead 0x51, IRQ may do not work, abort! ");
			break;
		}

		ret = read(fp, &recv_resp[3], recv_resp[2]);
		if (ret < 0) {
			printf("\npn544 read error! retcode = %d, errno = %d", ret, errno);
		}
		else{
			printf("\nNFCC->DH: ");
			for (i=0;i<(recv_resp[2]+3);i++){
				printf("%.2X ", recv_resp[i]);}
		}

		if (((recv_resp[0]&0xF0)==0x40) && (recv_resp[1]==send_test_cmd[num][1]) && (recv_resp[3]==0))
			printf("\nwrite<->read successful!\n");
		else			
			printf("\nwrite<->read error!\n");
	}

	printf("\n");
	close(fp);	
	return 0;
}
