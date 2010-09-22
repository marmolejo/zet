/*
 *  This utility simply takes any binary file and turns it into a HEX file
 *  with no carriage returns or line feeds.
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
  int  d, n;
  char data[8];

  fi = fopen(infile,  "rb");
  if (fi == NULL)
    {
      fprintf(stderr, "Cannot open input file\n");

      // terminate program early if can not open the file
      exit(EXIT_FAILURE);
    }

  fo = fopen(outfile, "wt");
  if (fo == NULL)
    {
      fprintf(stderr, "Cannot open output file\n");

      // terminate program early
      exit(EXIT_FAILURE);
    }

  n = 0;
  do
    {
      d = fgetc(fi);
      if (d == EOF) break;
      sprintf(data, "%02x", (unsigned char)d);
      fputc(data[0],fo);
      fputc(data[1],fo);
      n++;
    }
  while(d != EOF);

  fprintf(stderr, "%d bytes read and converted\n", n);

  fclose(fi);
  fclose(fo);
}


static char *filename_ext(char *infile)
{
  char ext[] = "hex";
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

  fprintf(stderr, "Hexer Conversion Utility:\n");
  fprintf(stderr, "input  file = %s\n", infile);
  fprintf(stderr, "output file = %s\n", outfile);

  make_hex(infile, outfile);

  fprintf(stderr, "Conversion to HEX complete\n");
  return(EXIT_SUCCESS);
}
