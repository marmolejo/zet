/*
 *  Utility to test the PC speaker
 *  Copyright (C) 2010  Donna Polehn <dpolehn@verizon.net>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

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
