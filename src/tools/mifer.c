/*
 *  This utility is made to specifically take the last 256 bytes of the bios
 *  ROM and output it to a hex data file with carriage returns or line feeds
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


static void make_hex(char *infile, char *outfile)
{
  FILE *fi, *fo;
  int  length, dh,dl, n;
  char data[16];

  fi = fopen(infile,  "rb");
  if (fi == NULL)
    {
      fprintf(stderr, "Cannot open input file\n");

      // terminate program early if can not open the file
      exit(1);
    }

  fseek(fi, 0L, SEEK_END);     // seek to end of file
  length = ftell(fi);          // tell me the length
  if (length != 0x10000)
    {
      printf("oops, that is not the bios file, must be 64K ROM!\n");
      fclose(fi);              // close the file
      exit(EXIT_FAILURE);      // terminate program
    }
  else printf("BIOS ROM File size = %u bytes\n", length);

  fo = fopen(outfile, "wt");
  if(fo == NULL)
    {
      fprintf(stderr, "Cannot open output file\n");
      exit(EXIT_FAILURE);        // terminate program early
    }

  fseek(fi, 0xFF00L, SEEK_SET);   // seek to the last 256 bytes

  n = 0;
  do
    {
      dh = fgetc(fi);
      dl = fgetc(fi);
      if(dl == EOF) break;
      sprintf(data, "%02x%02x\n", (unsigned char)dl, (unsigned char)dh);
      fputs(data, fo);
      n += 2;
    }
  while(dl != EOF);

  fprintf(stderr, "%d bytes read and converted\n", n);

  fclose(fi);
  fclose(fo);
}


static char *filename_ext(char *infile)
{
  char ext[] = "dat";
  static char fixed_filename[255];
  int i, dot;
  dot = 0;
  i   = 0;
  while(*infile)
    {
      if(*infile == '.') dot = i;
      fixed_filename[i++] = *infile++;
    }
  dot++;
  for(i = 0; i < 4; i++) fixed_filename[i+dot] = ext[i];
  return &fixed_filename[0];
}


int main(int argc, char* argv[])
{
  char *infile  = argv[1];
  char *outfile = filename_ext(infile);

  fprintf(stderr, "MIFER Shadow BIOS ROM Utility:\n");
  fprintf(stderr, "input  file = %s\n", infile);
  fprintf(stderr, "output file = %s\n", outfile);

  make_hex(infile, outfile);

  fprintf(stderr, "Conversion to DAT complete\n");
  return(EXIT_SUCCESS);
}
