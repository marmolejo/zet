/*
 *  Utility to play PCM files
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
#include <stdlib.h>
#include <dos.h>

#define REG(x) (0x0210+(x))


void main(int argc, char *argv[])
{
  unsigned int i, length, intv;
  unsigned char *ptr;
  char *filename;
  FILE *fp;

  if(argc > 1) {
    intv = atoi(argv[2]);
    if(intv == 0) intv = 200;
  }
  else intv = 100;
  outportb(REG(2), (intv >>   8));
  outportb(REG(3), (intv & 0xff));
  printf("Interval = 0x%02x%02x\n",inportb(REG(2)),inportb(REG(3)));

  if(argc < 2) {
    printf("Usage: playsound sndfile.pcm [samplerate]\n");
    return;
  }
  filename= argv[1];
  fp = fopen(filename, "rb");    /* Open in binary read mode */
      if(fp == NULL){
        printf("Cannot open input file.\n");
    exit(1);      /* terminate program if can not open the file */
  }
  fseek(fp, 0L, SEEK_END);  /* seek to end of file */
  length = (unsigned int)ftell(fp);    /* tell me the length  */
  fseek(fp, SEEK_SET, 0);    /* seek back tot he start */
  if(length > 0xFFFF) {
    printf("Sorry, that file is too big for me\n");
    fclose(fp);    /* close the file */
        exit(1);      /* terminate program if not enough memory */
  }
  else printf("PCM File size = %ud bytes\n", length );

  /* allocate memory for string */
  if((ptr = (unsigned char *) malloc(length)) == NULL) {
    printf("Not enough memory to allocate buffer.\n");
    fclose(fp);    /* close the file */
        exit(1);      /* terminate program if not enough memory */
  }
  fread(ptr, length , 1, fp);  /* read it into memory */
  fclose(fp);    /* close the file */

  for(i = 0; i < length ; i++) {
    outportb(REG(0), ptr[i]);
    outportb(REG(1), ptr[i]);
    do {
      if(inportb(REG(7))) break;
    } while(1);
   }

  free(ptr);    /* free memory */
  printf("Done playing the sound.\n");
  exit(0);    /* exit normally */
}
