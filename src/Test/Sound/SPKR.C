#include <stdio.h>
#include <dos.h>
#define PORT 0x0061
void main(void)
{
	char cmd = ' ';
	unsigned char d;

	printf("\nTest chasis speaker\n");
	printf(" o to turn speaker on\n");
	printf(" space bar to turn speaker off\n");
	printf(" q to quit\n");

	outportb(PORT,0x80);
	printf("%02x ",inportb(PORT));
	for(;;) {
		if(kbhit()) {
			cmd = getch();
			if(cmd == 'q') break;
		}
		outportb(PORT, cmd);
	}
	printf("Hit any key to continue\n"); getch();
}
