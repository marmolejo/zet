/*
 *  A simple cat program
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

#include <sys/stat.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stddef.h>


static void raw_cat(int rfd)
{
  int wfd;
  ssize_t nr, nw;
  char buf[1024];

  wfd = fileno(stdout);
  setmode(wfd, O_BINARY);
  do
    {
      nr = read(rfd, buf, sizeof(buf));
      if(nr > 0)
        {
          nw = write(wfd, buf, (size_t)nr);
          if(nw != nr) fprintf(stderr,"could not write all bytes\n");
        }
     }
  while(nr);

  setmode(wfd, O_TEXT);
}


void main(int argc, char *argv[])
{
   char *path;
   int fd;
   int i = 1;
   int rval = 0;

   do {
      path = argv[i];
      if(path == NULL) break;
      fd = open(path, O_RDONLY | O_BINARY);
      if(fd < 0) {
         fprintf(stderr,"could not open file %s", path);
         rval = 1;
      }
      else {
         raw_cat(fd);
         close(fd);
      }
      i++;
   } while(path != NULL);

   if(fclose(stdout)) fprintf(stderr, "file error");

   exit(rval);
}

/* End meow.c  */

